import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart'; // Add this import
import 'package:latlong2/latlong.dart';

class FarmMapCard extends StatefulWidget {
  final Map<String, dynamic> farm;
  final bool isMobile;

  const FarmMapCard({
    super.key,
    required this.farm,
    this.isMobile = false,
  });

  @override
  State<FarmMapCard> createState() => _FarmMapCardState();
}

class _FarmMapCardState extends State<FarmMapCard> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  double _calculateZoomLevel(double hectare) {
   
    if (hectare < 0.5) return 20.0;
    if (hectare < 0.6) return 19.0;
    if (hectare < 5) return 18.0;
    if (hectare < 20) return 16.0;
    if (hectare < 50) return 14.0;
    return 10.0;
  }

  Color _getColorForSector(String sector) {
    switch (sector) {
      case 'Rice':
        return Colors.green;
      case 'Corn':
        return Colors.yellow;
      case 'HVC':
        return Colors.purple;
      case 'Livestock':
        return Colors.deepOrange;
      case 'Fishery':
        return Colors.blue;
      case 'Organic':
        return Colors.grey;
      default:
        return Colors.blue; // Default color
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract vertices from farm data
    final List<dynamic> verticesData = widget.farm['vertices'] ?? [];
    final List<LatLng> polygonPoints = verticesData.map((vertex) {
      if (vertex is Map) {
        return LatLng(vertex['latitude'], vertex['longitude']);
      } else if (vertex is LatLng) {
        return vertex;
      }
      return LatLng(0, 0);
    }).toList();

    // If no valid vertices, show placeholder
    if (polygonPoints.isEmpty ||
        polygonPoints
            .every((point) => point.latitude == 0 && point.longitude == 0)) {
      return Card(
        elevation: 1,
        child: SizedBox(
          height: widget.isMobile ? 200 : 150,
          child: const Center(child: Text('No location data available')),
        ),
      );
    }

    // Calculate center point
    double centerLat = 0;
    double centerLng = 0;
    for (var point in polygonPoints) {
      centerLat += point.latitude;
      centerLng += point.longitude;
    }
    centerLat /= polygonPoints.length;
    centerLng /= polygonPoints.length;

    // Get hectare value
    final double hectare = widget.farm['hectare']?.toDouble() ?? 0.0;
    final double zoomLevel = _calculateZoomLevel(hectare);

    // Get sector and corresponding color
    final String sector = widget.farm['sector']?.toString() ?? '';
    final Color sectorColor = _getColorForSector(sector);

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: widget.isMobile ? 200 : 200,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: LatLng(centerLat, centerLng),
            zoom: zoomLevel,
            minZoom: 18,
            onMapReady: () {
              // Calculate bounds after map is ready
              final bounds = LatLngBounds.fromPoints(polygonPoints);
              _mapController.fitBounds(
                bounds,
                options: FitBoundsOptions(
                  padding: EdgeInsets.all(20),
                ),
              );
            },
          ),
          children: [
            TileLayer(
              tileProvider:
                  CancellableNetworkTileProvider(), // Use cancellable provider
              urlTemplate: "https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}",
              userAgentPackageName: 'com.example.app',
            ),
            PolygonLayer(
              polygons: [
                Polygon(
                  points: polygonPoints,
                  color: sectorColor.withOpacity(0.3),
                  borderColor: sectorColor,
                  borderStrokeWidth: 2,
                  isFilled: true,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  width: 40.0,
                  height: 40.0,
                  point: LatLng(centerLat, centerLng),
                  child: const Icon(
                    Icons.location_on,
                    color: Color.fromARGB(255, 8, 244, 141),
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
