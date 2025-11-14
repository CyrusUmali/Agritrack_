// File: map_layers.dart - Enhanced version with zoom-based dynamic icons

import 'polygon_manager.dart';
import 'package:flareline/pages/test/map_widget/pin_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';

class MapLayersHelper {
  // Define maximum area limits for each pin style in HECTARES
  static final Map<PinStyle, double> maxAreaLimitsHectares = {
    PinStyle.Fishery: 5,
    PinStyle.Rice: 5,
    PinStyle.HVC: 5,
    PinStyle.Organic: 5,
    PinStyle.Corn: 5,
    PinStyle.Livestock: 5,
  };

  /// Calculate dynamic icon size based on zoom level
  static double getIconSizeForZoom(double zoom) {
    // print('Current Zoom: $zoom');
    if (zoom < 13) return 20.0;
    if (zoom < 14) return 25.0;
    if (zoom < 15) return 30.0;
    if (zoom < 16) return 30.0;
    if (zoom < 17) return 36.0;
    return 48.0;
  }

  /// Calculate dynamic icon opacity based on zoom level
  static double getIconOpacityForZoom(double zoom) {
    if (zoom < 12.5) return 0.3;
    if (zoom < 13) return 0.5;
    if (zoom < 14) return 0.7;
    if (zoom < 15) return 0.85;
    return 1.0;
  }

  /// Determine if labels should be shown based on zoom
  static bool shouldShowLabelsForZoom(double zoom) {
    return zoom >= 15.5;
  }

  /// Get icon detail level based on zoom
  static IconDetailLevel getIconDetailForZoom(double zoom) {

    // print(zoom);

    // print('zoom');
    if (zoom < 13) return IconDetailLevel.minimal;
    if (zoom < 15) return IconDetailLevel.detailed;
    return IconDetailLevel.detailed;
  }

  static PolygonLayer createBarangayLayer(List<PolygonData> barangays) {
    return PolygonLayer(
      polygons: barangays
          .map((barangay) => Polygon(
                points: barangay.vertices,
                color: const Color.fromARGB(255, 255, 255, 0).withOpacity(0.1),
                borderStrokeWidth: 1,
                borderColor: const Color.fromARGB(255, 223, 212, 1),
                isFilled: true,
              ))
          .toList(),
    );
  }

  static PolygonLayer createLakeLayer(List<PolygonData> lakes) {
    return PolygonLayer(
      polygons: lakes
          .map((lake) => Polygon(
                points: lake.vertices,
                color: const Color.fromARGB(255, 255, 255, 0).withOpacity(0.1),
                borderStrokeWidth: 1,
                borderColor: const Color.fromARGB(255, 223, 212, 1),
                isFilled: true,
              ))
          .toList(),
    );
  }

  static PolygonLayer createPolygonLayer(
      List<List<LatLng>> polygons,
      List<LatLng> currentPolygon,
      List<Color>? polygonColors,
      {Color defaultColor = Colors.blue,
      int? selectedPolygonIndex}) {
    return PolygonLayer(
      polygons: [
        for (int i = 0; i < polygons.length; i++)
          Polygon(
            points: polygons[i],
            color: (i == selectedPolygonIndex)
                ? Colors.red.withOpacity(0.3)
                : (polygonColors != null && i < polygonColors.length)
                    ? polygonColors[i].withOpacity(0.2)
                    : defaultColor.withOpacity(0.2),
            borderStrokeWidth: 3,
            borderColor: (i == selectedPolygonIndex)
                ? Colors.red
                : (polygonColors != null && i < polygonColors.length)
                    ? polygonColors[i]
                    : defaultColor,
            isFilled: true,
          ),
        if (currentPolygon.isNotEmpty)
          Polygon(
            points: currentPolygon,
            color: Colors.red.withOpacity(0.5),
            borderStrokeWidth: 3,
            borderColor: Colors.red,
            isFilled: true,
          ),
      ],
    );
  }

  /// Creates a zoom-responsive layer for barangay centers
  static MarkerLayer createBarangayCenterFallbackLayer(
    List<PolygonData> barangays,
    Function(PolygonData) onTap, {
    Color circleColor = Colors.blue,
    Color iconColor = Colors.white,
    double size = 36.0,
    List<String>? filteredBarangays,
    required double currentZoom, // NEW: Required zoom level parameter
  }) {
    final iconSize = getIconSizeForZoom(currentZoom);
    final opacity = getIconOpacityForZoom(currentZoom);
    final showLabels = shouldShowLabelsForZoom(currentZoom);
    final detailLevel = getIconDetailForZoom(currentZoom);

    return MarkerLayer(
      markers: barangays.map((barangay) {
        final isFiltered = filteredBarangays != null &&
            filteredBarangays.contains(barangay.name);
        
        return Marker(
          point: MapLayersHelper.calculateCenter(barangay.vertices),
          width: iconSize + (showLabels ? 60 : 0),
          height: iconSize + (showLabels ? 30 : 0),
          child: GestureDetector(
            onTap: () => onTap(barangay),
            child: Opacity(
              opacity: opacity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: isFiltered ? Colors.green : circleColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: detailLevel == IconDetailLevel.detailed ? 2.5 : 1.5,
                      ),
                      boxShadow: detailLevel != IconDetailLevel.minimal
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: detailLevel == IconDetailLevel.detailed
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.account_balance,
                                  color: isFiltered ? Colors.white : iconColor,
                                  size: iconSize * 0.45,
                                ),
                                Text(
                                  'Brgy',
                                  style: TextStyle(
                                    color: isFiltered ? Colors.white : iconColor,
                                    fontSize: iconSize * 0.18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : Icon(
                              Icons.account_balance,
                              color: isFiltered ? Colors.white : iconColor,
                              size: iconSize * 0.6,
                            ),
                    ),
                  ),
                  if (showLabels)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        barangay.name ?? 'Unknown',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: currentZoom >= 16 ? 11 : 9,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Creates a zoom-responsive layer for lake centers
  static MarkerLayer createLakeCenterFallbackLayer(
    List<PolygonData> lakes,
    Function(PolygonData) onTap, {
    Color circleColor = Colors.blue,
    Color iconColor = Colors.white,
    double size = 36.0,
    List<String>? filteredLakes,
    required double currentZoom, // NEW: Required zoom level parameter
  }) {
    final iconSize = getIconSizeForZoom(currentZoom);
    final opacity = getIconOpacityForZoom(currentZoom);
    final showLabels = shouldShowLabelsForZoom(currentZoom);
    final detailLevel = getIconDetailForZoom(currentZoom);

    return MarkerLayer(
      markers: lakes.map((lake) {
        final isFiltered =
            filteredLakes != null && filteredLakes.contains(lake.name);
        
        return Marker(
          point: MapLayersHelper.calculateCenter(lake.vertices),
          width: iconSize + (showLabels ? 60 : 0),
          height: iconSize + (showLabels ? 30 : 0),
          child: GestureDetector(
            onTap: () => onTap(lake),
            child: Opacity(
              opacity: opacity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: isFiltered ? Colors.green : circleColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: detailLevel == IconDetailLevel.detailed ? 2.5 : 1.5,
                      ),
                      boxShadow: detailLevel != IconDetailLevel.minimal
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.water_drop_outlined,
                        color: isFiltered ? Colors.white : iconColor,
                        size: iconSize * 0.6,
                      ),
                    ),
                  ),
                  if (showLabels)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        lake.name ?? 'Unknown',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: currentZoom >= 16 ? 11 : 9,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  static PolylineLayer createPolylineLayer(List<List<LatLng>> polygons,
      List<LatLng> currentPolygon, LatLng? previewPoint, bool isDrawing) {
    return PolylineLayer(
      polylines: [
        for (var poly in polygons)
          Polyline(
            points: poly,
            color: Colors.blue,
            strokeWidth: 3,
            isDotted: true,
          ),
        if (isDrawing && currentPolygon.isNotEmpty && previewPoint != null)
          Polyline(
            points: [currentPolygon.last, previewPoint],
            color: Colors.red,
            strokeWidth: 2,
            isDotted: true,
          ),
      ],
    );
  }

  static MarkerLayer createMarkerLayer(
    List<List<LatLng>> polygons,
    List<LatLng> currentPolygon,
    int? selectedPolygonIndex,
    bool isEditing,
    Function(int, int) onMarkerTap,
    Function(int) onCurrentPolygonMarkerTap,
    List<PinStyle> pinStyles,
    PolygonManager polygonManager,
    BuildContext context,
    bool isFarmer,
  ) {
    return MarkerLayer(
      markers: [
        for (int i = 0; i < currentPolygon.length; i++)
          Marker(
            point: currentPolygon[i],
            width: 36.0,
            height: 36.0,
            child: GestureDetector(
              onTap: () {
                onCurrentPolygonMarkerTap(i);
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == 0 ? Colors.red : Colors.green,
                  border: Border.all(color: Colors.white, width: 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),

        for (int i = 0; i < polygons.length; i++)
          Marker(
            point: calculateCenter(polygons[i]),
            width: 30.0,
            height: 30.0,
            child: GestureDetector(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: getPinColor(pinStyles[i]).withOpacity(
                      polygonManager.selectedPolygonIndex == i ? 0.8 : 0.6),
                  border: Border.all(
                    color: Colors.white,
                    width: polygonManager.selectedPolygonIndex == i ? 3.0 : 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: _getExceedanceIcon(polygonManager.polygons[i],
                      pinStyles[i], isFarmer),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static Widget _getExceedanceIcon(
      PolygonData polygon, PinStyle pinStyle, bool isFarmer) {
    final maxArea = maxAreaLimitsHectares[pinStyle] ?? double.infinity;
    final exceedsLimit = polygon.area != null && polygon.area! > maxArea;

    if (exceedsLimit) {
      return Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          getPinIcon(pinStyle),
          Positioned(
            top: -8,
            right: -8,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.square_foot,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return getPinIcon(pinStyle);
    }
  }

  static LatLng calculateCenter(List<LatLng> vertices) {
    if (vertices.isEmpty) return const LatLng(0, 0);

    double latSum = 0, lngSum = 0;
    for (var vertex in vertices) {
      latSum += vertex.latitude;
      lngSum += vertex.longitude;
    }
    return LatLng(latSum / vertices.length, lngSum / vertices.length);
  }

  static DragMarkers createDragMarkerLayer(
      List<List<LatLng>> polygons,
      int selectedPolygonIndex,
      Function(int) onVertexRemove,
      Function(int, LatLng) onVertexDrag,
      Function(int, LatLng) onMidpointDrag) {
    return DragMarkers(
      markers: [
        for (int j = 0; j < polygons[selectedPolygonIndex].length; j++)
          DragMarker(
            point: polygons[selectedPolygonIndex][j],
            size: const Size(20, 20),
            builder: (context, point, isDragging) {
              return GestureDetector(
                onTap: () {
                  onVertexRemove(j);
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              );
            },
            onDragUpdate: (details, newPoint) {
              onVertexDrag(j, newPoint);
            },
          ),

        for (int j = 0; j < polygons[selectedPolygonIndex].length; j++)
          DragMarker(
            point: LatLng(
              (polygons[selectedPolygonIndex][j].latitude +
                      polygons[selectedPolygonIndex]
                              [(j + 1) % polygons[selectedPolygonIndex].length]
                          .latitude) /
                  2,
              (polygons[selectedPolygonIndex][j].longitude +
                      polygons[selectedPolygonIndex]
                              [(j + 1) % polygons[selectedPolygonIndex].length]
                          .longitude) /
                  2,
            ),
            size: const Size(20, 20),
            builder: (context, point, isDragging) {
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange.withOpacity(0.5),
                  border: Border.all(color: Colors.white, width: 2),
                ),
              );
            },
            onDragUpdate: (details, newPoint) {
              onMidpointDrag(j, newPoint);
            },
          ),
      ],
    );
  }

  static final Map<String, String> availableLayers = {
    "OSM": "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
    "Google Satellite": "https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}",
    "Google Satellite (No Labels)":
        "https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}",
    "ESRI World Imagery":
        "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}",
    "Wikimedia": "https://maps.wikimedia.org/osm-intl/{z}/{x}/{y}.png",
    "CartoDB Light":
        "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png",
    "OpenTopoMap": "https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png",
    "CyclOSM":
        "https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png",
    "Humanitarian": "https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png",
  };
}

/// Enum for icon detail levels based on zoom
enum IconDetailLevel {
  minimal,  // Just icon, small size
  medium,   // Icon with slight detail
  detailed, // Full icon with labels and effects
}