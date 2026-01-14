// File: map_content.dart - Updated to pass zoom level to icon layers

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flareline/pages/map/map_widget/cached_tile_provider.dart';
import 'package:flareline/pages/map/map_widget/map_measurement.dart';
import 'package:flareline/pages/map/map_widget/mobile_map_measurement.dart';
import 'package:flareline/pages/map/map_widget/tile_cache_service.dart';
import 'package:flareline/pages/map/map_widget/view_port_helper.dart' as view_port_helper;
import 'package:flareline/pages/map/map_widget/view_port_helper.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';
import 'package:latlong2/latlong.dart'; 
import 'package:flareline/services/lanugage_extension.dart';
import 'package:provider/provider.dart';
import 'map_layers.dart';
import 'polygon_manager.dart';
import 'dart:async';

class MapContent extends StatefulWidget {
  final MapController mapController;
  final String selectedMap;
  final double zoomLevel;
  final BarangayManager barangayManager;
  final LakeManager lakeManager;
  final PolygonManager polygonManager;
  final ValueNotifier<LatLng?> previewPointNotifier;
  final Function setState;
  final List<String>? barangayFilter;
  final List<String> lakeFilter;
  final Map<String, bool> farmTypeFilters;
  final List<String> productFilters;
  final AnimatedMapController animatedMapController;
  final Function(List<String>)? onBarangayFilterChanged;
  final Function(List<String>)? onLakeFilterChanged;
  final bool showExceedingAreaOnly;
  final bool showAreaMarkers;
  final bool showOwnedFarmsOnly;
  final bool showActiveFarmsOnly;
  final bool areaFilterActive; // ADD THIS
  final Function(bool) onAreaFilterChanged; // ADD THIS

  const MapContent({
    super.key,
    required this.mapController,
    required this.selectedMap,
    required this.zoomLevel,
    required this.polygonManager,
    required this.barangayManager,
    required this.lakeManager,
    required this.previewPointNotifier,
    required this.setState,
    this.barangayFilter,
    required this.lakeFilter,
    required this.farmTypeFilters,
    required this.productFilters,
    required this.animatedMapController,
    this.onBarangayFilterChanged,
    this.onLakeFilterChanged,
    required this.showExceedingAreaOnly,
    required this.showAreaMarkers,
    required this.showOwnedFarmsOnly,
    required this.showActiveFarmsOnly,
    required this.areaFilterActive, // ADD THIS
    required this.onAreaFilterChanged, // ADD THIS
  });

  @override
  State<MapContent> createState() => _MapContentState();
}

class _MapContentState extends State<MapContent> {
  double _currentZoom = 15.0;
  // Layer caching
  Timer? _zoomDebounceTimer;
  TileLayer? _cachedTileLayer;
  PolygonLayer? _cachedBarangayLayer;
  PolygonLayer? _cachedLakeLayer;
  MarkerLayer? _cachedBarangayMarkers;
  MarkerLayer? _cachedLakeMarkers;

  // Cache keys for comparison
  String? _lastSelectedMap;
  List<String>? _lastSelectedBarangays;
  List<String>? _lastSelectedLakes;
  double? _lastMarkerZoom;
  List<PolygonData>? _cachedUserFilteredPolygons;
  String? _lastUserFilterHash;
  double _lastZoomUpdate = 15.0;
  LatLngBounds? _currentViewport;
  Timer? _viewportDebounce;
  DateTime? _lastViewportUpdate;
  Timer? _polygonUpdateDelay; // NEW: For testing viewport culling

  bool isUpdatingViewport = false; // NEW: Show loading indicator
  Timer? _positionSaveTimer;
  LatLng? _initialCenter;
  double? _initialZoom;
  bool _isInitializing = true;
  bool _hasInitializedPosition = false;

  @override
  void initState() {
    super.initState();
    _currentZoom = widget.zoomLevel;
    _lastZoomUpdate = widget.zoomLevel;

 WidgetsBinding.instance.addPostFrameCallback((_) {
    // Initialize cache without waiting for it
    TileCacheService.initialize().catchError((e) {
      debugPrint('⚠️ Tile cache initialization failed (non-critical): $e');
    });
  });

     _loadInitialPosition();

    // Listen for map events to detect zoom changes
    widget.mapController.mapEventStream.listen((event) {
      // Get current zoom from map controller
      final currentZoom = widget.mapController.camera.zoom;

      // Check if zoom has changed
      if ((currentZoom - _lastZoomUpdate).abs() > 0.01) {
        _lastZoomUpdate = currentZoom;
        _handleZoomWithDebounce(currentZoom);
      }

      // Handle map move end as before
      if (event is MapEventMoveEnd || event is MapEventRotateEnd) {
        _handleMapMoveEnd();
        _scheduleSavePosition();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _currentViewport = widget.mapController.camera.visibleBounds;
         _initializeMapPosition();
      }
    });
  }



 Future<void> _loadInitialPosition() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isFarmer = userProvider.isFarmer;
    final farmerId = userProvider.farmer?.id.toString();

    view_port_helper.MapPosition? targetPosition;

    // Priority 1: Try to load saved position
    final savedPosition = await MapPositionService.getSavedPosition();
    
    if (savedPosition != null) {
      targetPosition = savedPosition;
      // print('📍 Restoring saved position: ${savedPosition.center}, zoom: ${savedPosition.zoom}');
    } 
    // Priority 2: For farmers, calculate position based on their farms
    else if (isFarmer && farmerId != null) {
      final farmerPolygons = widget.polygonManager.polygons
          .where((p) => p.farmerId?.toString() == farmerId)
          .toList();
      
      targetPosition = MapPositionService.calculateFarmerPosition(farmerPolygons);
      
      if (targetPosition != null) {
        // print('🚜 Positioning farmer map to their farms: ${targetPosition.center}');
      }
    }

    // Apply the position
    if (targetPosition != null && mounted) {
      setState(() {
        _initialCenter = targetPosition?.center;
        _initialZoom = targetPosition?.zoom;
        _isInitializing = false;
      });
    } else {
  
      setState(() {
        _isInitializing = false;
      });
    }
  }


   


 







   Future<void> _initializeMapPosition() async {
    if (_hasInitializedPosition) return;
    _hasInitializedPosition = true;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isFarmer = userProvider.isFarmer;
    final farmerId = userProvider.farmer?.id.toString();

    view_port_helper.MapPosition? targetPosition;

    // Priority 1: Try to load saved position
    final savedPosition = await MapPositionService.getSavedPosition();
    
    if (savedPosition != null) {
      // User has a recent saved position - use it
      targetPosition = savedPosition;
      // print('📍 Restoring saved position: ${savedPosition.center}, zoom: ${savedPosition.zoom}');
    } 
    // Priority 2: For farmers, calculate position based on their farms
    else if (isFarmer && farmerId != null) {
      final farmerPolygons = widget.polygonManager.polygons
          .where((p) => p.farmerId?.toString() == farmerId)
          .toList();
      
      targetPosition = MapPositionService.calculateFarmerPosition(farmerPolygons);
      
      if (targetPosition != null) {
        // print('🚜 Positioning farmer map to their farms');
      }
    }

    // Apply the position if we found one
    if (targetPosition != null && mounted) {
      widget.animatedMapController.animateTo(
        dest: targetPosition.center,
        zoom: targetPosition.zoom,
        curve: Curves.easeInOut,
      );
    } else {
    
    }
  }


   void _scheduleSavePosition() {
    _positionSaveTimer?.cancel();
    _positionSaveTimer = Timer(const Duration(seconds: 2), () {
      _saveCurrentPosition();
    });
  }

  // NEW: Save current map position
  Future<void> _saveCurrentPosition() async {
    try {
      final center = widget.mapController.camera.center;
      final zoom = widget.mapController.camera.zoom;
      await MapPositionService.savePosition(center, zoom);
    
    } catch (e) {
      
    }
  }


void _handleMapMoveEnd() {
  final newZoom = widget.mapController.camera.zoom;
  final newViewport = widget.mapController.camera.visibleBounds;
  
  // DEBUG: Print map move end event
  // print('🔄 MAP_MOVE_END - Zoom: ${newZoom.toStringAsFixed(2)}, Viewport changed');
  
  bool needsUpdate = false;
  
  // Check if zoom changed significantly
  if ((newZoom - _currentZoom).abs() > 0.5) {
    _currentZoom = newZoom;
    _cachedBarangayMarkers = null;
    _cachedLakeMarkers = null;
    _lastMarkerZoom = null;
    needsUpdate = true;
    // print('📊 ZOOM_CHANGE - Old: ${_currentZoom.toStringAsFixed(2)}, New: ${newZoom.toStringAsFixed(2)}');
  }
  
  // Check if viewport changed significantly
  if (_shouldUpdateViewport(newViewport)) {
    _currentViewport = newViewport;
    _cachedBarangayMarkers = null;
    _cachedLakeMarkers = null;
    needsUpdate = true;
    // print('📍 VIEWPORT_CHANGE - Significant move detected');
  }
  
  // Single setState after all checks
  if (needsUpdate && mounted) {
    // print('🚀 SETSTATE_TRIGGERED - Updating map layers');
    setState(() {});
  } else {
    // print('⏭️  NO_UPDATE_NEEDED - Changes too small');
  }
}


void _handleZoomWithDebounce(double newZoom) {
  // DEBUG: Print zoom start
  // print('🎯 ZOOM_START - Target: ${newZoom.toStringAsFixed(2)}');
  
  // Cancel existing timer
  _zoomDebounceTimer?.cancel();
  
  // Set new timer with 250ms delay
  _zoomDebounceTimer = Timer(const Duration(milliseconds: 650), () {
    // Only update if zoom changed significantly
    if ((newZoom - _currentZoom).abs() > 0.2) {
      _currentZoom = newZoom;
      _cachedBarangayMarkers = null;
      _cachedLakeMarkers = null;
      _lastMarkerZoom = null;
      
      // print('✅ ZOOM_UPDATE_COMPLETE - New zoom: ${_currentZoom.toStringAsFixed(2)}');
      
      if (mounted) {
        // print('🚀 SETSTATE_CALLED from zoom handler');
        setState(() {});
      }
    } else {
      // print('⏭️  ZOOM_IGNORED - Change too small: ${(newZoom - _currentZoom).abs().toStringAsFixed(2)}');
    }
  });
}

@override
void didUpdateWidget(MapContent oldWidget) {
  super.didUpdateWidget(oldWidget);
  
  // print('🔄 DID_UPDATE_WIDGET called');
  
  if (widget.zoomLevel != oldWidget.zoomLevel) {
    // print('📐 EXTERNAL_ZOOM_CHANGE - From: ${oldWidget.zoomLevel}, To: ${widget.zoomLevel}');
    _handleZoomWithDebounce(widget.zoomLevel);
  }
}

int _rebuildCount = 0;
Stopwatch _rebuildTimer = Stopwatch()..start();




bool _shouldUpdateViewport(LatLngBounds newViewport) {
  if (_currentViewport == null) return true;

  // NEW: Don't update more than once every 500ms
  if (_lastViewportUpdate != null && 
      DateTime.now().difference(_lastViewportUpdate!).inMilliseconds < 500) {
    // print('⏱️  VIEWPORT_UPDATE_SKIPPED - Too soon since last update');
    return false;
  }

  // Only update if viewport moved significantly (25% of current viewport)
  final latDiff = (_currentViewport!.north - _currentViewport!.south).abs();
  final lngDiff = (_currentViewport!.east - _currentViewport!.west).abs();

  final centerLatDiff = ((newViewport.north + newViewport.south) / 2 -
          (_currentViewport!.north + _currentViewport!.south) / 2)
      .abs();
  final centerLngDiff = ((newViewport.east + newViewport.west) / 2 -
          (_currentViewport!.east + _currentViewport!.west) / 2)
      .abs();

  final shouldUpdate = centerLatDiff > latDiff * 0.25 || centerLngDiff > lngDiff * 0.25;
  
  // NEW: Update timestamp if we're going to update
  if (shouldUpdate) {
    _lastViewportUpdate = DateTime.now();
    // print('📍 VIEWPORT_UPDATE_ALLOWED - Center moved: '
    //       'Lat ${centerLatDiff.toStringAsFixed(6)}, '
    //       'Lng ${centerLngDiff.toStringAsFixed(6)}');
  }
  
  return shouldUpdate;
}


  @override
  void dispose() {
    _zoomDebounceTimer?.cancel();
    _cachedTileLayer = null;
    _cachedBarangayLayer = null;
    _cachedLakeLayer = null;
    _cachedBarangayMarkers = null;
    _cachedLakeMarkers = null;
    _viewportDebounce?.cancel();
    _polygonUpdateDelay?.cancel();
 _positionSaveTimer?.cancel();

  // Save position one last time on dispose
    _saveCurrentPosition();

    super.dispose();
  }

  List<PolygonData> _getViewportFilteredPolygons(List<PolygonData> polygons) {
    if (_currentViewport == null) {
      // print('⚠️ No viewport yet, showing all ${polygons.length} polygons');
      return polygons;
    }

    final padding = ViewportHelper.getAdaptivePadding(_currentZoom);
    final stopwatch = Stopwatch()..start();

    int inViewport = 0;
    int culled = 0;

    final filtered = polygons.where((polygon) {
      final isInside = ViewportHelper.isPolygonInViewport(
        polygon.vertices,
        _currentViewport!,
        paddingDegrees: padding,
      );

      if (isInside) {
        inViewport++;
      } else {
        culled++;
        // LOG FIRST 5 CULLED ITEMS TO SEE WHY
        if (culled <= 5) {
          ViewportHelper.calculateCenter(polygon.vertices);
          // print(
          //     '   ❌ CULLED: "${polygon.name}" at (${center.latitude.toStringAsFixed(4)}, ${center.longitude.toStringAsFixed(4)})');
        }
      }

      return isInside;
    }).toList();

    stopwatch.stop();

    return filtered;
  }

  // Generate hash for user filter state
  String _getUserFilterHash() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return '${userProvider.isFarmer}_${userProvider.farmer?.id}_'
        '${widget.showOwnedFarmsOnly}_${widget.showActiveFarmsOnly}_'
        '${widget.areaFilterActive}_' // Use widget.areaFilterActive
        '${widget.polygonManager.polygons.length}';
  }

  List<PolygonData> _getUserFilteredPolygons() {
    final currentHash = _getUserFilterHash();

    if (_cachedUserFilteredPolygons != null &&
        _lastUserFilterHash == currentHash) {
      return _cachedUserFilteredPolygons!;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isFarmer = userProvider.isFarmer;
    final farmerId = userProvider.farmer?.id.toString();

    // If area filter is active (barangay or lake selected), skip user filtering
    if (widget.areaFilterActive) {
      _cachedUserFilteredPolygons = widget.polygonManager.polygons;
      _lastUserFilterHash = currentHash;
      return _cachedUserFilteredPolygons!;
    }

    // Otherwise, apply normal user filtering
    _cachedUserFilteredPolygons =
        widget.polygonManager.polygons.where((polygon) {
      if (isFarmer && widget.showOwnedFarmsOnly) {
        if (polygon.farmerId?.toString() != farmerId) return false;
      } else if (!isFarmer && widget.showActiveFarmsOnly) {
        if (polygon.status?.toLowerCase() != 'active' &&
            polygon.status != null) {
          return false;
        }
      } else if (!isFarmer && !widget.showActiveFarmsOnly) {
        if (polygon.status?.toLowerCase() == 'active' ||
            polygon.status == null) {
          return false;
        }
      }
      return true;
    }).toList();

    _lastUserFilterHash = currentHash;
    return _cachedUserFilteredPolygons!;
  }

  bool _listEquals(List<String>? a, List<String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [ 
        // Main map content
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.92,
          width: MediaQuery.of(context).size.width,
          child: ValueListenableBuilder<int>(
            valueListenable: widget.polygonManager.editorUpdateNotifier,
            builder: (context, updateCount, child) {

// print('📦 VALUE_LISTENABLE_BUILDER - Update count: $updateCount');

              final userProvider =
                  Provider.of<UserProvider>(context, listen: false);
              final isFarmer = userProvider.isFarmer;

              final userFilteredPolygons = _getUserFilteredPolygons();

              final viewportPolygons =
                  _getViewportFilteredPolygons(userFilteredPolygons);

              final filteredPolygons =
                  widget.polygonManager.getFilteredPolygons(
                widget.farmTypeFilters,
                showExceedingAreaOnly: widget.showExceedingAreaOnly,
                basePolygons: viewportPolygons,
              );

              final filteredPinStyles =
                  filteredPolygons.map((p) => p.pinStyle).toList();
              final filteredColors =
                  filteredPolygons.map((p) => p.color).toList();

              final filteredBarangays =
                  widget.polygonManager.selectedBarangays.isNotEmpty
                      ? widget.barangayManager.barangays
                          .where((barangay) => widget
                              .polygonManager.selectedBarangays
                              .contains(barangay.name))
                          .toList()
                      : widget.barangayManager.barangays;

              final filteredLakes =
                  widget.polygonManager.selectedLakes.isNotEmpty
                      ? widget.lakeManager.lakes
                          .where((lake) => widget.polygonManager.selectedLakes
                              .contains(lake.name))
                          .toList()
                      : widget.lakeManager.lakes;

              return FlutterMap(
                mapController: widget.mapController,
                options: _buildMapOptions(context),
                children: [
                  // CACHED: Base tile layer
                  _buildCachedTileLayer(),

                  // CACHED: Lake polygons layer
                  _buildCachedLakeLayer(filteredLakes),

                  if (widget.showAreaMarkers) _buildCachedLakeMarkers(),

                  // Polyline layer (dynamic, needs ValueListenableBuilder)
                  ValueListenableBuilder<LatLng?>(
                    valueListenable: widget.previewPointNotifier,
                    builder: (context, previewPoint, child) {
                      return MapLayersHelper.createPolylineLayer(
                        filteredPolygons
                            .map((polygon) => polygon.vertices)
                            .toList(),
                        widget.polygonManager.currentPolygon,
                        previewPoint,
                        widget.polygonManager.isDrawing,
                      );
                    },
                  ),

                  // CACHED: Barangay polygons layer
                  _buildCachedBarangayLayer(filteredBarangays),

                  // CACHED: Barangay center markers (only at zoom >= 13)
                  if (widget.showAreaMarkers) // Remove zoom restriction
                    _buildCachedBarangayMarkers(),

                  // if (!_debugShowAllPolygons)
                  MapLayersHelper.createPolygonLayer(
                    filteredPolygons
                        .map((polygon) => polygon.vertices)
                        .toList(),
                    widget.polygonManager.currentPolygon,
                    filteredColors,
                    defaultColor: Colors.blue,
                    selectedPolygonIndex:
                        widget.polygonManager.selectedPolygonIndex != null
                            ? filteredPolygons.indexWhere((p) =>
                                widget.polygonManager.polygons.indexOf(p) ==
                                widget.polygonManager.selectedPolygonIndex)
                            : null,
                  ),

                  // Polygon markers layer
                  MapLayersHelper.createMarkerLayer(
                    filteredPolygons
                        .map((polygon) => polygon.vertices)
                        .toList(),
                    widget.polygonManager.currentPolygon,
                    widget.polygonManager.selectedPolygonIndex != null
                        ? filteredPolygons.indexWhere((p) =>
                            widget.polygonManager.polygons.indexOf(p) ==
                            widget.polygonManager.selectedPolygonIndex)
                        : null,
                    widget.polygonManager.isEditing,
                    (filteredIndex, vertexIndex) {
                      if (widget.polygonManager.isEditing) {
                        widget.setState(() {
                          final polygon = filteredPolygons[filteredIndex];
                          final originalIndex =
                              widget.polygonManager.polygons.indexOf(polygon);
                          widget.polygonManager.selectPolygon(originalIndex);
                          if (widget.polygonManager.selectedPolygon != null) {
                            widget.polygonManager.initializePolyEditor(
                                widget.polygonManager.selectedPolygon!);
                          }
                        });
                      }
                    },
                    (i) {
                      if (i == 0 &&
                          widget.polygonManager.currentPolygon.length > 2) {
                        widget.setState(() {
                          widget.polygonManager.completeCurrentPolygon(context);
                        });
                      }
                    },
                    filteredPinStyles,
                    widget.polygonManager,
                    context,
                    isFarmer,
                  ),

                  // Drag markers for polygon editing
                  if (widget.polygonManager.isEditing &&
                      widget.polygonManager.selectedPolygon != null)
                    ValueListenableBuilder<int>(
                      valueListenable:
                          widget.polygonManager.editorUpdateNotifier,
                      builder: (context, updateCount, child) {
                        return DragMarkers(
                          markers:
                              widget.polygonManager.polyEditor?.edit() ?? [],
                        );
                      },
                    ),

                  // Drawing helper text
                  _buildDrawingHelper(),

                  // Live measurement overlay
                  _buildLiveMeasurementOverlay(),
                ],
              );
            },
          ),
        ),
      ],
    );
  }




Widget _buildCachedTileLayer() {
  if (_cachedTileLayer == null || _lastSelectedMap != widget.selectedMap) {
    _lastSelectedMap = widget.selectedMap;
    _cachedTileLayer = TileLayer(
      tileProvider: CachedTileProvider(), // Use cached provider
      urlTemplate: MapLayersHelper.availableLayers[widget.selectedMap]!,
      maxNativeZoom: 18,
      keepBuffer: 2,
      // Optional: Add these for better offline behavior
      errorTileCallback: (tile, error, stackTrace) {
        debugPrint('⚠️ Tile load error: ${tile.coordinates}');
      },
      fallbackUrl: MapLayersHelper.availableLayers[widget.selectedMap]!,
    );
  }
  return _cachedTileLayer!;
}

  Widget _buildCachedBarangayLayer(List<PolygonData> filteredBarangays) {
    // Always show when any barangay is selected
    if (widget.polygonManager.selectedBarangays.isNotEmpty) {
      final currentSelection = widget.polygonManager.selectedBarangays;

      // Force rebuild if selection changed or layer is null
      if (_cachedBarangayLayer == null ||
          !_listEquals(_lastSelectedBarangays, currentSelection)) {
        _lastSelectedBarangays = List.from(currentSelection);
        _cachedBarangayLayer = MapLayersHelper.createOptimizedBarangayLayer(
          filteredBarangays,
          currentZoom: _currentZoom,
        );
      }
      return _cachedBarangayLayer!;
    }

    _cachedBarangayLayer = null;
    return const SizedBox.shrink();
  }

  Widget _buildCachedLakeLayer(List<PolygonData> filteredLakes) {
    // Always show when any lake is selected
    if (widget.polygonManager.selectedLakes.isNotEmpty) {
      final currentSelection = widget.polygonManager.selectedLakes;

      // Force rebuild if selection changed or layer is null
      if (_cachedLakeLayer == null ||
          !_listEquals(_lastSelectedLakes, currentSelection)) {
        _lastSelectedLakes = List.from(currentSelection);
        _cachedLakeLayer = MapLayersHelper.createOptimizedLakeLayer(
          filteredLakes,
          currentZoom: _currentZoom,
        );
      }
      return _cachedLakeLayer!;
    }

    _cachedLakeLayer = null;
    return const SizedBox.shrink();
  }

  Widget _buildCachedBarangayMarkers() {
    if (_cachedBarangayMarkers != null && !_shouldRecalculateMarkers()) {
      return _cachedBarangayMarkers!;
    }

    if (_currentViewport == null) return const SizedBox.shrink();

    final currentSelection = widget.polygonManager.selectedBarangays;
    final zoomChanged = _lastMarkerZoom == null ||
        (_currentZoom - _lastMarkerZoom!).abs() > 0.5;

    if (_cachedBarangayMarkers == null ||
        !_listEquals(_lastSelectedBarangays, currentSelection) ||
        zoomChanged) {
      _lastMarkerZoom = _currentZoom;

      // CRITICAL: Only render barangays in viewport
      final padding = ViewportHelper.getAdaptivePadding(_currentZoom);
      final visibleBarangays = widget.barangayManager.barangays.where((b) {
        return ViewportHelper.isPolygonInViewport(
          b.vertices,
          _currentViewport!,
          paddingDegrees: padding,
        );
      }).toList();

      _cachedBarangayMarkers =
          MapLayersHelper.createBarangayMarkersWithLabels(
        visibleBarangays, // Use filtered list
        _handleBarangayMarkerTap,
        circleColor: const Color.fromARGB(255, 74, 72, 72),
        iconColor: Colors.white, 
        filteredBarangays: currentSelection,
        currentZoom: _currentZoom,
      );
    }
    return _cachedBarangayMarkers!;
  }




  bool _shouldRecalculateMarkers() {
    final currentSelection = widget.polygonManager.selectedBarangays;
    final zoomChanged = _lastMarkerZoom == null ||
        (_currentZoom - _lastMarkerZoom!).abs() > 0.5;

    return !_listEquals(_lastSelectedBarangays, currentSelection) ||
        zoomChanged;
  }

  Widget _buildCachedLakeMarkers() {
    if (_currentViewport == null) return const SizedBox.shrink();

    final currentSelection = widget.polygonManager.selectedLakes;
    final zoomChanged = _lastMarkerZoom == null ||
        (_currentZoom - _lastMarkerZoom!).abs() > 0.5;

    if (_cachedLakeMarkers == null ||
        !_listEquals(_lastSelectedLakes, currentSelection) ||
        zoomChanged) {
      _lastMarkerZoom = _currentZoom;

      final padding = ViewportHelper.getAdaptivePadding(_currentZoom);
      final visibleLakes = widget.lakeManager.lakes.where((l) {
        return ViewportHelper.isPolygonInViewport(
          l.vertices,
          _currentViewport!,
          paddingDegrees: padding,
        );
      }).toList();

      // print(
      //     'Rendering ${visibleLakes.length}/${widget.lakeManager.lakes.length} lakes');

      _cachedLakeMarkers = MapLayersHelper.createLakeMarkersWithLabels(
        visibleLakes,
        _handleLakeMarkerTap,
        circleColor: const Color.fromARGB(255, 59, 107, 145),
        iconColor: Colors.white, 
        filteredLakes: currentSelection,
        currentZoom: _currentZoom,
      );
    }
    return _cachedLakeMarkers!;
  }

  // ========== HELPER WIDGETS ==========

  Widget _buildDrawingHelper() {
    return ValueListenableBuilder<LatLng?>(
      valueListenable: widget.previewPointNotifier,
      builder: (context, previewPoint, child) {
        if (widget.polygonManager.isDrawing &&
            widget.polygonManager.currentPolygon.length > 2) {
          return IgnorePointer(
            ignoring: true,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  context.translate(
                      "Click the first point to close shape and save it"),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  bool get isMobilePlatform {
  // Native mobile apps
  if (Platform.isAndroid || Platform.isIOS) return true;
  
  // Mobile web browsers
  final mediaQuery = MediaQuery.of(context);
  final screenWidth = mediaQuery.size.width;
  final isMobileWeb = screenWidth < 768; // Tablet breakpoint
  
  return isMobileWeb;
}


// Replace your _buildLiveMeasurementOverlay method with this:

Widget _buildLiveMeasurementOverlay() {
  return ValueListenableBuilder<LatLng?>(
    valueListenable: widget.previewPointNotifier,
    builder: (context, previewPoint, child) {
      if (!widget.polygonManager.isDrawing) {
        return const SizedBox.shrink();
      }
      
      // DEBUG: Print current state
      print('DEBUG: isDrawing: ${widget.polygonManager.isDrawing}');
      print('DEBUG: currentPolygon length: ${widget.polygonManager.currentPolygon.length}');
      print('DEBUG: previewPoint: $previewPoint');
      
      // Platform detection - web-safe version
      final bool isMobile = _isMobilePlatform();
      
      if (isMobile) {
        // Use mobile-friendly overlay with STABLE KEY
        print('DEBUG: Using MobileMeasurementOverlay');
        return MobileMeasurementOverlay(
          key: const ValueKey('mobile_measurement_overlay'), // CRITICAL: Stable key
          currentPolygon: widget.polygonManager.currentPolygon,
        );
      } else {
        // Use original overlay with preview point for web/desktop
        print('DEBUG: Using MeasurementOverlay with preview');
        return MeasurementOverlay(
          key: const ValueKey('desktop_measurement_overlay'), // Add key here too
          currentPolygon: widget.polygonManager.currentPolygon,
          previewPoint: previewPoint,
        );
      }
    },
  );
}

// Web-safe platform detection helper
bool _isMobilePlatform() {
  // Check if running on web first
  if (kIsWeb) {
    // For web, use screen size to detect mobile
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < 768; // Mobile if width < 768px
  }
  
  // For native apps
  return Platform.isAndroid || Platform.isIOS;
}

// ========== EVENT HANDLERS ==========

void _handleBarangayMarkerTap(PolygonData barangay) {
  widget.animatedMapController.animatedFitCamera(
    cameraFit: CameraFit.coordinates(
      coordinates: barangay.vertices,
      padding: const EdgeInsets.all(30),
    ),
    curve: Curves.easeInOut,
  );

  widget.polygonManager
      .showBarangayInfo(context, barangay, widget.polygonManager.polygons);

  if (widget.onBarangayFilterChanged != null) {
    final isDeselecting =
        widget.polygonManager.selectedBarangays.contains(barangay.name);

    widget.setState(() {
      if (isDeselecting) {
        // Deselecting - clear all filters
        widget.onBarangayFilterChanged!([]);
        widget.polygonManager.selectedBarangays.clear();
        
        // CLEAR LAKE FILTER TOO
        if (widget.onLakeFilterChanged != null) {
          widget.onLakeFilterChanged!([]);
          widget.polygonManager.selectedLakes.clear();
        }
        
        widget.onAreaFilterChanged(false);
      } else {
        // Selecting a barangay - clear lake filter first
        if (widget.onLakeFilterChanged != null) {
          widget.onLakeFilterChanged!([]);
          widget.polygonManager.selectedLakes.clear();
        }
        
        // Then apply barangay filter
        widget.onBarangayFilterChanged!([barangay.name]);
        widget.polygonManager.selectedBarangays = [barangay.name];
        widget.onAreaFilterChanged(true);
      }

      // FORCE CACHE INVALIDATION
      _cachedBarangayLayer = null;
      _cachedBarangayMarkers = null;
      _cachedLakeLayer = null;
      _cachedLakeMarkers = null;
      _cachedUserFilteredPolygons = null;
      _lastUserFilterHash = null;
      _lastSelectedBarangays = null;
      _lastSelectedLakes = null;
    });
  }
}

void _handleLakeMarkerTap(PolygonData lake) {
  widget.animatedMapController.animatedFitCamera(
    cameraFit: CameraFit.coordinates(
      coordinates: lake.vertices,
      padding: const EdgeInsets.all(30),
    ),
    curve: Curves.easeInOut,
  );

  widget.polygonManager
      .showLakenInfo(context, lake, widget.polygonManager.polygons);

  if (widget.onLakeFilterChanged != null) {
    final isDeselecting =
        widget.polygonManager.selectedLakes.contains(lake.name);

    widget.setState(() {
      if (isDeselecting) {
        // Deselecting - clear all filters
        widget.onLakeFilterChanged!([]);
        widget.polygonManager.selectedLakes.clear();
        
        // CLEAR BARANGAY FILTER TOO
        if (widget.onBarangayFilterChanged != null) {
          widget.onBarangayFilterChanged!([]);
          widget.polygonManager.selectedBarangays.clear();
        }
        
        widget.onAreaFilterChanged(false);
      } else {
        // Selecting a lake - clear barangay filter first
        if (widget.onBarangayFilterChanged != null) {
          widget.onBarangayFilterChanged!([]);
          widget.polygonManager.selectedBarangays.clear();
        }
        
        // Then apply lake filter
        widget.onLakeFilterChanged!([lake.name]);
        widget.polygonManager.selectedLakes = [lake.name];
        widget.onAreaFilterChanged(true);
      }

      // FORCE CACHE INVALIDATION
      _cachedLakeLayer = null;
      _cachedLakeMarkers = null;
      _cachedBarangayLayer = null;
      _cachedBarangayMarkers = null;
      _cachedUserFilteredPolygons = null;
      _lastUserFilterHash = null;
      _lastSelectedLakes = null;
      _lastSelectedBarangays = null;
    });
  }
}




  MapOptions _buildMapOptions(BuildContext context) {
    return MapOptions(
      center: _initialCenter ?? const LatLng(14.077557, 121.328938),
      zoom: widget.zoomLevel,
      minZoom: 12,
      maxBounds: LatLngBounds(
        const LatLng(13.877557, 121.128938),
        const LatLng(14.277557, 121.528938),
      ),
      onTap: (_, LatLng point) {
        widget.setState(() {
          if (widget.polygonManager.isDrawing) {
            widget.polygonManager.handleDrawingTap(point);
          } else if (widget.polygonManager.isEditing) {
            widget.polygonManager.handleSelectionTap(point, context);
          } else {
            widget.polygonManager.handleSelectionTap(point, context);
          }
        });
      },
    );
  }
 



}
