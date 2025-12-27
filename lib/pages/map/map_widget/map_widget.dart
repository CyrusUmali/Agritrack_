// ignore_for_file: library_private_types_in_public_api

import 'dart:math';
import 'package:flareline/core/models/farmer_model.dart';
import 'package:flareline/core/models/product_model.dart';
import 'package:flareline/pages/map/map_widget/farm_list_panel/barangay_filter_panel.dart';
import 'package:flareline/pages/map/map_widget/farm_service.dart';
import 'package:flareline/pages/map/map_widget/map_panel/polygon_modal_components/farm_info_card.dart';
import 'package:flareline/pages/toast/toast_helper.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flareline/pages/map/map_widget/legend_panel.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

import 'farm_list_panel/farm_list.dart';
import 'stored_polygons.dart';
import 'map_controls.dart';
import 'map_layers.dart';
import 'polygon_manager.dart';
import 'map_content.dart';

class MapWidget extends StatefulWidget {
  const MapWidget({
    super.key,
    required this.routeObserver,
    required this.farmService,
    required this.products,
    required this.farmers,
  });

  final RouteObserver<ModalRoute> routeObserver;
  final FarmService farmService;
  final List<Product> products;
  final List<Farmer> farmers;

  @override
  _MapWidgetState createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget>
    with TickerProviderStateMixin, RouteAware { 
  String selectedMap = "Google Satellite (No Labels)";
  bool _showFarmListPanel = false;
  bool _showLegendPanel = false;
  bool _showAreaMarkers = false;
  double zoomLevel = 15.0;
  LatLng? previewPoint;
  bool _isLoading = true;
  String? _loadingError;
  DateTime? _lastPointerUpdate;
  bool _showExceedingAreaOnly = false;
  bool get hasExceedingAreaFilter => _showExceedingAreaOnly;

  bool get isMobile => MediaQuery.of(context).size.width < 600;
  bool _areaFilterActive = false;
  bool _showOwnedFarmsOnly = true;
  bool _showActiveFarmsOnly = true;

  late final AnimatedMapController _animatedMapController;
  late PolygonManager polygonManager;
  late BarangayManager barangayManager;

  late LakeManager lakeManager;

  final ValueNotifier<LatLng?> previewPointNotifier = ValueNotifier(null);
  late final RenderBox _renderBox;
  LatLng? _lastPoint;
 
  void _toggleUserFilter() {
    setState(() {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final isFarmer = userProvider.isFarmer;

      if (isFarmer) {
        _showOwnedFarmsOnly = !_showOwnedFarmsOnly;

        BarangayFilterPanel.userFilterOptions['showOwnedOnly'] =
            _showOwnedFarmsOnly;
      } else {
        _showActiveFarmsOnly = !_showActiveFarmsOnly;
        BarangayFilterPanel.userFilterOptions['showActiveOnly'] =
            _showActiveFarmsOnly;
      }

      polygonManager.onFiltersChanged!();
    });
  }

  @override
  void initState() {
    super.initState();

    _loadFarmsFromApi();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _renderBox = context.findRenderObject() as RenderBox;
    });
    FarmInfoCard.loadBarangays();

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isFarmer = userProvider.isFarmer;

    _animatedMapController = AnimatedMapController(vsync: this);
    polygonManager = PolygonManager(
      context: context,
      mapController: _animatedMapController,
      onPolygonSelected: hideFarmListPanel,
      products: widget.products,
      farmers: widget.farmers,
      farmService: widget.farmService,
      onFiltersChanged: () => setState(() {}),
      isFarmer: isFarmer,
      onDrawingStateChanged: (isDrawing) {
        setState(() {
          _showAreaMarkers = !isDrawing;
        });
      },
    );

    barangayManager = BarangayManager();
    barangayManager.loadBarangays(barangays);

    lakeManager = LakeManager();
    lakeManager.loadLakes(lakes);
  }

  Future<void> _loadFarmsFromApi() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _loadingError = null;
    });

    try {
      final farmsData = await widget.farmService.fetchFarms();

      if (!mounted) return;

      final polygonsToLoad =
          farmsData.map((map) => PolygonData.fromMap(map)).toList();
      polygonManager.loadPolygons(polygonsToLoad);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingError = e.toString();
      });
      if (mounted) {
        ToastHelper.showErrorToast(
          'Failed to load farms: ${e.toString()}',
          context,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void hideFarmListPanel() {
    setState(() {
      _showFarmListPanel = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final route = ModalRoute.of(context);
    if (route == null) return;

    final navigator = Navigator.of(context);
    for (final observer in navigator.widget.observers) {
      if (observer is RouteObserver<ModalRoute>) {
        observer.subscribe(this, route);
        break;
      }
    }
    }

  @override
  void dispose() {
    widget.routeObserver.unsubscribe(this);
    polygonManager.dispose();
    _animatedMapController.dispose();
    previewPointNotifier.dispose();
    super.dispose();
  }

  @override
  void didPush() {
    polygonManager.removeInfoCardOverlay();
  }

  @override
  void didPop() {
    polygonManager.removeInfoCardOverlay();
  }

  @override
  void didPopNext() {
    polygonManager.removeInfoCardOverlay();
  }

  @override
  void didPushNext() {
    polygonManager.removeInfoCardOverlay();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isFarmer = userProvider.isFarmer;
    final farmerId = userProvider.farmer?.id.toString();

    bool canUserEditPolygon(PolygonData? polygon) {
      if (!isFarmer) {
        return true;
      }

      if (polygon?.farmerId != null && farmerId != null) {
        return polygon!.farmerId.toString() == farmerId;
      }

      return false;
    }

    if (_isLoading) {
      return SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Center(
          child: LoadingAnimationWidget.inkDrop(
            color: Colors.blue,
            size: 50,
          ),
        ),
      );
    }

    if (_loadingError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error loading data', style: TextStyle(color: Colors.red)),
            Text(_loadingError!),
            ElevatedButton(
              onPressed: _loadFarmsFromApi,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: <Widget>[
        Listener(
          onPointerMove: (event) {
            if (!polygonManager.isDrawing) return;
            try {
              final renderBox =
                  _renderBox;
              final localPosition = renderBox.globalToLocal(event.position);
              final newPoint = _animatedMapController.mapController.camera
                  .pointToLatLng(Point(localPosition.dx, localPosition.dy));
              if (_lastPoint == null ||
                  (newPoint.latitude - _lastPoint!.latitude).abs() > 0.0001 ||
                  (newPoint.longitude - _lastPoint!.longitude).abs() > 0.0001) {
                _lastPoint = newPoint;
                previewPointNotifier.value = newPoint;
              }
            } catch (e) {
              debugPrint('Error in pointer move: $e');
            }
          },
          child: MouseRegion(
            onHover: (event) {
              if (!polygonManager.isDrawing) return;

              final now = DateTime.now();
              if (_lastPointerUpdate != null &&
                  now.difference(_lastPointerUpdate!).inMilliseconds < 50) {
                return;
              }
              _lastPointerUpdate = now;

              try {
                final renderBox = context.findRenderObject() as RenderBox?;
                if (renderBox == null) return;
                final localPosition = renderBox.globalToLocal(event.position);
                final newPoint = _animatedMapController.mapController.camera
                    .pointToLatLng(Point(localPosition.dx, localPosition.dy));
                previewPointNotifier.value = newPoint;
              } catch (e) {
                debugPrint('Error in hover: $e');
              }
            },
            child: MapContent(
              mapController: _animatedMapController.mapController,
              selectedMap: selectedMap,
              zoomLevel: zoomLevel,
              polygonManager: polygonManager,
              barangayManager: barangayManager,
              lakeManager: lakeManager,
              previewPointNotifier: previewPointNotifier,
              setState: setState,
              lakeFilter: polygonManager.selectedLakes,
              barangayFilter: polygonManager.selectedBarangays,
              farmTypeFilters: BarangayFilterPanel.filterOptions,
              productFilters: polygonManager.selectedProducts,
              animatedMapController: _animatedMapController,
              showExceedingAreaOnly: _showExceedingAreaOnly,
              showAreaMarkers: _showAreaMarkers,
              showOwnedFarmsOnly: _showOwnedFarmsOnly,
              showActiveFarmsOnly: _showActiveFarmsOnly,
              areaFilterActive: _areaFilterActive,
              onAreaFilterChanged: (bool isActive) {
                setState(() {
                  _areaFilterActive = isActive;
                });
              },
              onBarangayFilterChanged: (newFilters) {
                setState(() {
                  polygonManager.selectedBarangays = newFilters;
                  hideFarmListPanel();
                });
              },
              onLakeFilterChanged: (newFilters) {
                setState(() {
                  polygonManager.selectedLakes = newFilters;
                  hideFarmListPanel();
                });
              },
            ),
          ),
        ),
        if (_showFarmListPanel)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: FarmListPanel(
              polygonManager: polygonManager,
              barangayManager: barangayManager,
              lakeManager: lakeManager,
              selectedBarangays: polygonManager.selectedBarangays,
              selectedProducts: polygonManager.selectedProducts,
              showExceedingAreaOnly: _showExceedingAreaOnly,
              onBarangayFilterChanged: (newFilters) {
                polygonManager.updateFilters(barangays: newFilters);
                setState(() {});
              },
              onProductFilterChanged: (newFilters) {
                polygonManager.updateFilters(products: newFilters);
                setState(() {});
              },
              onPolygonSelected: (int index) {
                setState(() {});
              },
              onFiltersChanged: () {
                setState(() {});
              },
            ),
          ),
        if (_showLegendPanel)
          Positioned(
            left: _showFarmListPanel ? 320 : 60,
            top: 20,
            child: LegendPanel(),
          ),
        Positioned(
          top: 15,
          left: _showFarmListPanel ? 290 : 10,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildStyledIconButton(
                icon: _showFarmListPanel
                    ? Icons.arrow_left_rounded
                    : Icons.arrow_right_rounded,
                tooltip: _showFarmListPanel
                    ? 'Hide Farm List'
                    : 'Show Farm List', // ADD THIS
                onPressed: () {
                  setState(() {
                    _showFarmListPanel = !_showFarmListPanel;
                    _showLegendPanel = isMobile ? false : _showLegendPanel;
                    if (_showFarmListPanel) {
                      polygonManager.selectedPolygonIndex = -1;
                      polygonManager.selectedPolygon = null;
                      polygonManager.selectedPolygonNotifier.value = null;
                      polygonManager.removeInfoCardOverlay();
                    }
                  });
                },
                backgroundColor: Colors.white,
                iconSize: 15,
                buttonSize: isMobile ? 40.0 : 30,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              const SizedBox(height: 5),
              _buildUserFilterButton(),
              const SizedBox(height: 5),
              buildStyledIconButton(
                icon:
                    _showLegendPanel ? Icons.info_outline : Icons.info_outline,
                tooltip: _showLegendPanel
                    ? 'Hide Legend'
                    : 'Show Legend', // ADD THIS
                iconColor: _showLegendPanel ? Colors.blue : null,
                onPressed: () {
                  setState(() {
                    _showLegendPanel = !_showLegendPanel;
                    _showFarmListPanel = isMobile ? false : _showFarmListPanel;
                  });
                },
                backgroundColor: Colors.white,
                iconSize: 15,
                buttonSize: isMobile ? 40.0 : 30,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              const SizedBox(height: 5),
              buildStyledIconButton(
                icon: _showAreaMarkers ? Icons.location_on : Icons.location_off,
                tooltip: _showAreaMarkers
                    ? 'Hide Area Markers'
                    : 'Show Area Markers',
                onPressed: () {
                  setState(() {
                    _showAreaMarkers = !_showAreaMarkers;
                  });
                },
                backgroundColor: _showAreaMarkers
                    ? Colors.green.withOpacity(0.9)
                    : Colors.grey.withOpacity(0.9),
                iconColor: _showAreaMarkers ? Colors.blue : null,
                iconSize: 15,
                buttonSize: isMobile ? 40.0 : 30,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              const SizedBox(height: 5),
              buildStyledIconButton(
                icon: _showExceedingAreaOnly
                    ? Icons.square_foot
                    : Icons.square_foot_outlined,
                tooltip: _showExceedingAreaOnly
                    ? 'Show All Areas'
                    : 'Show Exceeding Areas Only',
                onPressed: () {
                  setState(() {
                    _showExceedingAreaOnly = !_showExceedingAreaOnly;
                    polygonManager.selectedPolygonIndex = -1;
                    polygonManager.selectedPolygon = null;
                    polygonManager.selectedPolygonNotifier.value = null;
                    polygonManager.removeInfoCardOverlay();
                    hideFarmListPanel();
                  });
                },
                backgroundColor:
                    _showExceedingAreaOnly ? null : Colors.red.withOpacity(0.9),
                iconColor: _showExceedingAreaOnly ? Colors.red : null,
                iconSize: 15,
                buttonSize: isMobile ? 40.0 : 30,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 15,
          right: 10,
          child: MapControls(
            zoomLevel: zoomLevel,
            isDrawing: polygonManager.isDrawing,
            isEditing: polygonManager.isEditing,
            mapLayers: MapLayersHelper.availableLayers,
            selectedMap: selectedMap,
            selectedPolygonIndex: polygonManager.selectedPolygonIndex,
            onZoomIn: () {
              setState(() {
                _animatedMapController.animatedZoomIn();
              });
            },
            onZoomOut: () {
              setState(() {
                _animatedMapController.animatedZoomOut();
              });
            },
            onToggleDrawing: () {
              setState(() {
                polygonManager.toggleDrawing();
                polygonManager.selectedPolygon = null;
              });
            },
            onToggleEditing: () {
              if (polygonManager.selectedPolygon != null &&
                  !canUserEditPolygon(polygonManager.selectedPolygon)) {
                ToastHelper.showErrorToast(
                  'You can only edit farms that you own.',
                  context,
                );
                return;
              }

              setState(() {
                polygonManager.toggleEditing();
                if (!polygonManager.isEditing) {
                  polygonManager.selectedPolygon = null;
                }
              });
            },
            onMapLayerChange: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  selectedMap = newValue;
                });
              }
            },
            onUndo: () {
              if (polygonManager.canUndo()) {
                setState(() {
                  polygonManager.undoLastPoint();
                });
              }
            },
          ),
        ),
        if (polygonManager.selectedPolygonIndex != null &&
            polygonManager.isEditing &&
            canUserEditPolygon(polygonManager.selectedPolygon))
          Positioned(
            bottom: 20,
            right: 10,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  polygonManager.saveEditedPolygon();
                  polygonManager.selectedPolygon = null;
                  polygonManager.selectedPolygonIndex = null;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                'Save',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        if (polygonManager.selectedLakes.isNotEmpty && !_showFarmListPanel ||
            polygonManager.selectedBarangays.isNotEmpty &&
                !_showFarmListPanel ||
            polygonManager.selectedProducts.isNotEmpty && !_showFarmListPanel ||
            BarangayFilterPanel.filterOptions.values
                    .any((isChecked) => !isChecked) &&
                !_showFarmListPanel)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 20),
              child: ElevatedButton(
                onPressed: () {
                  polygonManager.clearFilters();
                  setState(() {
                    _areaFilterActive = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: Text(
                  'Reset Filters',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserFilterButton() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isFarmer = userProvider.isFarmer;
    final isFilterEnabled =
        isFarmer ? _showOwnedFarmsOnly : _showActiveFarmsOnly;

    final tooltip = isFarmer
        ? (isFilterEnabled ? 'Show All Farms' : 'Show My Farms Only')
        : (isFilterEnabled
            ? 'Show Inactive Farms Only'
            : 'Show Active Farms Only');

    final icon = isFarmer
        ? (isFilterEnabled ? Icons.person : Icons.people)
        : Icons.fiber_manual_record;

    final iconColor = isFilterEnabled ? Colors.green : Colors.red;

    return buildStyledIconButton(
      icon: icon,
      tooltip: tooltip,
      onPressed: _toggleUserFilter,
      backgroundColor: isFilterEnabled
          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
          : Colors.white,
      iconColor: iconColor,
      iconSize: 15,
      buttonSize: isMobile ? 40.0 : 30,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    );
  }

  Widget buildStyledIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip, // NEW: Add tooltip parameter
    Color? backgroundColor,
    Color? iconColor,
    double iconSize = 24.0,
    double buttonSize = 48.0,
    ShapeBorder? shape,
    bool elevated = false,
  }) {
    final cardColor = Theme.of(context).cardTheme.color ?? Colors.white;

    return Tooltip(
      // WRAP WITH TOOLTIP
      message: tooltip,
      waitDuration:
          const Duration(milliseconds: 500), // Optional: delay before showing
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: cardColor,
            shape: shape is CircleBorder ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: shape is RoundedRectangleBorder
                ? (shape.borderRadius as BorderRadius?)
                : shape == null
                    ? BorderRadius.circular(8)
                    : null,
            boxShadow: elevated
                ? [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: shape is CircleBorder
                ? BorderRadius.circular(buttonSize / 2)
                : shape is RoundedRectangleBorder
                    ? (shape.borderRadius as BorderRadius?)
                    : BorderRadius.circular(8),
            child: Icon(
              icon,
              size: iconSize,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
