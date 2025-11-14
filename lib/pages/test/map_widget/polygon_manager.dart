// ignore_for_file: avoid_print

import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flareline/providers/user_provider.dart';

import 'package:flareline/core/models/farmer_model.dart';
import 'package:flareline/core/models/product_model.dart';
import 'package:flareline/pages/test/map_widget/farm_list_panel/barangay_filter_panel.dart';
import 'package:flareline/pages/test/map_widget/farm_service.dart';
import 'package:flareline/pages/test/map_widget/map_panel/barangay_modal.dart';
import 'package:flareline/pages/test/map_widget/map_panel/lake_modal.dart';
import 'package:flareline/pages/test/map_widget/map_panel/brgy_prev.dart';
import 'package:flareline/pages/test/map_widget/map_panel/farm_creation/farm_creation_modal.dart';
import 'package:flareline/pages/test/map_widget/map_panel/farm_prev.dart';
import 'package:flareline/pages/test/map_widget/map_panel/lake_prev.dart';
import 'package:flareline/pages/test/map_widget/map_panel/polygon_modal.dart';
import 'package:flareline/pages/test/map_widget/pin_style.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_line_editor/flutter_map_line_editor.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:turf/turf.dart' as turf;
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:toastification/toastification.dart';

class PolygonManager with RouteAware {
  final AnimatedMapController mapController;
  List<PolygonData> polygons = [];
  List<LatLng> currentPolygon = [];

  int? selectedPolygonIndex;
  PolygonData? selectedPolygon;
  bool isDrawing = false;
  bool isEditing = false;
  ValueNotifier<PolygonData?> selectedPolygonNotifier = ValueNotifier(null);
  final Function()? onPolygonSelected;
  final BuildContext context;
  PolyEditor? polyEditor;

  List<PolygonHistoryEntry> undoHistory = [];
  List<PolygonHistoryEntry> redoHistory = [];

  final VoidCallback? onFiltersChanged;
  final bool isFarmer;

  bool _isModalShowing = false;
  PolygonData? _lastShownPolygon;
  List<String> selectedBarangays = [];
  List<String> selectedLakes = [];
  List<String> selectedProducts = [];

  OverlayEntry? _infoCardOverlay;
  final FarmService farmService;
  final List<Product> products;
  final List<Farmer> farmers;
// Simple update counter
  int _updateCounter = 0;
  final ValueNotifier<int> editorUpdateNotifier = ValueNotifier<int>(0);

  PolygonManager({
    required this.mapController,
    required this.context,
    this.onPolygonSelected,
    this.onFiltersChanged,
    required this.isFarmer,
    required this.farmService,
    required this.products, // Add this
    required this.farmers, // Add this
  });

  bool polygonExceedsAreaLimit(PolygonData polygon) {
    if (polygon.area == null) return false;

    final maxAreaHectares =
        maxAreaLimitsHectares[polygon.pinStyle] ?? double.infinity;
    return polygon.area! > maxAreaHectares;
  }

// In PolygonManager class
  List<PolygonData> getFilteredPolygons(
    Map<String, bool> farmTypeFilters, {
    bool showExceedingAreaOnly = false,
    List<PolygonData>? basePolygons, // Optional base list to filter from
  }) {
    // Use provided base polygons or default to all polygons
    final baseList = basePolygons ?? polygons;

    return baseList.where((polygon) {
      // Check barangay filter
      final barangayMatch = selectedBarangays.isEmpty ||
          selectedBarangays.contains(polygon.parentBarangay);

      final lakeMatch =
          selectedLakes.isEmpty || selectedLakes.contains(polygon.lake);

      // Check farm type filter
      final pinStyle = polygon.pinStyle.toString().split('.').last;
      final filterKey = pinStyle[0].toUpperCase() + pinStyle.substring(1);
      final typeMatch = farmTypeFilters[filterKey] ?? true;

      // Check product filter
      final productMatch = selectedProducts.isEmpty ||
          polygon.products.any((product) => selectedProducts.contains(product));

      // Check exceeding area filter
      final exceedingAreaMatch =
          !showExceedingAreaOnly || polygonExceedsAreaLimit(polygon);

      return lakeMatch &&
          barangayMatch &&
          typeMatch &&
          productMatch &&
          exceedingAreaMatch;
    }).toList();
  }

  void selectPolygon(int index, {BuildContext? context}) async {
    print("select polygon" + index.toString());

    if (index >= 0 && index < polygons.length) {
      selectedPolygonIndex = index;
      selectedPolygon = polygons[index];
      selectedPolygonNotifier.value = selectedPolygon;

      _zoomToPolygon(polygons[index]); // Make sure this is awaited
      onPolygonSelected?.call();
      // debugPrint(
      //     'Zoom animation started (but not awaited), onPolygonSelected called');

      if (context != null) {
        if (context.mounted) {
          // debugPrint('Context is mounted - scheduling post-frame callback');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // debugPrint(
            //     'Post-frame callback executing - checking mounted status again');
            if (context.mounted) {
              _showInfoCard(context, polygons[index]);
            } else {
              // debugPrint('Context no longer mounted - cannot show info card');
            }
          });
        } else {
          // debugPrint('Context not mounted when checked initially');
        }
      } else {
        // debugPrint('No context provided - cannot show info card');
      }
    } else {
      // debugPrint('Invalid index: $index (polygons length: ${polygons.length})');
    }
  }

  bool get hasFiltersApplied {
    return selectedBarangays.isNotEmpty ||
        selectedLakes.isNotEmpty ||
        selectedProducts.isNotEmpty ||
        BarangayFilterPanel.filterOptions.values.any((isChecked) => !isChecked);
  }

// Add this method to PolygonManager class to get user-filtered base polygons
  List<PolygonData> _getUserFilteredPolygons(BuildContext context) {
    // This should match the filtering logic in MapContent
    return polygons.where((polygon) {
      // Apply user-based filters
      if (isFarmer &&
          BarangayFilterPanel.userFilterOptions['showOwnedOnly'] == true) {
        // Get farmer ID from context
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final farmerId = userProvider.farmer?.id?.toString();

        // Show only farms owned by current farmer
        if (polygon.farmerId?.toString() != farmerId) {
          return false;
        }
      } else if (!isFarmer &&
          BarangayFilterPanel.userFilterOptions['showActiveOnly'] == true) {
        // Show only active farms for non-farmers
        if (polygon.status?.toLowerCase() != 'active' &&
            polygon.status != null) {
          return false;
        }
      }
      return true;
    }).toList();
  }

// Updated getCurrentFilteredIndex method - BuildContext is now optional
  int getCurrentFilteredIndex(
    Map<String, bool> farmTypeFilters, {
    BuildContext? context,
    bool showExceedingAreaOnly = false,
  }) {
    if (selectedPolygon == null) return -1;

    // Get user-filtered base polygons if context is provided
    List<PolygonData>? userFilteredPolygons;
    if (context != null) {
      userFilteredPolygons = _getUserFilteredPolygons(context);
    }

    // Then apply other filters
    final filteredPolygons = getFilteredPolygons(
      farmTypeFilters,
      showExceedingAreaOnly: showExceedingAreaOnly,
      basePolygons:
          userFilteredPolygons, // Pass user-filtered base (or null for all)
    );

    return filteredPolygons.indexWhere((p) => p == selectedPolygon);
  }

// Updated navigateToPreviousPolygon method
  void navigateToPreviousPolygon(
    Map<String, bool> farmTypeFilters,
    BuildContext context, {
    bool showExceedingAreaOnly = false,
  }) {
    // Get user-filtered base polygons first
    final userFilteredPolygons = _getUserFilteredPolygons(context);

    // Then apply other filters
    final filteredPolygons = getFilteredPolygons(
      farmTypeFilters,
      showExceedingAreaOnly: showExceedingAreaOnly,
      basePolygons: userFilteredPolygons, // Pass user-filtered base
    );

    if (filteredPolygons.isEmpty) return;

    final currentIndex = getCurrentFilteredIndex(
      farmTypeFilters,
      context: context, // Pass as named parameter
      showExceedingAreaOnly: showExceedingAreaOnly,
    );
    if (currentIndex <= 0) return;

    final previousIndex = currentIndex - 1;
    final previousPolygon = filteredPolygons[previousIndex];

    final originalIndex = polygons.indexOf(previousPolygon);
    if (originalIndex != -1) {
      selectPolygon(originalIndex, context: context);
    }
  }

// Updated navigateToNextPolygon method
  void navigateToNextPolygon(
    Map<String, bool> farmTypeFilters,
    BuildContext context, {
    bool showExceedingAreaOnly = false,
  }) {
    // Get user-filtered base polygons first
    final userFilteredPolygons = _getUserFilteredPolygons(context);

    // Then apply other filters
    final filteredPolygons = getFilteredPolygons(
      farmTypeFilters,
      showExceedingAreaOnly: showExceedingAreaOnly,
      basePolygons: userFilteredPolygons, // Pass user-filtered base
    );

    if (filteredPolygons.isEmpty) return;

    final currentIndex = getCurrentFilteredIndex(
      farmTypeFilters,
      context: context, // Pass as named parameter
      showExceedingAreaOnly: showExceedingAreaOnly,
    );
    if (currentIndex >= filteredPolygons.length - 1 || currentIndex == -1)
      return;

    final nextIndex = currentIndex + 1;
    final nextPolygon = filteredPolygons[nextIndex];

    final originalIndex = polygons.indexOf(nextPolygon);
    if (originalIndex != -1) {
      selectPolygon(originalIndex, context: context);
    }
  }

// Updated _showInfoCard method
  void _showInfoCard(
    BuildContext context,
    PolygonData polygon, {
    bool showExceedingAreaOnly = false,
  }) {
    // Ensure any existing overlay is removed first
    removeInfoCardOverlay();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        return;
      }

      try {
        final overlayState = Overlay.of(context, rootOverlay: true);
        if (overlayState == null) {
          return;
        }

        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox == null || !renderBox.hasSize) {
          return;
        }

        final mapWidgetSize = renderBox.size;
        final mapWidgetPosition = renderBox.localToGlobal(Offset.zero);

        final farmTypeFilters =
            Map<String, bool>.from(BarangayFilterPanel.filterOptions);

        // Get user-filtered base polygons first
        final userFilteredPolygons = _getUserFilteredPolygons(context);

        // Then apply other filters
        final filteredPolygons = getFilteredPolygons(
          farmTypeFilters,
          showExceedingAreaOnly: showExceedingAreaOnly,
          basePolygons: userFilteredPolygons, // Pass user-filtered base
        );

        final currentIndex = getCurrentFilteredIndex(
          farmTypeFilters,
          context: context, // Pass context for user filtering
          showExceedingAreaOnly: showExceedingAreaOnly,
        );
        final showNavigation = filteredPolygons.length > 1;

        _infoCardOverlay = OverlayEntry(
          builder: (overlayContext) => Positioned(
            left: mapWidgetPosition.dx,
            width: mapWidgetSize.width,
            bottom: 20,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: InfoCard(
                polygon: polygon,
                onTap: () {
                  removeInfoCardOverlay();
                  if (context.mounted) {
                    showPolygonModal(context, polygon);
                  }
                },
                onClose: () {
                  selectedPolygonIndex = null;
                  selectedPolygon = null;
                  selectedPolygonNotifier.value = null;

                  // NEW: Close button callback
                  removeInfoCardOverlay();
                },
                showNavigation: showNavigation,
                currentIndex: currentIndex >= 0 ? currentIndex : 0,
                totalCount: filteredPolygons.length,
                onPrevious: showNavigation && currentIndex > 0
                    ? () {
                        navigateToPreviousPolygon(
                          farmTypeFilters,
                          context,
                          showExceedingAreaOnly: showExceedingAreaOnly,
                        );
                      }
                    : null,
                onNext:
                    showNavigation && currentIndex < filteredPolygons.length - 1
                        ? () {
                            navigateToNextPolygon(
                              farmTypeFilters,
                              context,
                              showExceedingAreaOnly: showExceedingAreaOnly,
                            );
                          }
                        : null,
              ),
            ),
          ),
        );

        overlayState.insert(_infoCardOverlay!);
      } catch (e) {
        debugPrint('[InfoCard] Error showing info card: $e');
        _showInfoCardFallback(context, polygon,
            showExceedingAreaOnly: showExceedingAreaOnly);
      }
    });
  }

// Updated _showInfoCardFallback method
  void _showInfoCardFallback(
    BuildContext context,
    PolygonData polygon, {
    bool showExceedingAreaOnly = false,
  }) {
    try {
      final navigator = Navigator.of(context, rootNavigator: true);
      final overlay = navigator.overlay;
      if (overlay != null) {
        final farmTypeFilters =
            Map<String, bool>.from(BarangayFilterPanel.filterOptions);

        // Get user-filtered base polygons first
        final userFilteredPolygons = _getUserFilteredPolygons(context);

        // Then apply other filters
        final filteredPolygons = getFilteredPolygons(
          farmTypeFilters,
          showExceedingAreaOnly: showExceedingAreaOnly,
          basePolygons: userFilteredPolygons, // Pass user-filtered base
        );

        final currentIndex = getCurrentFilteredIndex(
          farmTypeFilters,
          context: context, // Pass context for user filtering
          showExceedingAreaOnly: showExceedingAreaOnly,
        );
        final showNavigation = filteredPolygons.length > 1;

        _infoCardOverlay = OverlayEntry(
          builder: (context) => Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                elevation: 4,
                color: Colors.transparent,
                child: InfoCard(
                  polygon: polygon,
                  onTap: () {
                    removeInfoCardOverlay();
                    if (context.mounted) {
                      showPolygonModal(context, polygon);
                    }
                  },
                  onClose: () {
                    // NEW: Close button callback
                    removeInfoCardOverlay();
                    selectedPolygonIndex = null;
                    selectedPolygon = null;
                    selectedPolygonNotifier.value = null;
                  },
                  showNavigation: showNavigation,
                  currentIndex: currentIndex,
                  totalCount: filteredPolygons.length,
                  onPrevious: showNavigation && currentIndex > 0
                      ? () => navigateToPreviousPolygon(
                            farmTypeFilters,
                            context,
                            showExceedingAreaOnly: showExceedingAreaOnly,
                          )
                      : null,
                  onNext: showNavigation &&
                          currentIndex < filteredPolygons.length - 1
                      ? () => navigateToNextPolygon(
                            farmTypeFilters,
                            context,
                            showExceedingAreaOnly: showExceedingAreaOnly,
                          )
                      : null,
                ),
              ),
            ),
          ),
        );
        overlay.insert(_infoCardOverlay!);
        debugPrint(
            '[InfoCard] Used fallback overlay successfully with navigation: $showNavigation');
      }
    } catch (e) {
      debugPrint('[InfoCard] Fallback also failed: $e');
    }
  }

// Add method to get count of exceeding polygons
  int getExceedingAreaPolygonsCount() {
    return polygons.where((polygon) => polygonExceedsAreaLimit(polygon)).length;
  }

// Add method to get area limit text for display
  String getAreaLimitText(PinStyle pinStyle) {
    final limit = maxAreaLimitsHectares[pinStyle];
    if (limit == null || limit == double.infinity) {
      return 'No limit';
    }
    return '${limit.toStringAsFixed(1)} hectares';
  }

  void updateFilters({
    List<String>? lakes,
    List<String>? barangays,
    List<String>? products,
    Map<String, bool>? farmTypes,
  }) {
    if (lakes != null) selectedLakes = lakes;
    if (barangays != null) selectedBarangays = barangays;
    if (products != null) selectedProducts = products;

    // Notify listeners if needed
    onFiltersChanged?.call();
  }

  void clearFilters() {
    selectedLakes.clear();
    selectedBarangays.clear();
    selectedProducts.clear();
    BarangayFilterPanel.filterOptions.forEach((key, value) {
      BarangayFilterPanel.filterOptions[key] = true;
    });
    onFiltersChanged?.call();
  }

  void initializePolyEditor(PolygonData polygon) {
    polyEditor = PolyEditor(
      points: List<LatLng>.from(selectedPolygon!.vertices),
      pointIcon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.orange,
          border: Border.all(
            color: Colors.white,
            width: 2.0,
          ),
        ),
      ),
      intermediateIcon: Container(
        width: 25,
        height: 25,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.withOpacity(0.8),
          border: Border.all(
            color: Colors.white,
            width: 1.0,
          ),
        ),
      ),
      callbackRefresh: () {
        // Only update the polygon data, don't recreate the editor during editing
        if (selectedPolygonIndex != null && polyEditor != null) {
          polygons[selectedPolygonIndex!].vertices =
              List<LatLng>.from(polyEditor!.points);
          selectedPolygon = polygons[selectedPolygonIndex!];
          selectedPolygonNotifier.value = selectedPolygon;
          onFiltersChanged?.call();
        }
      },
      addClosePathMarker: true,
    );
  }

  // Method to manually refresh midpoints after editing is complete
  void refreshMidpoints() {
    if (polyEditor != null && selectedPolygon != null) {
      final currentPoints = List<LatLng>.from(polyEditor!.points);

      // Save the current editor state
      polyEditor = null;

      // Recreate with updated points
      polyEditor = PolyEditor(
        points: currentPoints,
        pointIcon: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.orange,
            border: Border.all(
              color: Colors.white,
              width: 2.0,
            ),
          ),
        ),
        intermediateIcon: Container(
          width: 25,
          height: 25,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.withOpacity(0.8),
            border: Border.all(
              color: Colors.white,
              width: 1.0,
            ),
          ),
        ),
        callbackRefresh: () {
          if (selectedPolygonIndex != null && polyEditor != null) {
            polygons[selectedPolygonIndex!].vertices =
                List<LatLng>.from(polyEditor!.points);
            selectedPolygon = polygons[selectedPolygonIndex!];
            selectedPolygonNotifier.value = selectedPolygon;
            onFiltersChanged?.call();
          }
        },
        addClosePathMarker: true,
      );

      _updateCounter++;
    }
  }

  void startEditing() {
    isEditing = true;
    if (selectedPolygon != null) {
      initializePolyEditor(selectedPolygon!);
    }
  }

  void stopEditing() {
    isEditing = false;
    polyEditor = null;
    _updateCounter++;
  }

  // Call this periodically or after certain actions to refresh midpoints
  void periodicMidpointRefresh() {
    Timer.periodic(Duration(seconds: 2), (timer) {
      if (isEditing && polyEditor != null) {
        refreshMidpoints();
      } else {
        timer.cancel();
      }
    });
  }

  int get updateCounter => _updateCounter;

  void forceUpdate() {
    _updateCounter++;
  }

// Add this helper method to check if a polygon is currently visible
  bool isPolygonVisible(
    PolygonData polygon,
    BuildContext context, {
    bool showExceedingAreaOnly = false,
  }) {
    // Get user-filtered base polygons
    final userFilteredPolygons = _getUserFilteredPolygons(context);

    // Check if polygon passes user filters
    if (!userFilteredPolygons.contains(polygon)) {
      return false;
    }

    // Get farm type filters
    final farmTypeFilters =
        Map<String, bool>.from(BarangayFilterPanel.filterOptions);

    // Get all filtered polygons
    final filteredPolygons = getFilteredPolygons(
      farmTypeFilters,
      showExceedingAreaOnly: showExceedingAreaOnly,
      basePolygons: userFilteredPolygons,
    );

    // Check if polygon is in the filtered list
    return filteredPolygons.contains(polygon);
  }

// Updated handleSelectionTap method - replace your existing one with this
  void handleSelectionTap(
    LatLng tapPoint,
    BuildContext context, {
    bool showExceedingAreaOnly = false,
  }) {
    if (polyEditor != null) {
      isDrawing = false;
      isEditing = false;
      currentPolygon.clear();
      undoLastPoint();
      selectedPolygonIndex = null;
    }

    _saveState();
    selectedPolygon = null;
    selectedPolygonIndex = null;

    for (int i = 0; i < polygons.length; i++) {
      List<LatLng> polygonPoints = polygons[i].vertices;

      if (polygonPoints.length < 3) continue;

      // Convert to List<Position>
      List<turf.Position> polygonCoordinates = polygonPoints
          .map((p) => turf.Position(p.longitude, p.latitude))
          .toList();

      if (polygonCoordinates.first != polygonCoordinates.last) {
        polygonCoordinates.add(polygonCoordinates.first);
      }

      // Convert tapPoint to Turf Point correctly
      var tapTurfPoint = turf.Point(
          coordinates: turf.Position(tapPoint.longitude, tapPoint.latitude));

      bool isInside = turf.booleanPointInPolygon(tapTurfPoint.coordinates,
          turf.Polygon(coordinates: [polygonCoordinates]));

      if (isInside) {
        final polygon = polygons[i];

        // Check if this polygon is currently visible based on filters
        if (!isPolygonVisible(polygon, context,
            showExceedingAreaOnly: showExceedingAreaOnly)) {
          // Polygon is filtered out, don't show info card or select it
          // debugPrint(
          //     '[Selection] Polygon ${polygon.name} is filtered out, ignoring tap');
          removeInfoCardOverlay();
          continue; // Continue checking other polygons (in case of overlapping)
        }

        // Polygon is visible, select it and show info card
        // Pass the context to selectPolygon
        selectPolygon(i, context: context);

        // print('here');
        // print(i);

        // Reinitialize the PolyEditor with the new polygon's vertices
        initializePolyEditor(selectedPolygon!);
        break;
      } else {
        removeInfoCardOverlay();
      }
    }

    if (selectedPolygon == null) {
      // Clear the PolyEditor when no polygon is selected
      polyEditor = null;
    }
  }

  Future<void> deletePolygon(BuildContext context, int polygonId) async {
    try {
      // Attempt to delete the farm from the server
      final success = await farmService.deleteFarm(polygonId);

      if (success) {
        polygons.removeWhere((polygon) => polygon.id == polygonId);
        selectedPolygonNotifier.value = null;

        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.flat,
          title: const Text('Farm deleted successfully!'),
          autoCloseDuration: const Duration(seconds: 4),
        );

        if (onFiltersChanged != null) {
          onFiltersChanged!();
        }
      } else {
        throw Exception('Deletion failed');
      }
    } catch (e) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.flat,
        title: Text('Failed to delete farm: ${e.toString()}'),
        autoCloseDuration: const Duration(seconds: 4),
      );
      debugPrint('Failed to delete farm: ${e.toString()}');
    }
  }

  Future<void> saveEditedPolygon() async {
    // Early exit if no polygon is selected
    if (selectedPolygonIndex == null || selectedPolygon == null) {
      debugPrint('No polygon selected.');
      return;
    }

    // Store references locally to avoid race conditions
    final polygonToSave = selectedPolygon!;
    final indexToUpdate = selectedPolygonIndex!;

    try {
      await farmService.updateFarm(polygonToSave); // API call

      // Verify indices and data are still valid before updating
      if (indexToUpdate < polygons.length &&
          polygons[indexToUpdate].id == polygonToSave.id) {
        polygons[indexToUpdate] = polygonToSave.copyWith();
        selectedPolygonNotifier.value = polygonToSave;
      }

      toastification.show(
        context: context,
        type: ToastificationType.success,
        title: const Text('Farm updated successfully!'),
        autoCloseDuration: const Duration(seconds: 4),
      );
    } catch (e) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: Text('Failed to update farm: ${e.toString()}'),
        autoCloseDuration: const Duration(seconds: 4),
      );
      debugPrint('Error saving polygon: $e');
    }

    isDrawing = false;

    _saveState();

    currentPolygon.clear();

    selectedPolygonIndex = null;
  }

  double calculateAreaInHectares(List<LatLng> vertices) {
    if (vertices.length < 3) return 0.0;

    final coordinates = [
      vertices
          .map((point) => turf.Position(point.longitude, point.latitude))
          .toList()
    ];

    final geoJsonPolygon = turf.Polygon(coordinates: coordinates);
    final areaInSqMeters = turf.area(geoJsonPolygon);
    final areaInHectares = areaInSqMeters! / 10000;

    return double.parse(areaInHectares.toStringAsFixed(3));
  }

  bool canUndo() {
    return undoHistory.isNotEmpty;
  }

  void undoLastPoint() {
    // print('undoohereee');a
    undo();
  }

  void _saveState() {
    if (undoHistory.isNotEmpty && redoHistory.isNotEmpty) {
      redoHistory.clear();
    }

    final newState = PolygonHistoryEntry(
      List<PolygonData>.from(polygons.map((polygon) => PolygonData(
            vertices: List<LatLng>.from(polygon.vertices),
            name: polygon.name,
            color: polygon.color,
            description: polygon.description,
            pinStyle: polygon.pinStyle,
          ))),
      List<LatLng>.from(currentPolygon),
      selectedPolygonIndex,
    );
    undoHistory.add(newState);
  }

  void undo() {
    if (undoHistory.isNotEmpty) {
      // Save current state to redo history first
      redoHistory.add(PolygonHistoryEntry(
        polygons.map((p) => p.copyWith()).toList(),
        List<LatLng>.from(currentPolygon),
        selectedPolygonIndex,
      ));

      // Get the last undo state
      final lastState = undoHistory.removeLast();

      // Update vertices while preserving other properties
      for (int i = 0;
          i < polygons.length && i < lastState.polygons.length;
          i++) {
        polygons[i].vertices =
            List<LatLng>.from(lastState.polygons[i].vertices);
      }

      currentPolygon = List<LatLng>.from(lastState.currentPolygon);
      selectedPolygonIndex = lastState.selectedPolygonIndex;

      // Update selected polygon reference
      if (selectedPolygonIndex != null &&
          selectedPolygonIndex! < polygons.length) {
        selectedPolygon = polygons[selectedPolygonIndex!];

        // Recreate the editor with all original properties
        if (polyEditor != null) {
          initializePolyEditor(
              selectedPolygon!); // Reinitialize with all custom properties
        }
      } else {
        selectedPolygon = null;
        polyEditor = null;
      }

      selectedPolygonNotifier.value = selectedPolygon;
      debugPrint('Undo completed. Selected index: $selectedPolygonIndex');
    }
  }

  void didPush() {
    removeInfoCardOverlay();
  }

  void didPop() {
    removeInfoCardOverlay();
  }

// Updated showBarangayInfo method
  void showBarangayInfo(BuildContext context, PolygonData barangay,
      List<PolygonData> allPolygons) {
    removeInfoCardOverlay();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize) return;

      final mapWidgetSize = renderBox.size;
      final mapWidgetPosition = renderBox.localToGlobal(Offset.zero);

      _infoCardOverlay = OverlayEntry(
        builder: (context) => Positioned(
          bottom: 20,
          left: mapWidgetPosition.dx,
          width: mapWidgetSize.width,
          child: Center(
            child: BarangayInfoCard(
              barangay: barangay,
              farmsInBarangay: allPolygons
                  .where((p) => p.parentBarangay == barangay.name)
                  .toList(),
              onTap: () {
                removeInfoCardOverlay();
                if (context.mounted) {
                  _showBarangayDetailsModal(
                      context,
                      barangay,
                      allPolygons
                          .where((p) => p.parentBarangay == barangay.name)
                          .toList());
                }
              },
              onClose: () {
                // NEW: Close button callback
                removeInfoCardOverlay();
              },
            ),
          ),
        ),
      );

      if (context.mounted) {
        Overlay.of(context).insert(_infoCardOverlay!);
      }
    });
  }

  void _showBarangayDetailsModal(
      BuildContext context, PolygonData barangay, List<PolygonData> farms) {
    BarangayModal.show(
      context: context,
      barangay: barangay,
      farms: farms,
      polygonManager: this,
    ).then((_) {
      // Modal closed callback
      _isModalShowing = false;
      _lastShownPolygon = null;
    });
  }

  void showLakenInfo(
      BuildContext context, PolygonData lake, List<PolygonData> allPolygons) {
    removeInfoCardOverlay();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize) return;

      final mapWidgetSize = renderBox.size;
      final mapWidgetPosition = renderBox.localToGlobal(Offset.zero);

      _infoCardOverlay = OverlayEntry(
        builder: (context) => Positioned(
          bottom: 20,
          left: mapWidgetPosition.dx,
          width: mapWidgetSize.width,
          child: Center(
            child: LakeInfoCard(
              lake: lake,
              farmsInLake:
                  allPolygons.where((p) => p.lake == lake.name).toList(),
              onTap: () {
                removeInfoCardOverlay();
                if (context.mounted) {
                  _showLakeDetailsModal(context, lake,
                      allPolygons.where((p) => p.lake == lake.name).toList());
                }
              },
              onClose: () {
                // NEW: Close button callback
                removeInfoCardOverlay();
              },
            ),
          ),
        ),
      );

      if (context.mounted) {
        Overlay.of(context).insert(_infoCardOverlay!);
      }
    });
  }

  void _showLakeDetailsModal(
      BuildContext context, PolygonData lake, List<PolygonData> farms) {
    LakeModal.show(
      context: context,
      lake: lake,
      farms: farms,
      polygonManager: this,
    ).then((_) {
      // Modal closed callback
      _isModalShowing = false;
      _lastShownPolygon = null;
    });
  }

  // Method to remove the info card overlay
  void removeInfoCardOverlay() {
    if (_infoCardOverlay != null && _infoCardOverlay!.mounted) {
      _infoCardOverlay!.remove();
    }
    _infoCardOverlay = null;
  }

  void handleModalForSelectedPolygon(BuildContext context) {
    if (selectedPolygon != null &&
        selectedPolygon!.vertices.isNotEmpty &&
        !_isModalShowing &&
        _lastShownPolygon != selectedPolygon) {
      _lastShownPolygon = selectedPolygon;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          _showInfoCard(context, selectedPolygon!);
        }
      });
    }
  }

  Future<void> showPolygonModal(
      BuildContext context, PolygonData polygon) async {
    // debugPrint('Initial products: ${polygon.products?.join(', ') ?? 'none'}');
    _isModalShowing = true;
    selectedPolygon = polygon;
    selectedPolygonNotifier.value = polygon;
    print("farmers");
    print(farmers);
    await PolygonModal.show(
      context: context,
      products: products,
      farmers: farmers,
      polygon: polygon,
      onUpdateCenter: (newCenter) {
        selectedPolygon?.center = newCenter;
        selectedPolygonNotifier.value = selectedPolygon;
      },
      onUpdateStatus: (status) {
        selectedPolygon?.status = status;
        selectedPolygonNotifier.value = selectedPolygon;
      },
      onUpdatePinStyle: (newStyle) {
        selectedPolygon?.pinStyle = newStyle;
        selectedPolygonNotifier.value = selectedPolygon;
      },
      onUpdateColor: (color) {
        selectedPolygon?.color = color;
        selectedPolygonNotifier.value = selectedPolygon;
        debugPrint('Products update triggered');
      },
      onUpdateProducts: (newProducts) {
        // Debug print before update
        debugPrint('Products update triggered');
        debugPrint(
            'Current products: ${selectedPolygon?.products?.join(', ') ?? 'none'}');
        debugPrint('New products: ${newProducts.join(', ')}');

        if (selectedPolygon == null) {
          debugPrint('Warning: selectedPolygon is null during product update');
          return;
        }

        // Create a new list to avoid reference issues
        final updatedProducts = List<String>.from(newProducts);

        // Update the polygon
        selectedPolygon = selectedPolygon!.copyWith(products: updatedProducts);

        // Debug print after update but before notifying
        debugPrint(
            'Updated polygon products: ${selectedPolygon!.products?.join(', ') ?? 'none'}');

        // Notify listeners
        selectedPolygonNotifier.value = selectedPolygon;

        // Final verification print
        debugPrint(
            'Notifier updated with products: ${selectedPolygonNotifier.value?.products?.join(', ') ?? 'none'}');
      },
      onSave: () {
        saveEditedPolygon();
      },
      selectedYear: DateTime.now().year.toString(),
      onYearChanged: (newYear) {},
      onDeletePolygon: (id) {
        deletePolygon(context, id);
        // Add any additional UI updates or navigation here
      },
      onUpdateFarmName: (String) {},
      onUpdateFarmOwner: (String) {},
      onUpdateBarangay: (String) {},
      onUpdateLake: (String) {},
    );

    _isModalShowing = false;
    _lastShownPolygon = polygon;
    selectedPolygon = null;
    selectedPolygonNotifier.value = null;
  }

  // Don't forget to clean up overlay when disposing
  void dispose() {
    removeInfoCardOverlay();
    selectedPolygonNotifier.dispose();
    // Other cleanup code...
  }

  void _zoomToPolygon(PolygonData polygon) {
    if (polygon.vertices.isEmpty) return;

    mapController.animatedFitCamera(
      cameraFit: CameraFit.coordinates(
        coordinates: polygon.vertices,
        padding: const EdgeInsets.all(30), // Decrease for tighter zoom
      ),
      curve: Curves.easeInOut,
    );
  }

  void handleDrawingTap(LatLng point) {
    if (selectedPolygonIndex != null) {
      polygons[selectedPolygonIndex!].vertices.add(point);
      _saveState(); // ✅ Already saving for existing polygons
    } else {
      if (currentPolygon.isNotEmpty) {
        final double distance = const Distance().as(
          LengthUnit.Meter,
          currentPolygon.first,
          point,
        );

        if (distance < 10) {
          currentPolygon.add(currentPolygon.first);
          polygons.add(PolygonData(
            vertices: List.from(currentPolygon),
            name: 'Polygon ${polygons.length + 1}',
            color: Colors.blue,
          ));
          selectedPolygonIndex = polygons.length - 1;
          selectedPolygon = polygons[selectedPolygonIndex!];
          currentPolygon.clear();
          _saveState(); // ✅ Save when finishing a new polygon
        } else {
          currentPolygon.add(point);
          _saveState(); // 🚀 NEW: Save after adding any intermediate point
        }
      } else {
        currentPolygon.add(point);
        _saveState(); // 🚀 NEW: Save after adding the first point
      }
    }
  }

  Future<void> completeCurrentPolygon(BuildContext context) async {
    _saveState();
    if (currentPolygon.length > 2) {
      final tempPolygon = PolygonData(
        vertices: List.from(currentPolygon),
        name: 'New Farm ${polygons.length + 1}',
        color: Colors.blue, // will be updated below
        status: isFarmer ? 'Inactive' : 'Active', // default status
      );

      // Calculate area first
      tempPolygon.area = calculateAreaInHectares(tempPolygon.vertices);

      // Set color based on area
      tempPolygon.color = tempPolygon.area! > 5 ? Colors.red : Colors.blue;

      final shouldSave = await FarmCreationModal.show(
        context: context,
        polygon: tempPolygon,
        onNameChanged: (name) => tempPolygon.name = name,
        onPinStyleChanged: (style) => tempPolygon.pinStyle = style,
        farmers: farmers, // Pass the farmers list
        onFarmerChanged: (id, name) {
          tempPolygon.owner = id != null ? "$id: $name" : null;
          tempPolygon.farmerId = id;
        },
      );

      if (shouldSave) {
        try {
          final response = await farmService.createFarm(tempPolygon);
          // Update tempPolygon with the ID from response
          tempPolygon.id = response['id'];
          polygons.add(tempPolygon);
          currentPolygon.clear();
          isDrawing = false;
          clearFilters();
          selectedPolygonNotifier.value = tempPolygon;

          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.flat,
            title: const Text('Farm created successfully!'),
            autoCloseDuration: const Duration(seconds: 4),
          );
        } catch (e) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            style: ToastificationStyle.flat,
            title: Text('Failed to create farm: ${e.toString()}'),
            alignment: Alignment.topRight,
            autoCloseDuration: const Duration(seconds: 4),
          );
          debugPrint('Failed to create farm: ${e.toString()}');
          currentPolygon.clear();
          isDrawing = false;
        }
      } else {
        currentPolygon.clear();
        isDrawing = false;
        isEditing = false;
        selectedPolygon = null;
        selectedPolygonIndex = null;
        polyEditor = null;
        selectedPolygonNotifier.value = null;

        if (onFiltersChanged != null) {
          onFiltersChanged!();
        }
      }
    }
  }

  final Map<PinStyle, double> maxAreaLimitsHectares = {
    PinStyle.Fishery: 1,
    PinStyle.Rice: 5,
    PinStyle.HVC: 5,
    PinStyle.Organic: 5,
    PinStyle.Corn: 5,
    PinStyle.Livestock: 5,
    // Add other pin styles as needed
  };

  /// Loads a list of polygons into the manager
  void loadPolygons(List<PolygonData> polygonsToLoad) {
    // Define maximum area limits for each pin style in HECTARES

    final processedPolygons = polygonsToLoad.map((polygon) {
      final maxAreaHectares =
          maxAreaLimitsHectares[polygon.pinStyle] ?? double.infinity;
      final exceedsLimit =
          polygon.area != null && polygon.area! > maxAreaHectares;

      return polygon.copyWith(
        color: exceedsLimit
            ? Colors.red.withOpacity(0.7)
            : polygon.color, // Keep original color if within limit
      );
    }).toList();

    polygons = List<PolygonData>.from(processedPolygons);
    selectedPolygonIndex = null;
    selectedPolygon = null;
    selectedPolygonNotifier.value = null;
  }

  /// Logs all polygon data to the console
  void logPolygons() {
    if (polygons.isEmpty) {
      // print("No polygons available.");
      return;
    }

    // print("===== Logging Polygon Data =====");
    for (int i = 0; i < polygons.length; i++) {
      final polygon = polygons[i];
      print("Polygon ${i + 1}: ${polygon.name}");

      print("  - Color: ${polygon.color}");
      print(
          "  - Center: Lat: ${polygon.center.latitude}, Lng: ${polygon.center.longitude}");

      print("  - Description: ${polygon.description}");

      if (polygon.pinStyle != null) {
        print("  - Icon: ${polygon.pinStyle}");
      }
      print("-----------------------------");
    }
    print("===== End of Polygon Data =====");
  }

  void toggleDrawing() {
    _saveState();
    isDrawing = !isDrawing;

    if (!isDrawing) {
      currentPolygon.clear();
      if (selectedPolygon == null) {
        polyEditor = null; // Clear the PolyEditor when no polygon is selected
      }
    }

    if (isDrawing) {
      isEditing = false;
      currentPolygon.clear();
      selectedPolygon = null;
      selectedPolygonIndex = null;
    }
  }

  void toggleEditing() {
    if (isEditing) {
      isDrawing = false;

      currentPolygon.clear();
      undoLastPoint();

      _saveState();

      currentPolygon.clear();

      selectedPolygonIndex = null;
    }

    isEditing = !isEditing;
  }

  void removeVertex(int vertexIndex) {
    _saveState();

    if (selectedPolygonIndex == null) return;

    PolygonData polygon = polygons[selectedPolygonIndex!];

    if (vertexIndex >= 0 && vertexIndex < polygon.vertices.length) {
      polygon.vertices.removeAt(vertexIndex);

      if (polygon.vertices.length < 3) {
        // If less than 3 vertices remain, remove the polygon
        polygons.removeAt(selectedPolygonIndex!);
        selectedPolygonIndex = null;
        selectedPolygon = null;
      } else {
        selectedPolygon = polygon;
      }
    }
  }

  void redo() {
    if (redoHistory.isNotEmpty) {
      // Save current state to undo history first
      undoHistory.add(PolygonHistoryEntry(
        polygons.map((p) => p.copyWith()).toList(),
        List<LatLng>.from(currentPolygon),
        selectedPolygonIndex,
      ));

      // Get the next redo state
      final nextState = redoHistory.removeLast();

      // Update vertices while preserving other properties
      for (int i = 0;
          i < polygons.length && i < nextState.polygons.length;
          i++) {
        polygons[i].vertices =
            List<LatLng>.from(nextState.polygons[i].vertices);
      }

      currentPolygon = List<LatLng>.from(nextState.currentPolygon);
      selectedPolygonIndex = nextState.selectedPolygonIndex;

      // Update selected polygon reference
      if (selectedPolygonIndex != null &&
          selectedPolygonIndex! < polygons.length) {
        selectedPolygon = polygons[selectedPolygonIndex!];

        // Recreate the editor with all original properties if needed
        if (polyEditor != null) {
          initializePolyEditor(
              selectedPolygon!); // Reinitialize with all custom properties
        }
      } else {
        selectedPolygon = null;
        polyEditor = null;
      }

      selectedPolygonNotifier.value = selectedPolygon;
      debugPrint('Redo completed. Selected index: $selectedPolygonIndex');
    }
  }
}

class PolygonHistoryEntry {
  final List<PolygonData> polygons;
  final List<LatLng> currentPolygon;
  final int? selectedPolygonIndex;

  PolygonHistoryEntry(
      this.polygons, this.currentPolygon, this.selectedPolygonIndex);
}

enum PolygonType { farm, barangay, lake }

class PolygonData {
  int? id; // Changed to int type
  List<LatLng> vertices;
  String name;
  String? owner;
  int? farmerId;
  LatLng center;
  Color color;
  String? description;
  PinStyle pinStyle;
  PolygonType type;
  String? barangay;
  String? lake;
  String? status;
  String? parentBarangay;
  List<String> products;
  double? area;

  PolygonData({
    this.id,
    required this.vertices,
    required this.name,
    this.farmerId,
    this.owner,
    LatLng? center,
    this.color = Colors.blue,
    this.description,
    this.pinStyle = PinStyle.Fishery,
    this.type = PolygonType.farm,
    this.barangay,
    this.lake,
    this.status,
    this.parentBarangay,
    List<String>? products,
    this.area,
  })  : center = center ?? calculateCenter(vertices),
        products = products ?? [];

  /// Helper method to calculate the center of a polygon
  static LatLng calculateCenter(List<LatLng> vertices) {
    if (vertices.isEmpty) return const LatLng(0, 0);

    double latSum = 0, lngSum = 0;
    for (var vertex in vertices) {
      latSum += vertex.latitude;
      lngSum += vertex.longitude;
    }
    return LatLng(latSum / vertices.length, lngSum / vertices.length);
  }

  void parseOwnerString(String ownerString) {
    if (ownerString.isEmpty) {
      farmerId = null;
      owner = null;
      return;
    }

    // Split the string at the first occurrence of ":"
    final parts = ownerString.split(':');
    if (parts.length >= 2) {
      // Parse the ID part (trim whitespace)
      farmerId = int.tryParse(parts[0].trim());
      // The rest is the owner name (trim whitespace)
      owner = parts.sublist(1).join(':').trim();
    } else {
      // If no colon found, assume it's just the name
      farmerId = null;
      owner = ownerString.trim();
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id, // Include id in serialization
      'vertices': vertices
          .map((point) => {'lat': point.latitude, 'lng': point.longitude})
          .toList(),
      'name': name,
      'farmerId': farmerId,
      'owner': owner,
      'center': {'lat': center.latitude, 'lng': center.longitude},
      'color': color.value,
      'description': description,
      'pinStyle': pinStyle.toString().split('.').last,
      'type': type.toString().split('.').last,
      'barangay': barangay,
      'parentBarangay': parentBarangay,
      'products': products,
      'lake': lake,
      'status': status,
      'area': area,
    };
  }

  factory PolygonData.fromMap(Map<String, dynamic> map) {
    return PolygonData(
      id: map['id'], // Deserialize id
      vertices: (map['vertices'] as List)
          .map((point) => LatLng(point['lat'], point['lng']))
          .toList(),
      name: map['name'],
      owner: map['owner'],
      farmerId: map['farmerId'],
      center: map.containsKey('center')
          ? LatLng(map['center']['lat'], map['center']['lng'])
          : calculateCenter((map['vertices'] as List)
              .map((point) => LatLng(point['lat'], point['lng']))
              .toList()),
      color: Color(map['color']),
      description: map['description'],
      pinStyle: parsePinStyle(map['pinStyle']),
      type: map['type'] == 'barangay'
          ? PolygonType.barangay
          : map['type'] == 'lake'
              ? PolygonType.lake
              : PolygonType.farm,

      barangay: map['barangay'],
      lake: map['lake'],
      status: map['status'],
      parentBarangay: map['parentBarangay'],
      products:
          map['products'] != null ? List<String>.from(map['products']) : [],
      area: map['area']?.toDouble(),
    );
  }

  PolygonData copyWith({
    int? id,
    String? name,
    String? owner,
    int? farmerId,
    LatLng? center,
    List<LatLng>? vertices,
    Color? color,
    String? description,
    PinStyle? pinStyle,
    String? parentBarangay,
    String? lake,
    String? status,
    List<String>? products,
    double? area,
  }) {
    return PolygonData(
      id: id ?? this.id,
      name: name ?? this.name,
      owner: owner ?? this.owner,
      farmerId: farmerId ?? this.farmerId,
      center: center ?? this.center,
      vertices: vertices ?? List.from(this.vertices),
      color: color ?? this.color,
      description: description ?? this.description,
      pinStyle: pinStyle ?? this.pinStyle,
      lake: lake ?? this.lake,
      status: status ?? this.status,
      parentBarangay: parentBarangay ?? this.parentBarangay,
      products:
          products ?? (this.products ?? []).toList(), // Better null handling
      area: area ?? this.area,
    );
  }

  void updateFrom(PolygonData other) {
    id = other.id; // Update id
    name = other.name;
    owner = other.owner;
    farmerId = other.farmerId;
    center = other.center;
    vertices = List.from(other.vertices);
    color = other.color;
    pinStyle = other.pinStyle;
    description = other.description;
    lake = other.lake;
    status = other.status;
    parentBarangay = other.parentBarangay;
    products = other.products.toList();
    area = other.area;
  }

  /// Updates the center manually
  void updateCenter(LatLng newCenter) {
    center = newCenter;
  }
}

class BarangayManager {
  List<PolygonData> barangays = [];

  void loadBarangays(List<Map<String, dynamic>> barangayMaps) {
    barangays = barangayMaps.map((map) {
      final polygon = PolygonData.fromMap(map);
      polygon.type = PolygonType.barangay;
      return polygon;
    }).toList();
  }
}

class LakeManager {
  List<PolygonData> lakes = [];

  void loadLakes(List<Map<String, dynamic>> lakeMaps) {
    lakes = lakeMaps.map((map) {
      final polygon = PolygonData.fromMap(map);
      polygon.type = PolygonType.lake;
      return polygon;
    }).toList();
  }
}
