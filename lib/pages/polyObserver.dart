import 'package:flareline/pages/test/map_widget/polygon_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PolygonRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) => _handleRouteChange();
  @override
  void didPop(Route route, Route? previousRoute) => _handleRouteChange();

  void _handleRouteChange() {
    final context = navigator?.context;
    if (context != null) {
      context.read<PolygonManager>().removeInfoCardOverlay();
    }
  }
}
