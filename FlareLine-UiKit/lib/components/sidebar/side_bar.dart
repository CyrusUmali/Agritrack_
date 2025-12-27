library flareline_uikit;

import 'dart:convert';

import 'package:flareline_uikit/components/sidebar/side_menu.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flareline_uikit/service/sidebar_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SideBarWidget extends StatelessWidget {
  final double? width;
  final String? appName;
  final String? sideBarAsset;
  final Widget? logoWidget;
  final bool? isDark;
  final Color? darkBg;
  final Color? lightBg;
  final Widget? footerWidget;
  final double? logoFontSize;
  final bool isCollapsible;
  final ValueNotifier<String> expandedMenuName = ValueNotifier('');

  SideBarWidget({
    super.key,
    this.darkBg,
    this.lightBg,
    this.width,
    this.appName,
    this.sideBarAsset,
    this.logoWidget,
    this.footerWidget,
    this.logoFontSize = 30,
    this.isDark,
    this.isCollapsible = true,
  });

  @override
  Widget build(BuildContext context) {
    final sidebarProvider = Provider.of<SidebarProvider>(context, listen: true);
    bool isDarkTheme =
        isDark ?? Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 16),
        color: (isDarkTheme ? darkBg : lightBg) ??
            (isDarkTheme ? FlarelineColors.darkBackground : Colors.white),
        width: sidebarProvider.isCollapsed ? 80 : width,
        child: Column(
          children: [
            _logoWidget(context, isDarkTheme, sidebarProvider.isCollapsed),
            const SizedBox(height: 30),
            Expanded(
              child: _sideListWidget(
                context,
                isDarkTheme,
                sidebarProvider.isCollapsed,
              ),
            ),
            if (footerWidget != null) footerWidget!,
          ],
        ),
      ),
    );
  }

  Widget _logoWidget(BuildContext context, bool isDark, bool isCollapsed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (logoWidget != null)
              SizedBox(
                width: 40,
                child: Center(child: logoWidget!),
              ),
            if (!isCollapsed) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  appName ?? '',
                  style: TextStyle(
                    color:
                        isDark ? Colors.white : FlarelineColors.darkBlackText,
                    fontSize: logoFontSize,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sideListWidget(BuildContext context, bool isDark, bool isCollapsed) {
    if (sideBarAsset == null) {
      return const SizedBox.shrink();
    }

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: FutureBuilder(
        future: _loadMenuData(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Use cached count if available, otherwise default to 6
            return _buildLoadingPlaceholders(
              isDark,
              isCollapsed,
              snapshot.data?['cachedCount'] as int? ?? 6,
            );
          }

          if (!snapshot.hasData || snapshot.data?['menu'] == null) {
            return _buildEmptyState(isDark);
          }

          try {
            List listMenu = snapshot.data!['menu'] as List;
            return ListView.separated(
              padding: EdgeInsets.only(left: isCollapsed ? 0 : 8, right: 8),
              itemBuilder: (ctx, index) {
                return _itemBuilder(ctx, index, listMenu, isDark, isCollapsed);
              },
              separatorBuilder: (context, index) => const Divider(
                height: 8,
                color: Colors.transparent,
              ),
              itemCount: listMenu.length,
            );
          } catch (e) {
            return Center(child: Text('Error loading menu: $e'));
          }
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _loadMenuData(BuildContext context) async {
    final jsonString = await DefaultAssetBundle.of(context).loadString(sideBarAsset!);
    final List listMenu = json.decode(jsonString);
    
    // Calculate total menu items
    int totalMenuItems = 0;
    for (var group in listMenu) {
      List menuList = group['menuList'] ?? [];
      totalMenuItems += menuList.length;
    }
    
    return {
      'menu': listMenu,
      'cachedCount': totalMenuItems,
    };
  }

  Widget _buildLoadingPlaceholders(bool isDark, bool isCollapsed, int count) {
    
    return ListView.separated(
      padding: EdgeInsets.only(left: isCollapsed ? 0 : 8, right: 8),
      itemCount: count,
      separatorBuilder: (context, index) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        return _ShimmerPlaceholder(
          isDark: isDark,
          isCollapsed: isCollapsed,
          delay: Duration(milliseconds: index * 50),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_open,
              size: 48,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No menu items',
              style: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemBuilder(
    BuildContext context,
    int index,
    List listMenu,
    bool isDark,
    bool isCollapsed,
  ) {
    var groupElement = listMenu.elementAt(index);
    List menuList = groupElement['menuList'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: menuList
              .map((e) => SideMenuWidget(
                    e: e,
                    isDark: isDark,
                    expandedMenuName: expandedMenuName,
                    isCollapsed: isCollapsed,
                  ))
              .toList(),
        ),
        if (index < listMenu.length - 1 && !isCollapsed) ...[
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ShimmerPlaceholder extends StatefulWidget {
  final bool isDark;
  final bool isCollapsed;
  final Duration delay;

  const _ShimmerPlaceholder({
    required this.isDark,
    required this.isCollapsed,
    this.delay = Duration.zero,
  });

  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: widget.isCollapsed ? 12 : 8,
            vertical: 4,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCollapsed ? 8 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: widget.isDark
                ? Colors.white.withOpacity(0.03)
                : Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Icon placeholder with shimmer
              _buildShimmerBox(
                width: 20,
                height: 20,
                borderRadius: 6,
              ),
              
              if (!widget.isCollapsed) ...[
                const SizedBox(width: 12),
                // Text placeholder with shimmer
                Expanded(
                  child: _buildShimmerBox(
                    height: 12,
                    borderRadius: 6,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerBox({
    double? width,
    required double height,
    required double borderRadius,
  }) {
    final baseColor = widget.isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.04);
    
    final highlightColor = widget.isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            baseColor,
            highlightColor,
            baseColor,
          ],
          stops: [
            0.0,
            _animation.value.clamp(0.0, 1.0),
            1.0,
          ],
        ),
      ),
    );
  }
}