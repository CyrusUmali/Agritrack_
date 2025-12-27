import 'package:flareline/pages/map/map_widget/polygon_manager.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ViewportHelper {
  /// Check if a point is within the current viewport with padding
  static bool isPointInViewport(
    LatLng point,
    LatLngBounds bounds, {
    double paddingDegrees = 0.01, // ~1km padding
  }) {
    return point.latitude >= bounds.south - paddingDegrees &&
        point.latitude <= bounds.north + paddingDegrees &&
        point.longitude >= bounds.west - paddingDegrees &&
        point.longitude <= bounds.east + paddingDegrees;
  }

  /// Check if a polygon intersects with viewport
  static bool isPolygonInViewport(
    List<LatLng> vertices,
    LatLngBounds bounds, {
    double paddingDegrees = 0.01, 
  }) {
    if (vertices.isEmpty) return false;

    // Quick check: is polygon center in viewport?
    final center = calculateCenter(vertices);
    if (isPointInViewport(center, bounds, paddingDegrees: paddingDegrees)) {
      return true;
    }

    // Thorough check: does any vertex fall in viewport?
    for (final vertex in vertices) {
      if (isPointInViewport(vertex, bounds, paddingDegrees: paddingDegrees)) {
        return true;
      }
    }

    // Final check: does viewport intersect polygon bounds?
    final polygonBounds = _getPolygonBounds(vertices);
    return _boundsIntersect(bounds, polygonBounds, paddingDegrees);
  }

  static LatLng calculateCenter(List<LatLng> vertices) {
    double latSum = 0, lngSum = 0;
    for (var vertex in vertices) {
      latSum += vertex.latitude;
      lngSum += vertex.longitude;
    }
    return LatLng(latSum / vertices.length, lngSum / vertices.length);
  }

  static LatLngBounds _getPolygonBounds(List<LatLng> vertices) {
    double minLat = vertices[0].latitude;
    double maxLat = vertices[0].latitude;
    double minLng = vertices[0].longitude;
    double maxLng = vertices[0].longitude;

    for (var vertex in vertices) {
      if (vertex.latitude < minLat) minLat = vertex.latitude;
      if (vertex.latitude > maxLat) maxLat = vertex.latitude;
      if (vertex.longitude < minLng) minLng = vertex.longitude;
      if (vertex.longitude > maxLng) maxLng = vertex.longitude;
    }

    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }

  static bool _boundsIntersect(
    LatLngBounds a,
    LatLngBounds b,
    double padding,
  ) {
    return !(a.east + padding < b.west - padding ||
        a.west - padding > b.east + padding ||
        a.north + padding < b.south - padding ||
        a.south - padding > b.north + padding);
  }

  /// Get adaptive padding based on zoom level
  static double getAdaptivePadding(double zoom) {

     return 0.001;
    // if (zoom < 13) return 0.05; // ~5km
    // if (zoom < 15) return 0.02; // ~2km
    // return 0.01; // ~1km
  }
}














 
class MapPositionService {
  static const String _keyLatitude = 'map_last_latitude';
  static const String _keyLongitude = 'map_last_longitude';
  static const String _keyZoom = 'map_last_zoom';
  static const String _keyTimestamp = 'map_last_timestamp';

  // Save current map position
  static Future<void> savePosition(LatLng center, double zoom) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyLatitude, center.latitude);
    await prefs.setDouble(_keyLongitude, center.longitude);
    await prefs.setDouble(_keyZoom, zoom);
    await prefs.setInt(_keyTimestamp, DateTime.now().millisecondsSinceEpoch);
  }

  // Get saved position (returns null if no saved position or too old)
  static Future<MapPosition?> getSavedPosition({int maxAgeHours = 168}) async {
    final prefs = await SharedPreferences.getInstance();
    
    final lat = prefs.getDouble(_keyLatitude);
    final lng = prefs.getDouble(_keyLongitude);
    final zoom = prefs.getDouble(_keyZoom);
    final timestamp = prefs.getInt(_keyTimestamp);

    if (lat == null || lng == null || zoom == null) {
      return null;
    }

    // Check if position is too old (default 7 days)
    if (timestamp != null) {
      final savedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final age = DateTime.now().difference(savedTime);
      if (age.inHours > maxAgeHours) {
        return null; // Position too old, ignore it
      }
    }

    return MapPosition(
      center: LatLng(lat, lng),
      zoom: zoom,
    );
  }

  // Clear saved position
  static Future<void> clearPosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLatitude);
    await prefs.remove(_keyLongitude);
    await prefs.remove(_keyZoom);
    await prefs.remove(_keyTimestamp);
  }

  // Calculate best initial position for a farmer based on their farms
  static MapPosition? calculateFarmerPosition(List<PolygonData> farmerPolygons) {
    if (farmerPolygons.isEmpty) return null;

    // Calculate centroid of all farms
    double totalLat = 0;
    double totalLng = 0;
    int pointCount = 0;

    for (final polygon in farmerPolygons) {
      for (final vertex in polygon.vertices) {
        totalLat += vertex.latitude;
        totalLng += vertex.longitude;
        pointCount++;
      }
    }

    if (pointCount == 0) return null;

    final centerLat = totalLat / pointCount;
    final centerLng = totalLng / pointCount;

    // Calculate appropriate zoom level based on farm spread
    double maxDistance = 0;
    final center = LatLng(centerLat, centerLng);

    for (final polygon in farmerPolygons) {
      for (final vertex in polygon.vertices) {
        final distance = const Distance().as(
          LengthUnit.Meter,
          center,
          vertex,
        );
        if (distance > maxDistance) {
          maxDistance = distance;
        }
      }
    }

    // Set zoom based on maximum distance from center
    double zoom;
    if (maxDistance > 5000) {
      zoom = 13.0; // Very spread out
    } else if (maxDistance > 2000) {
      zoom = 14.5; // Moderately spread
    } else if (maxDistance > 1000) {
      zoom = 15.5; // Close together
    } else {
      zoom = 16.5; // Very close
    }

    return MapPosition(
      center: LatLng(centerLat, centerLng),
      zoom: zoom,
    );
  }
}

class MapPosition {
  final LatLng center;
  final double zoom;

  MapPosition({
    required this.center,
    required this.zoom,
  });
}