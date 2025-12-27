  
import 'package:flutter/material.dart'; 
import 'package:latlong2/latlong.dart'; 
import 'dart:async';
import 'package:turf/turf.dart' as turf;




class MeasurementOverlay extends StatefulWidget {
  final List<LatLng> currentPolygon;
  final LatLng? previewPoint;

  const MeasurementOverlay({super.key, 
    required this.currentPolygon,
    required this.previewPoint,
  });

  @override
  State<MeasurementOverlay> createState() => MeasurementOverlayState();
}

class MeasurementOverlayState extends State<MeasurementOverlay> {
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
  void didUpdateWidget(MeasurementOverlay oldWidget) {
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