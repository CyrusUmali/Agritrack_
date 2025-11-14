// File: map_content.dart - Updated to pass zoom level to icon layers

import 'package:flareline/pages/test/map_widget/farm_list_panel/barangay_filter_panel.dart';
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
  }) : super(key: key);

  @override
  State<MapContent> createState() => _MapContentState();
}

class _MapContentState extends State<MapContent> {
  double _currentZoom = 15.0;

  @override
  void initState() {
    super.initState();
    _currentZoom = widget.zoomLevel;
    
widget.mapController.mapEventStream.listen((event) {
  if (event is MapEventWithMove || event is MapEventRotate) {
    final newZoom = widget.mapController.camera.zoom;
    if ((newZoom - _currentZoom).abs() > 0.1) {
      setState(() {
        _currentZoom = newZoom;
      });
    }
  }
});



  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.92,
      width: MediaQuery.of(context).size.width,
      child: ValueListenableBuilder<int>(
        valueListenable: widget.polygonManager.editorUpdateNotifier,
        builder: (context, updateCount, child) {
          final userProvider =
              Provider.of<UserProvider>(context, listen: false);
          final isFarmer = userProvider.isFarmer;
          final farmerId = userProvider.farmer?.id?.toString();

          List<PolygonData> userFilteredPolygons =
              widget.polygonManager.polygons.where((polygon) {
            if (isFarmer &&
                BarangayFilterPanel.userFilterOptions['showOwnedOnly'] ==
                    true) {
              if (polygon.farmerId?.toString() != farmerId) {
                return false;
              }
            } else if (!isFarmer &&
                BarangayFilterPanel.userFilterOptions['showActiveOnly'] ==
                    true) {
              if (polygon.status?.toLowerCase() != 'active' &&
                  polygon.status != null) {
                return false;
              }
            }
            return true;
          }).toList();

          final filteredPolygons = widget.polygonManager.getFilteredPolygons(
            widget.farmTypeFilters,
            showExceedingAreaOnly: widget.showExceedingAreaOnly,
            basePolygons: userFilteredPolygons,
          );

          final filteredPinStyles =
              filteredPolygons.map((p) => p.pinStyle).toList();
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

          final _isFarmer = userProvider.isFarmer;

          return FlutterMap(
            mapController: widget.mapController,
            options: _buildMapOptions(context),
            children: [
              // Base tile layer
              TileLayer(
                tileProvider: CancellableNetworkTileProvider(),
                urlTemplate: MapLayersHelper.availableLayers[widget.selectedMap]!,
              ),

              // Lake polygons layer
              if (widget.polygonManager.selectedLakes.isNotEmpty)
                MapLayersHelper.createLakeLayer(widget.lakeManager.lakes
                    .where((lake) =>
                        widget.polygonManager.selectedLakes.contains(lake.name))
                    .toList()),

              // Lake center markers layer - NOW WITH ZOOM PARAMETER
              if (widget.showAreaMarkers)
                MapLayersHelper.createLakeCenterFallbackLayer(
                  widget.lakeManager.lakes,
                  (lake) {
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
                      widget.setState(() {
                        if (widget.polygonManager.selectedLakes.contains(lake.name)) {
                          widget.onLakeFilterChanged!([]);
                        } else {
                          widget.onLakeFilterChanged!([lake.name]);
                        }
                      });
                    }
                  },
                  circleColor: const Color.fromARGB(255, 59, 107, 145),
                  iconColor: Colors.white,
                  size: 30.0,
                  filteredLakes: widget.polygonManager.selectedLakes,
                  currentZoom: _currentZoom, // PASS CURRENT ZOOM
                ),

              // Polyline layer
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

              // Barangay polygons layer
              if (widget.polygonManager.selectedBarangays.isNotEmpty)
                MapLayersHelper.createBarangayLayer(widget.barangayManager.barangays
                    .where((barangay) => widget.polygonManager.selectedBarangays
                        .contains(barangay.name))
                    .toList()),

              // Barangay center markers layer - NOW WITH ZOOM PARAMETER
              if (widget.showAreaMarkers)
                MapLayersHelper.createBarangayCenterFallbackLayer(
                  widget.barangayManager.barangays,
                  (barangay) {
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
                      widget.setState(() {
                        if (widget.polygonManager.selectedBarangays
                            .contains(barangay.name)) {
                          widget.onBarangayFilterChanged!([]);
                        } else {
                          widget.onBarangayFilterChanged!([barangay.name]);
                        }
                      });
                    }
                  },
                  circleColor: const Color.fromARGB(255, 74, 72, 72),
                  iconColor: Colors.white,
                  size: 30.0,
                  filteredBarangays: widget.polygonManager.selectedBarangays,
                  currentZoom: _currentZoom, // PASS CURRENT ZOOM
                ),

              // Polygon layer
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
                _isFarmer,
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
              ValueListenableBuilder<LatLng?>(
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
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  MapOptions _buildMapOptions(BuildContext context) {
    return MapOptions(
      center: LatLng(14.077557, 121.328938),
      zoom: widget.zoomLevel,
      minZoom: 12,
      maxBounds: LatLngBounds(
        LatLng(13.877557, 121.128938),
        LatLng(14.277557, 121.528938),
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