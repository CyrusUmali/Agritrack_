import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:turf/turf.dart' as turf;

class MobileMeasurementOverlay extends StatefulWidget {
  final List<LatLng> currentPolygon;

  const MobileMeasurementOverlay({
    Key? key,  // Changed from super.key
    required this.currentPolygon,
  }) : super(key: key);

  @override
  State<MobileMeasurementOverlay> createState() => _MobileMeasurementOverlayState();
}

class _MobileMeasurementOverlayState extends State<MobileMeasurementOverlay> {
  double _cachedArea = 0.0;
  double _cachedPerimeter = 0.0;
  double _cachedDistance = 0.0;
  int _lastPointCount = 0;
  
  @override
  void initState() {
    super.initState();
    print('MobileMeasurementOverlay: initState');
    _lastPointCount = widget.currentPolygon.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateMeasurements();
      }
    });
  }

  @override
  void didUpdateWidget(MobileMeasurementOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    print('MobileMeasurementOverlay: didUpdateWidget - old: ${oldWidget.currentPolygon.length}, new: ${widget.currentPolygon.length}');
    
    // Check if polygon actually changed
    if (widget.currentPolygon.length != _lastPointCount ||
        _hasPolygonChanged(oldWidget.currentPolygon, widget.currentPolygon)) {
      _lastPointCount = widget.currentPolygon.length;
      print('Polygon changed, updating measurements immediately');
      _updateMeasurements();
    }
  }

  // Helper to check if polygon changed
  bool _hasPolygonChanged(List<LatLng> oldPolygon, List<LatLng> newPolygon) {
    if (oldPolygon.length != newPolygon.length) return true;
    
    for (int i = 0; i < oldPolygon.length; i++) {
      if (oldPolygon[i].latitude != newPolygon[i].latitude ||
          oldPolygon[i].longitude != newPolygon[i].longitude) {
        return true;
      }
    }
    
    return false;
  }

  void _updateMeasurements() {
    print('_updateMeasurements called with ${widget.currentPolygon.length} points');
    
    if (!mounted) {
      print('Widget not mounted, skipping update');
      return;
    }

    final pointCount = widget.currentPolygon.length;
    
    // Calculate immediately without setState if possible
    double newArea = 0.0;
    double newPerimeter = 0.0;
    double newDistance = 0.0;
    
    if (pointCount >= 3) {
      // 3+ points: Show area and perimeter
      newArea = _calculateArea(widget.currentPolygon);
      newPerimeter = _calculatePerimeter(widget.currentPolygon);
      print('Calculated: Area=${newArea}ha, Perimeter=${newPerimeter}m');
    } else if (pointCount == 2) {
      // 2 points: Show distance
      newDistance = const Distance().distance(
        widget.currentPolygon[0],
        widget.currentPolygon[1],
      );
      print('Calculated: Distance=${newDistance}m');
    } else {
      print('Cleared measurements');
    }
    
    // Only setState if values actually changed
    if (_cachedArea != newArea || 
        _cachedPerimeter != newPerimeter || 
        _cachedDistance != newDistance) {
      setState(() {
        _cachedArea = newArea;
        _cachedPerimeter = newPerimeter;
        _cachedDistance = newDistance;
      });
      print('State updated with new measurements');
    } else {
      print('Values unchanged, skipping setState');
    }
  }

  double _calculateArea(List<LatLng> vertices) {
    if (vertices.length < 3) return 0.0;

    try {
      final coordinates = [
        vertices.map((p) => turf.Position(p.longitude, p.latitude)).toList()
      ];

      final geoJsonPolygon = turf.Polygon(coordinates: coordinates);
      final areaInSqMeters = turf.area(geoJsonPolygon);
      final areaInHectares = areaInSqMeters! / 10000;

      return double.parse(areaInHectares.toStringAsFixed(3));
    } catch (e) {
      print('Error calculating area: $e');
      return 0.0;
    }
  }

  double _calculatePerimeter(List<LatLng> points) {
    if (points.length < 2) return 0.0;
    
    try {
      double perimeter = 0.0;
      for (int i = 0; i < points.length; i++) {
        final p1 = points[i];
        final p2 = points[(i + 1) % points.length];
        perimeter += const Distance().distance(p1, p2);
      }
      return perimeter;
    } catch (e) {
      print('Error calculating perimeter: $e');
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    print('MobileMeasurementOverlay: build - points: ${widget.currentPolygon.length}');
    
    return Container(
      color: Colors.transparent,
      child: IgnorePointer(
        ignoring: true,
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blueAccent, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  '📐 Live Measurement',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Points count - always show
                _buildMeasurementRow(
                  icon: '📍',
                  label: 'Points',
                  value: '${widget.currentPolygon.length}',
                ),
                
                // Distance for 2 points only
                if (widget.currentPolygon.length == 2 && _cachedDistance > 0) ...[
                  const SizedBox(height: 6),
                  _buildMeasurementRow(
                    icon: '📏',
                    label: 'Distance',
                    value: '${(_cachedDistance / 1000).toStringAsFixed(3)} km',
                    highlight: true,
                  ),
                ],
                
                // Area and perimeter for 3+ points
                if (widget.currentPolygon.length >= 3) ...[
                  const SizedBox(height: 6),
                  _buildMeasurementRow(
                    icon: '📐',
                    label: 'Area',
                    value: _cachedArea > 0 
                        ? '${_cachedArea.toStringAsFixed(3)} ha'
                        : 'Calculating...',
                    highlight: true,
                  ),
                  const SizedBox(height: 6),
                  _buildMeasurementRow(
                    icon: '⭕',
                    label: 'Perimeter',
                    value: _cachedPerimeter > 0
                        ? '${(_cachedPerimeter / 1000).toStringAsFixed(3)} km'
                        : 'Calculating...',
                  ),
                ],
              ],
            ),
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
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: highlight ? Colors.greenAccent : Colors.white,
            fontSize: 14,
            fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    print('MobileMeasurementOverlay: dispose');
    super.dispose();
  }
}