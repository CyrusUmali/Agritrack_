// polygon_modal_components/vertices_coordinates_card.dart

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class VerticesCoordinatesCard {
  static Widget build({
    required BuildContext context,
    required List<LatLng> vertices,
    required ThemeData theme,
  }) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Polygon Vertices',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (vertices.isEmpty)
              Text(
                'No vertices defined',
                style: theme.textTheme.bodyMedium,
              )
            else
              Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: SingleChildScrollView(
                      child: Column(
                        children: vertices
                            .map((vertex) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Lat: ${vertex.latitude.toStringAsFixed(6)}',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        'Lng: ${vertex.longitude.toStringAsFixed(6)}',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        _logVerticesToConsole(vertices);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vertices logged to console'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text('Log Vertices to Console'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  static void _logVerticesToConsole(List<LatLng> vertices) {
    print("'vertices': [");
    for (final vertex in vertices) {
      print("      {'lat': ${vertex.latitude}, 'lng': ${vertex.longitude}},");
    }
    print("    ]");
  }
}
