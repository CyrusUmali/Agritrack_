library flareline_uikit;

import 'package:flutter/material.dart';

class BreakTab extends StatelessWidget {
  final String title;
  final Widget? rightWidget;
  final List<BreadcrumbItem>? breadcrumbs;

  const BreakTab(
    this.title, {
    super.key,
    this.rightWidget,
    this.breadcrumbs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      rightWidget ?? _buildBreadcrumbs(context),
    ]);
  }

  Widget _buildBreadcrumbs(BuildContext context) {
    final items = breadcrumbs ??
        [
          BreadcrumbItem('Dashboard', '/'),
        ];

    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          InkWell(
            child: Text(
              items[i].title,
              style: const TextStyle(fontSize: 14),
            ),
            onTap: () {
              if (items[i].route != null) {
                _navigateToRoute(context, items[i].route!);
              }
            },
          ),
          if (i < items.length - 1) ...[
            const SizedBox(width: 6),
            const Text('/'),
            const SizedBox(width: 6),
          ],
        ],
        const SizedBox(width: 6),
        const Text('/'),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.blue),
        ),
      ],
    );
  }

  void _navigateToRoute(BuildContext context, String targetRoute) {
    final navigator = Navigator.of(context);

    // Check if the route already exists in the stack
    bool routeExists = false;
    navigator.popUntil((route) {
      if (route.settings.name == targetRoute) {
        routeExists = true;
        return true;
      }
      return false;
    });

    if (routeExists) {
      // If route exists, pop back to it
      navigator.popUntil((route) => route.settings.name == targetRoute);
    } else {
      // If route doesn't exist, navigate to it normally (push)
      navigator.pushNamed(targetRoute);
    }
  }
}

class BreadcrumbItem {
  final String title;
  final String? route;

  BreadcrumbItem(this.title, [this.route]);
}