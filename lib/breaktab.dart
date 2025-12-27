library flareline_uikit;

import 'package:flutter/material.dart';

class BreakTab extends StatelessWidget {
  final String title; 
  final Widget? rightWidget; 
  final List<BreadcrumbItem>? breadcrumbs;
  final bool showBreadcrumbs;
  final bool showCurrentRoute;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  
  // Add a constant for your special title
  static const String hideAllTitle = '---HIDE_ALL---';

  const BreakTab(
    this.title, {
    super.key,
    this.rightWidget,
    this.breadcrumbs,
    this.showBreadcrumbs = true,
    this.showCurrentRoute = true,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Check if title is the special "hide all" title
    final isHideAllTitle = title == hideAllTitle;
    
    // If it's the special hide title, return an empty SizedBox with zero height
    if (isHideAllTitle) {
      return const SizedBox.shrink();
    }
    
    // Don't show back button if it's the special title
    final shouldShowBackButton = !isHideAllTitle && (showBackButton || title.isEmpty);
    
    return Row( 
      children: [
        // Back button (if enabled or title is empty, but not for special title)
        if (shouldShowBackButton)
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBackPressed ?? () {
                Navigator.of(context).pop();
              },
              tooltip: 'Go back',
              iconSize: 20.0,
              padding: const EdgeInsets.all(4.0),
              constraints: const BoxConstraints(),
            ),
          ),
        
        Expanded(
          child: title.isNotEmpty && !isHideAllTitle
              ? Text(
                  title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                )
              : const SizedBox.shrink(), // Hide title when empty or special title
        ),
        if (rightWidget != null) rightWidget!,
        // Don't show breadcrumbs if it's the special title
        if (rightWidget == null && showBreadcrumbs && title.isNotEmpty && !isHideAllTitle) 
          _buildBreadcrumbs(context),
        if (rightWidget == null && (!showBreadcrumbs || title.isEmpty || isHideAllTitle)) 
          const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildBreadcrumbs(BuildContext context) {
    // Don't show breadcrumbs when title is empty or special title
    if (title.isEmpty || title == hideAllTitle) return const SizedBox.shrink();
    
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
        // Conditionally show current route
        if (showCurrentRoute && items.isNotEmpty) ...[
          const SizedBox(width: 6),
          const Text('/'),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.blue),
          ),
        ],
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