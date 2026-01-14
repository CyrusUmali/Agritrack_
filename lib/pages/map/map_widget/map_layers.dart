// File: map_layers.dart - Enhanced version with zoom-based dynamic icons

import 'polygon_manager.dart';
import 'package:flareline/pages/map/map_widget/pin_style.dart';
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

  // Fixed marker size (same as farm icons)
  static const double fixedMarkerSize = 30.0;
  static const double fixedIconSize = 16.0;
  
  /// Determine if labels should be shown based on zoom (for second version)
  static bool shouldShowLabelsForZoom(double zoom) {
    return zoom >= 17;
  }

  // OPTION 1: Fixed size markers (same as farms) - HIGH PERFORMANCE
  static MarkerLayer createFixedBarangayMarkers(
    List<PolygonData> barangays,
    Function(PolygonData) onTap, {
    Color circleColor = const Color.fromARGB(255, 74, 72, 72),
    Color iconColor = Colors.white,
    List<String>? filteredBarangays,
  }) {
    return MarkerLayer(
      markers: barangays.map((barangay) {
        final isFiltered = filteredBarangays != null &&
            filteredBarangays.contains(barangay.name);
        
        return Marker(
          point: MapLayersHelper.calculateCenter(barangay.vertices),
          width: fixedMarkerSize,
          height: fixedMarkerSize,
          child: GestureDetector(
            onTap: () => onTap(barangay),
            child: Container(
              width: fixedMarkerSize,
              height: fixedMarkerSize,
              decoration: BoxDecoration(
                color: isFiltered ? Colors.green : circleColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.account_balance,
                color: iconColor,
                size: fixedIconSize,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // OPTION 1: Fixed size lake markers
  static MarkerLayer createFixedLakeMarkers(
    List<PolygonData> lakes,
    Function(PolygonData) onTap, {
    Color circleColor = const Color.fromARGB(255, 59, 107, 145),
    Color iconColor = Colors.white,
    List<String>? filteredLakes,
  }) {
    return MarkerLayer(
      markers: lakes.map((lake) {
        final isFiltered = filteredLakes != null &&
            filteredLakes.contains(lake.name);
        
        return Marker(
          point: MapLayersHelper.calculateCenter(lake.vertices),
          width: fixedMarkerSize,
          height: fixedMarkerSize,
          child: GestureDetector(
            onTap: () => onTap(lake),
            child: Container(
              width: fixedMarkerSize,
              height: fixedMarkerSize,
              decoration: BoxDecoration(
                color: isFiltered ? Colors.green : circleColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.water_drop_outlined,
                color: iconColor,
                size: fixedIconSize,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // OPTION 2: Fixed size with labels on zoom
  static MarkerLayer createBarangayMarkersWithLabels(
    List<PolygonData> barangays,
    Function(PolygonData) onTap, {
    required double currentZoom,
    Color circleColor = const Color.fromARGB(255, 74, 72, 72),
    Color iconColor = Colors.white,
    List<String>? filteredBarangays,
  }) {
    final showLabels = shouldShowLabelsForZoom(currentZoom);
    
    return MarkerLayer(
      markers: barangays.map((barangay) {
        final isFiltered = filteredBarangays != null &&
            filteredBarangays.contains(barangay.name);
        
        return Marker(
          point: MapLayersHelper.calculateCenter(barangay.vertices),
          width: fixedMarkerSize + (showLabels ? 60 : 0),
          height: fixedMarkerSize + (showLabels ? 30 : 0),
          child: GestureDetector(
            onTap: () => onTap(barangay),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: fixedMarkerSize,
                  height: fixedMarkerSize,
                  decoration: BoxDecoration(
                    color: isFiltered ? Colors.green : circleColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.account_balance,
                    color: iconColor,
                    size: fixedIconSize,
                  ),
                ),
                if (showLabels) _buildLabel(barangay.name, currentZoom),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // OPTION 2: Lake markers with labels on zoom
  static MarkerLayer createLakeMarkersWithLabels(
    List<PolygonData> lakes,
    Function(PolygonData) onTap, {
    required double currentZoom,
    Color circleColor = const Color.fromARGB(255, 59, 107, 145),
    Color iconColor = Colors.white,
    List<String>? filteredLakes,
  }) {
    final showLabels = shouldShowLabelsForZoom(currentZoom);
    
    return MarkerLayer(
      markers: lakes.map((lake) {
        final isFiltered = filteredLakes != null &&
            filteredLakes.contains(lake.name);
        
        return Marker(
          point: MapLayersHelper.calculateCenter(lake.vertices),
          width: fixedMarkerSize + (showLabels ? 60 : 0),
          height: fixedMarkerSize + (showLabels ? 30 : 0),
          child: GestureDetector(
            onTap: () => onTap(lake),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: fixedMarkerSize,
                  height: fixedMarkerSize,
                  decoration: BoxDecoration(
                    color: isFiltered ? Colors.green : circleColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.water_drop_outlined,
                    color: iconColor,
                    size: fixedIconSize,
                  ),
                ),
                if (showLabels) _buildLabel(lake.name, currentZoom),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  static Widget _buildLabel(String text, double currentZoom) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: currentZoom >= 16 ? 11 : 9,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }


static PolygonLayer createOptimizedBarangayLayer(
  List<PolygonData> barangays, {
  required double currentZoom,
}) {
  // Always render barangay polygons at any zoom level

     // Don't render at very low zoom
    // if (currentZoom < 12) {
    //   return PolygonLayer(polygons: const []);
    // }
  return PolygonLayer(
    polygons: barangays.map((barangay) {
      return Polygon(
        points: barangay.vertices, // Use original vertices, no simplification
        color: const Color.fromARGB(255, 255, 255, 0).withOpacity(
          // Adjust opacity for better visibility when zoomed out
          currentZoom < 13 ? 0.05 : 0.1
        ),
        borderStrokeWidth: currentZoom < 13 ? 0.5 : 1.0,
        borderColor: const Color.fromARGB(255, 223, 212, 1),
        isFilled: true,
      );
    }).toList(),
  );
}

static PolygonLayer createOptimizedLakeLayer(
  List<PolygonData> lakes, {
  required double currentZoom,
}) {

 // Don't render at very low zoom
    // if (currentZoom < 12) {
    //   return PolygonLayer(polygons: const []);
    // }

  return PolygonLayer(
    polygons: lakes.map((lake) {
      return Polygon(
        points: lake.vertices, // Use original vertices
        color: const Color.fromARGB(255, 59, 107, 145).withOpacity(
          currentZoom < 13 ? 0.1 : 0.15
        ),
        borderStrokeWidth: currentZoom < 13 ? 0.5 : 1.0,
        borderColor: const Color.fromARGB(255, 59, 107, 145),
        isFilled: true,
      );
    }).toList(),
  );
}

  static List<LatLng> _simplifyPolygon(List<LatLng> points, {required double tolerance}) {
    if (points.length <= 3) return points;

    double maxDistance = 0;
    int maxIndex = 0;
    final end = points.length - 1;

    for (int i = 1; i < end; i++) {
      final distance = _perpendicularDistance(
        points[i],
        points[0],
        points[end],
      );
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    if (maxDistance > tolerance) {
      final left = _simplifyPolygon(
        points.sublist(0, maxIndex + 1),
        tolerance: tolerance,
      );
      final right = _simplifyPolygon(
        points.sublist(maxIndex),
        tolerance: tolerance,
      );

      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      return [points[0], points[end]];
    }
  }

  static double _perpendicularDistance(LatLng point, LatLng lineStart, LatLng lineEnd) {
    final dx = lineEnd.longitude - lineStart.longitude;
    final dy = lineEnd.latitude - lineStart.latitude;

    final mag = (dx * dx + dy * dy);
    if (mag == 0) return 0;

    final u = ((point.longitude - lineStart.longitude) * dx +
            (point.latitude - lineStart.latitude) * dy) /
        mag;

    final closestPoint = LatLng(
      lineStart.latitude + u * dy,
      lineStart.longitude + u * dx,
    );

    return _distance(point, closestPoint);
  }

  static double _distance(LatLng p1, LatLng p2) {
    final dx = p1.longitude - p2.longitude;
    final dy = p1.latitude - p2.latitude;
    return (dx * dx + dy * dy);
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





/// Separate stateless widget for cached marker rendering
class _CachedBarangayMarker extends StatelessWidget {

  final double iconSize;
  final double opacity;
  final bool showLabels;
  final IconDetailLevel detailLevel;
  final PolygonData barangay;
  final bool isFiltered;
  final Color circleColor;
  final Color iconColor;
  final double currentZoom;

  const _CachedBarangayMarker({
    required this.iconSize,
    required this.opacity,
    required this.showLabels,
    required this.detailLevel,
    required this.barangay,
    required this.isFiltered,
    required this.circleColor,
    required this.iconColor,
    required this.currentZoom,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
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
                  : null, // CHANGED: null instead of empty list
            ),
            child: Center(
              child: detailLevel == IconDetailLevel.detailed
                  ? _buildDetailedIcon()
                  : _buildSimpleIcon(),
            ),
          ),
          if (showLabels) _buildLabel(),
        ],
      ),
    );
  }

  Widget _buildDetailedIcon() {
    return Column(
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
    );
  }

  Widget _buildSimpleIcon() {
    return Icon(
      Icons.account_balance,
      color: isFiltered ? Colors.white : iconColor,
      size: iconSize * 0.6,
    );
  }

  Widget _buildLabel() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        barangay.name,
        style: TextStyle(
          color: Colors.white,
          fontSize: currentZoom >= 16 ? 11 : 9,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is _CachedBarangayMarker &&
        other.iconSize == iconSize &&
        other.opacity == opacity &&
        other.showLabels == showLabels &&
        other.detailLevel == detailLevel &&
        other.barangay == barangay &&
        other.isFiltered == isFiltered &&
        other.circleColor == circleColor &&
        other.iconColor == iconColor;
  }

  @override
  int get hashCode {
    return Object.hash(
      iconSize,
      opacity,
      showLabels,
      detailLevel,
      barangay,
      isFiltered,
      circleColor,
      iconColor,
    );
  }
}













class _CachedLakeMarker extends StatelessWidget {
  final double iconSize;
  final double opacity;
  final bool showLabels;
  final IconDetailLevel detailLevel;
  final PolygonData lake;
  final bool isFiltered;
  final Color circleColor;
  final Color iconColor;
  final double currentZoom;

  const _CachedLakeMarker({
    required this.iconSize,
    required this.opacity,
    required this.showLabels,
    required this.detailLevel,
    required this.lake,
    required this.isFiltered,
    required this.circleColor,
    required this.iconColor,
    required this.currentZoom,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
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
                  : null,
            ),
            child: Center(
              child: Icon(
                Icons.water_drop_outlined,
                color: isFiltered ? Colors.white : iconColor,
                size: iconSize * 0.6,
              ),
            ),
          ),
          if (showLabels) _buildLabel(),
        ],
      ),
    );
  }

  Widget _buildLabel() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        lake.name,
        style: TextStyle(
          color: Colors.white,
          fontSize: currentZoom >= 16 ? 11 : 9,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is _CachedLakeMarker &&
        other.iconSize == iconSize &&
        other.opacity == opacity &&
        other.showLabels == showLabels &&
        other.detailLevel == detailLevel &&
        other.lake == lake &&
        other.isFiltered == isFiltered &&
        other.circleColor == circleColor &&
        other.iconColor == iconColor;
  }

  @override
  int get hashCode {
    return Object.hash( 
      iconSize,
      opacity,
      showLabels,
      detailLevel,
      lake,
      isFiltered,
      circleColor,
      iconColor,
    );
  }
}