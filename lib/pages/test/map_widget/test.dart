import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPreview extends StatelessWidget {
  final List<LatLng> polygonPoints;

  const MapPreview({super.key, required this.polygonPoints});

  // Calculate the centroid (center) of the polygon
  LatLng getPolygonCenter() {
    double sumLat = 0, sumLng = 0;
    for (var point in polygonPoints) {
      sumLat += point.latitude;
      sumLng += point.longitude;
    }
    return LatLng(sumLat / polygonPoints.length, sumLng / polygonPoints.length);
  }

  @override
  Widget build(BuildContext context) {
    final polygonCenter = getPolygonCenter();

    return SizedBox(
      width: 150, // Adjust preview size
      height: 150,
      child: FlutterMap(
        options: MapOptions(
          center: polygonCenter, // Center the map on the polygon
          zoom: 15, // Adjust zoom level as needed
          interactiveFlags: InteractiveFlag.none, // Makes it static
        ),
        children: [
          // Tile Layer (Map background)
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          // Polygon Layer (Fully shaded polygon)
          PolygonLayer(
            polygons: [
              Polygon(
                points: polygonPoints,
                color: Colors.blue, // Fully filled color (No transparency)
                borderColor: Colors.blue.shade900, // Darker border
                borderStrokeWidth: 2,
                isFilled: true, // Ensures full fill
              ),
            ],
          ),
        ],
      ),
    );
  }
}
