// File: map_widget/map_controls.dart
import 'package:flutter/material.dart';

class MapControls extends StatelessWidget {
  final double zoomLevel;
  final bool isDrawing;
  final bool isEditing;
  final Map<String, String> mapLayers;
  final String selectedMap;
  final int? selectedPolygonIndex;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onToggleDrawing;
  final VoidCallback onToggleEditing;
  final Function(String?) onMapLayerChange;
  final VoidCallback onUndo;

  const MapControls({
    super.key,
    required this.zoomLevel,
    required this.isDrawing,
    required this.isEditing,
    required this.mapLayers,
    required this.selectedMap,
    required this.selectedPolygonIndex,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onToggleDrawing,
    required this.onToggleEditing,
    required this.onMapLayerChange,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardTheme.color ?? Colors.white;
    final surfaceTintColor =
        Theme.of(context).cardTheme.surfaceTintColor ?? Colors.transparent;
    final shadowColor =
        Theme.of(context).cardTheme.shadowColor ?? Colors.transparent;

    return Column(
      children: [
        _buildControlButton(
          tooltip: "Zoom In",
          icon: Icons.add,
          onPressed: onZoomIn,
          backgroundColor: cardColor,
          index: 1,
          surfaceTintColor: surfaceTintColor,
          shadowColor: shadowColor,
        ),
        const SizedBox(height: 5),
        _buildControlButton(
          tooltip: "Zoom Out",
          icon: Icons.remove,
          onPressed: onZoomOut,
          backgroundColor: cardColor,
          index: 2,
          surfaceTintColor: surfaceTintColor,
          shadowColor: shadowColor,
        ),
        const SizedBox(height: 5),
        _buildControlButton(
          tooltip: "Toggle Drawing Mode",
          icon: Icons.create,
          onPressed: onToggleDrawing,
          backgroundColor: isDrawing ? Colors.red : cardColor,
          index: 3,
          surfaceTintColor: surfaceTintColor,
          shadowColor: shadowColor,
        ),
        const SizedBox(height: 5),
        _buildControlButton(
          tooltip: "Change Map Layer",
          icon: Icons.map,
          onPressed: () async {
            final String? newValue = await showMenu<String>(
              context: context,
              position: RelativeRect.fromLTRB(100, 100, 50, 0),
              color: cardColor,
              items: mapLayers.keys.map((String key) {
                return PopupMenuItem<String>(
                  value: key,
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor, // Item background color
                      // borderRadius: BorderRadius.circular(4),
                    ),
                    // padding: EdgeInsets.all(8),
                    child: Text(key),
                  ),
                );
              }).toList(),
            );
            onMapLayerChange(newValue);
          },
          backgroundColor: cardColor,
          index: 4,
          surfaceTintColor: surfaceTintColor,
          shadowColor: shadowColor,
        ),
        const SizedBox(height: 5),
        _buildControlButton(
          tooltip: "Undo last point in selected polygon",
          icon: Icons.undo,
          onPressed: onUndo,
          backgroundColor: cardColor,
          index: 5,
          surfaceTintColor: surfaceTintColor,
          shadowColor: shadowColor,
        ),
        const SizedBox(height: 5),
        _buildControlButton(
          tooltip: "Toggle Edit Mode",
          icon: Icons.edit,
          onPressed: onToggleEditing,
          backgroundColor: isEditing ? Colors.orange : cardColor,
          index: 6,
          surfaceTintColor: surfaceTintColor,
          shadowColor: shadowColor,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
    required int index,
    Color? surfaceTintColor,
    Color? shadowColor,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Get screen size using MediaQuery
        final screenSize = MediaQuery.of(context).size;
        final screenWidth = screenSize.width;

        // Define sizes based on screen width breakpoints
        double buttonSize;

        if (screenWidth < 600) {
          // Small screens (phones)
          buttonSize = 40.0;
        } else {
          // Large screens (desktops, tablets in landscape)
          buttonSize = 30.0;
        }

        return Tooltip(
          message: tooltip,
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: shadowColor ?? Colors.transparent,
                  blurRadius: 13,
                  offset: const Offset(0, 8),
                  spreadRadius: -3,
                ),
              ],
            ),
            child: FloatingActionButton(
              heroTag: 'map-control-$index',
              mini: true,
              onPressed: onPressed,
              backgroundColor: backgroundColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1,
                  color: Colors.transparent,
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                icon,
                size: buttonSize * 0.5, // Icon size proportional to button
              ),
            ),
          ),
        );
      },
    );
  }
}
