import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

// Add this Barangay model
class Barangay {
  final String name;
  final List<List<LatLng>> polygons;
  final Color color;
  final LatLng? labelPosition;

  Barangay({
    required this.name,
    required this.polygons,
    this.color = const Color(0x3000FF00),
    this.labelPosition,
  });
}
