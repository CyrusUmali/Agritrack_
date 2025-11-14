import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';

class MapMiniView extends StatefulWidget {
  final bool isMobile;
  final VoidCallback? onTap;

  const MapMiniView({super.key, this.isMobile = false, this.onTap});

  @override
  State<MapMiniView> createState() => _MapMiniViewState();
}

class _MapMiniViewState extends State<MapMiniView> {
  bool _isHovered = false;
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 10),
      child: Column(
        children: [
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) {
                if (!widget.isMobile) {
                  setState(() => _isHovered = true);
                }
              },
              onExit: (_) {
                if (!widget.isMobile) {
                  setState(() {
                    _isHovered = false;
                    _isTapped = false;
                  });
                }
              },
              child: GestureDetector(
                onTapDown: (_) => setState(() => _isTapped = true),
                onTapUp: (_) => setState(() => _isTapped = false),
                onTapCancel: () => setState(() => _isTapped = false),
                onTap: widget.onTap ??
                    () {
                      Navigator.pushNamed(context, '/map');
                    },
                child: Card(
                  elevation: (_isHovered || _isTapped) ? 4 : 1,
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      // Use AbsorbPointer to prevent FlutterMap from intercepting gestures
                      AbsorbPointer(
                        child: FlutterMap(
                          options: MapOptions(
                            center: const LatLng(14.077557, 121.328938),
                            zoom: 13,
                            minZoom: 13,
                            maxBounds: LatLngBounds(
                              const LatLng(13.927557, 121.178938),
                              const LatLng(14.227557, 121.478938),
                            ),
                            // Disable interactive flags
                            interactiveFlags: InteractiveFlag.none,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  "https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png",
                              subdomains: const ['a', 'b', 'c'],
                              tileProvider: CancellableNetworkTileProvider(),
                              userAgentPackageName: 'com.example.app',
                            ),
                          ],
                        ),
                      ),
                      if (_isHovered || _isTapped)
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: (_isHovered || _isTapped) ? 1 : 0,
                          child: Container(
                            color: Colors.black.withOpacity(0.3),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.isMobile
                                        ? Icons.touch_app
                                        : Icons.zoom_in,
                                    size: 48,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.isMobile
                                        ? 'Tap to View Map'
                                        : 'View Full Map',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
