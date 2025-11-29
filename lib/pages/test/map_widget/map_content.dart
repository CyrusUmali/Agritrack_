// File: map_content.dart - Updated to pass zoom level to icon layers
 
import 'package:flareline/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flareline/services/lanugage_extension.dart';
import 'package:provider/provider.dart';
import 'map_layers.dart';
import 'polygon_manager.dart';
import 'dart:async';
import 'package:turf/turf.dart' as turf;




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
    Key? key,
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
  }) : super(key: key);

  @override
  State<MapContent> createState() => _MapContentState();
}

class _MapContentState extends State<MapContent> {
  double _currentZoom = 15.0;
  Timer? _zoomDebounce;

  // Layer caching
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

  @override
  void initState() {
    super.initState();
    _currentZoom = widget.zoomLevel;
    
    widget.mapController.mapEventStream.listen((event) {
      if (event is MapEventWithMove || event is MapEventRotate) {
        _zoomDebounce?.cancel();
        _zoomDebounce = Timer(const Duration(milliseconds: 150), () {
          final newZoom = widget.mapController.camera.zoom;
          if ((newZoom - _currentZoom).abs() > 0.5) {
            if (mounted) {
              setState(() {
                _currentZoom = newZoom;
                // Invalidate marker caches on significant zoom change
                _cachedBarangayMarkers = null;
                _cachedLakeMarkers = null;
                _lastMarkerZoom = null;
              });
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _zoomDebounce?.cancel();
    _cachedTileLayer = null;
    _cachedBarangayLayer = null;
    _cachedLakeLayer = null;
    _cachedBarangayMarkers = null;
    _cachedLakeMarkers = null;
    super.dispose();
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
  
  if (_cachedUserFilteredPolygons != null && _lastUserFilterHash == currentHash) {
    return _cachedUserFilteredPolygons!;
  }

  final userProvider = Provider.of<UserProvider>(context, listen: false);
  final isFarmer = userProvider.isFarmer;
  final farmerId = userProvider.farmer?.id?.toString();

  // If area filter is active (barangay or lake selected), skip user filtering
  if (widget.areaFilterActive) {
    _cachedUserFilteredPolygons = widget.polygonManager.polygons;
    _lastUserFilterHash = currentHash;
    return _cachedUserFilteredPolygons!;
  }

  // Otherwise, apply normal user filtering
  _cachedUserFilteredPolygons = widget.polygonManager.polygons.where((polygon) {
    if (isFarmer && widget.showOwnedFarmsOnly) {
      if (polygon.farmerId?.toString() != farmerId) return false;
    } else if (!isFarmer && widget.showActiveFarmsOnly) {
      if (polygon.status?.toLowerCase() != 'active' && polygon.status != null) {
        return false;
      }
    } else if (!isFarmer && !widget.showActiveFarmsOnly) {
      if (polygon.status?.toLowerCase() == 'active' || polygon.status == null) {
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

 

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.92,
      width: MediaQuery.of(context).size.width,
      child: ValueListenableBuilder<int>(
        valueListenable: widget.polygonManager.editorUpdateNotifier,
        builder: (context, updateCount, child) {
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          final isFarmer = userProvider.isFarmer;

          // Use cached user-filtered polygons
          final userFilteredPolygons = _getUserFilteredPolygons();

          final filteredPolygons = widget.polygonManager.getFilteredPolygons(
            widget.farmTypeFilters,
            showExceedingAreaOnly: widget.showExceedingAreaOnly,
            basePolygons: userFilteredPolygons,
          );

          final filteredPinStyles = filteredPolygons.map((p) => p.pinStyle).toList();
          final filteredColors = filteredPolygons.map((p) => p.color).toList();

          final filteredBarangays = widget.polygonManager.selectedBarangays.isNotEmpty
              ? widget.barangayManager.barangays
                  .where((barangay) =>
                      widget.polygonManager.selectedBarangays.contains(barangay.name))
                  .toList()
              : widget.barangayManager.barangays;

          final filteredLakes = widget.polygonManager.selectedLakes.isNotEmpty
              ? widget.lakeManager.lakes
                  .where((lake) =>
                      widget.polygonManager.selectedLakes.contains(lake.name))
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

              // CACHED: Lake center markers (only at zoom >= 13)
              if (widget.showAreaMarkers && _currentZoom >= 13)
                _buildCachedLakeMarkers(),

              // Polyline layer (dynamic, needs ValueListenableBuilder)
              ValueListenableBuilder<LatLng?>(
                valueListenable: widget.previewPointNotifier,
                builder: (context, previewPoint, child) {
                  return MapLayersHelper.createPolylineLayer(
                    filteredPolygons.map((polygon) => polygon.vertices).toList(),
                    widget.polygonManager.currentPolygon,
                    previewPoint,
                    widget.polygonManager.isDrawing,
                  );
                },
              ),

              // CACHED: Barangay polygons layer
              _buildCachedBarangayLayer(filteredBarangays),

              // CACHED: Barangay center markers (only at zoom >= 13)
              if (widget.showAreaMarkers && _currentZoom >= 13)
                _buildCachedBarangayMarkers(),

              // Polygon layer (dynamic, rebuilds with filteredPolygons)
              MapLayersHelper.createPolygonLayer(
                filteredPolygons.map((polygon) => polygon.vertices).toList(),
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
                filteredPolygons.map((polygon) => polygon.vertices).toList(),
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
                  if (i == 0 && widget.polygonManager.currentPolygon.length > 2) {
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
                  valueListenable: widget.polygonManager.editorUpdateNotifier,
                  builder: (context, updateCount, child) {
                    return DragMarkers(
                      markers: widget.polygonManager.polyEditor?.edit() ?? [],
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
    );
  }

  // ========== CACHED LAYER BUILDERS ==========

  Widget _buildCachedTileLayer() { 
    if (_cachedTileLayer == null || _lastSelectedMap != widget.selectedMap) {
 
      _lastSelectedMap = widget.selectedMap;
      _cachedTileLayer = TileLayer(
        tileProvider: CancellableNetworkTileProvider(),
        urlTemplate: MapLayersHelper.availableLayers[widget.selectedMap]!,
        maxNativeZoom: 18,
        keepBuffer: 2,
      );
    }
    return _cachedTileLayer!;
  }

  Widget _buildCachedBarangayLayer(List<PolygonData> filteredBarangays) {
     
    if (widget.polygonManager.selectedBarangays.isEmpty) {
      _cachedBarangayLayer = null;
      return const SizedBox.shrink();
    }

    final currentSelection = widget.polygonManager.selectedBarangays;
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

  Widget _buildCachedLakeLayer(List<PolygonData> filteredLakes) {
    if (widget.polygonManager.selectedLakes.isEmpty) {
      _cachedLakeLayer = null;
      return const SizedBox.shrink();
    }

    final currentSelection = widget.polygonManager.selectedLakes;
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

  Widget _buildCachedBarangayMarkers() {

    
    // Only rebuild on selection change or significant zoom change
    final currentSelection = widget.polygonManager.selectedBarangays;
    final zoomChanged = _lastMarkerZoom == null || 
                        (_currentZoom - _lastMarkerZoom!).abs() > 0.5;
    
    if (_cachedBarangayMarkers == null ||
        !_listEquals(_lastSelectedBarangays, currentSelection) ||
        zoomChanged) {
      _lastMarkerZoom = _currentZoom;
      _cachedBarangayMarkers = MapLayersHelper.createBarangayCenterFallbackLayer(
        widget.barangayManager.barangays,
        _handleBarangayMarkerTap,
        circleColor: const Color.fromARGB(255, 74, 72, 72),
        iconColor: Colors.white,
        size: 30.0,
        filteredBarangays: currentSelection,
        currentZoom: _currentZoom,
      );
    }
    return _cachedBarangayMarkers!;
  }

  Widget _buildCachedLakeMarkers() {
 
    final currentSelection = widget.polygonManager.selectedLakes;
    final zoomChanged = _lastMarkerZoom == null || 
                        (_currentZoom - _lastMarkerZoom!).abs() > 0.5;
    
    if (_cachedLakeMarkers == null ||
        !_listEquals(_lastSelectedLakes, currentSelection) ||
        zoomChanged) {
      _lastMarkerZoom = _currentZoom;
      _cachedLakeMarkers = MapLayersHelper.createLakeCenterFallbackLayer(
        widget.lakeManager.lakes,
        _handleLakeMarkerTap,
        circleColor: const Color.fromARGB(255, 59, 107, 145),
        iconColor: Colors.white,
        size: 30.0,
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
                  context.translate("Click the first point to close shape and save it"),
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

  Widget _buildLiveMeasurementOverlay() {
    return ValueListenableBuilder<LatLng?>(
      valueListenable: widget.previewPointNotifier,
      builder: (context, previewPoint, child) {
        if (!widget.polygonManager.isDrawing ||
            widget.polygonManager.currentPolygon.isEmpty) {
          return const SizedBox.shrink();
        }

        return _ThrottledMeasurementOverlay(
          currentPolygon: widget.polygonManager.currentPolygon,
          previewPoint: previewPoint,
        );
      },
    );
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

  widget.polygonManager.showBarangayInfo(
      context, barangay, widget.polygonManager.polygons);

  if (widget.onBarangayFilterChanged != null) {
    final isDeselecting = widget.polygonManager.selectedBarangays.contains(barangay.name);
    
    widget.setState(() {
      if (isDeselecting) {
        widget.onBarangayFilterChanged!([]);
      } else {
        widget.onBarangayFilterChanged!([barangay.name]);
      }
      
      // Update area filter state via callback
      widget.onAreaFilterChanged(!isDeselecting);
      
      // Invalidate cache to force rebuild
      _cachedUserFilteredPolygons = null;
      _lastUserFilterHash = null;
    });
  }
}

// Update _handleLakeMarkerTap:
void _handleLakeMarkerTap(PolygonData lake) {
  widget.animatedMapController.animatedFitCamera(
    cameraFit: CameraFit.coordinates(
      coordinates: lake.vertices,
      padding: const EdgeInsets.all(30),
    ),
    curve: Curves.easeInOut,
  );

  widget.polygonManager.showLakenInfo(
      context, lake, widget.polygonManager.polygons);

  if (widget.onLakeFilterChanged != null) {
    final isDeselecting = widget.polygonManager.selectedLakes.contains(lake.name);
    
    widget.setState(() {
      if (isDeselecting) {
        widget.onLakeFilterChanged!([]);
      } else {
        widget.onLakeFilterChanged!([lake.name]);
      }
      
      // Update area filter state via callback
      widget.onAreaFilterChanged(!isDeselecting);
      
      // Invalidate cache to force rebuild
      _cachedUserFilteredPolygons = null;
      _lastUserFilterHash = null;
    });
  }
}





  MapOptions _buildMapOptions(BuildContext context) {
    return MapOptions(
      center: const LatLng(14.077557, 121.328938),
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



 // Throttled measurement overlay widget
class _ThrottledMeasurementOverlay extends StatefulWidget {
  final List<LatLng> currentPolygon;
  final LatLng? previewPoint;

  const _ThrottledMeasurementOverlay({
    required this.currentPolygon,
    required this.previewPoint,
  });

  @override
  State<_ThrottledMeasurementOverlay> createState() => _ThrottledMeasurementOverlayState();
}

class _ThrottledMeasurementOverlayState extends State<_ThrottledMeasurementOverlay> {
  // Cached values
  double _cachedArea = 0.0;
  double _cachedPerimeter = 0.0;
  double _cachedDistance = 0.0; // NEW: Distance for 1-2 points
  int _cachedPointCount = 0;
  
  // Throttling
  Timer? _throttleTimer;
  bool _isThrottled = false;

  @override
  void initState() {
    super.initState();
    _updateMeasurements();
  }

  @override
  void didUpdateWidget(_ThrottledMeasurementOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Only update if points changed or preview moved significantly
    final pointsChanged = oldWidget.currentPolygon.length != widget.currentPolygon.length;
    final previewChanged = _hasPreviewMoved(oldWidget.previewPoint, widget.previewPoint);
    
    if (pointsChanged || previewChanged) {
      _throttledUpdate();
    }
  }

  bool _hasPreviewMoved(LatLng? oldPoint, LatLng? newPoint) {
    if (oldPoint == null && newPoint == null) return false;
    if (oldPoint == null || newPoint == null) return true;
    
    // Only update if moved more than ~5 meters
    final distance = const Distance().distance(oldPoint, newPoint);
    return distance > 5;
  }

  void _throttledUpdate() {
    if (_isThrottled) return;
    
    _updateMeasurements();
    _isThrottled = true;
    
    _throttleTimer?.cancel();
    _throttleTimer = Timer(const Duration(milliseconds: 100), () {
      _isThrottled = false;
    });
  }

  void _updateMeasurements() {
    if (!mounted) return;

    final pointCount = widget.currentPolygon.length;
    
    // Create measurement points including preview
    List<LatLng> measurePoints = List.from(widget.currentPolygon);
    if (widget.previewPoint != null) {
      measurePoints.add(widget.previewPoint!);
    }

    setState(() {
      _cachedPointCount = pointCount;

      if (measurePoints.length >= 3) {
        // 3+ points: Show area and perimeter
        _cachedArea = _calculateArea(measurePoints);
        _cachedPerimeter = _calculatePerimeter(measurePoints);
        _cachedDistance = 0.0;
      } else if (measurePoints.length == 2) {
        // 2 points: Show distance
        _cachedDistance = const Distance().distance(
          measurePoints[0],
          measurePoints[1],
        );
        _cachedArea = 0.0;
        _cachedPerimeter = 0.0;
      } else {
        // 1 point: Just show point count
        _cachedDistance = 0.0;
        _cachedArea = 0.0;
        _cachedPerimeter = 0.0;
      }
    });
  }

  double _calculateArea(List<LatLng> vertices) {
    if (vertices.length < 3) return 0.0;

    final coordinates = [
      vertices.map((p) => turf.Position(p.longitude, p.latitude)).toList()
    ];

    final geoJsonPolygon = turf.Polygon(coordinates: coordinates);
    final areaInSqMeters = turf.area(geoJsonPolygon);
    final areaInHectares = areaInSqMeters! / 10000;

    return double.parse(areaInHectares.toStringAsFixed(3));
  }

  double _calculatePerimeter(List<LatLng> points) {
    double perimeter = 0.0;
    for (int i = 0; i < points.length; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % points.length];
      perimeter += const Distance().distance(p1, p2);
    }
    return perimeter;
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📐 Live Measurement',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildMeasurementRow(
                icon: '📍',
                label: 'Points',
                value: '$_cachedPointCount',
              ),
              
              // Show distance for 2 points
              if (_cachedPointCount >= 1 && _cachedDistance > 0) ...[
                const SizedBox(height: 4),
                _buildMeasurementRow(
                  icon: '📏',
                  label: 'Distance',
                  value: '${(_cachedDistance / 1000).toStringAsFixed(3)} km',
                  highlight: true,
                ),
              ],
              
              // Show area and perimeter for 3+ points
              if (_cachedPointCount >= 2 && _cachedArea > 0) ...[
                const SizedBox(height: 4),
                _buildMeasurementRow(
                  icon: '📐',
                  label: 'Area',
                  value: '${_cachedArea.toStringAsFixed(3)} ha',
                  highlight: true,
                ),
                const SizedBox(height: 4),
                _buildMeasurementRow(
                  icon: '⭕',
                  label: 'Perimeter',
                  value: '${(_cachedPerimeter / 1000).toStringAsFixed(3)} km',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeasurementRow({
    required String icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: highlight ? Colors.greenAccent : Colors.white,
            fontSize: 13,
            fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _throttleTimer?.cancel();
    super.dispose();
  }
}