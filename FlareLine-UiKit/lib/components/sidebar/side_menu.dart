// ignore_for_file: must_be_immutable, deprecated_member_use

import 'dart:async';

import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:window_location_href/window_location_href.dart';

class SideMenuWidget extends StatefulWidget {
  dynamic e;
  bool? isDark;
  bool isCollapsed;
  ValueNotifier<String> expandedMenuName;

  SideMenuWidget({
    super.key,
    this.e,
    this.isDark,
    required this.expandedMenuName,
    this.isCollapsed = false,
  });

  @override
  State<SideMenuWidget> createState() => _SideMenuWidgetState();
}

class _SideMenuWidgetState extends State<SideMenuWidget> {
  static OverlayEntry? _currentTooltip;
  static Timer? _tooltipTimer;
  static Timer? _showTimer;
  bool _isHovering = false;

  void setExpandedMenuName(String menuName) {
    if (widget.expandedMenuName.value == menuName) {
      widget.expandedMenuName.value = '';
    } else {
      widget.expandedMenuName.value = menuName;
    }
  }

  bool isSelectedPath(BuildContext context, String path) {
    if (kIsWeb) {
      String? location = href;
      if (location != null) {
        var uri = Uri.dataFromString(location);
        String? routePath = uri.path;
        return routePath.endsWith(path);
      }
    }

    String? routePath = ModalRoute.of(context)?.settings.name;
    return routePath == path;
  }

  @override
  void dispose() {
    _removeCurrentTooltip();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widget.isDark ??= false;
    return _itemMenuWidget(context, widget.e, widget.isDark!);
  }

  Widget _itemMenuWidget(BuildContext context, e, bool isDark) {
    String itemMenuName = e['menuName'] ?? '';
    List? childList = e['childList'];
    bool isSelected = childList != null && childList.isNotEmpty
        ? false
        : isSelectedPath(context, e['path'] ?? '');

    return Column(
      children: [
        Builder(
          builder: (BuildContext itemContext) => MouseRegion(
            onEnter: (_) => setState(() => _isHovering = true),
            onExit: (_) => setState(() => _isHovering = false),
            child: InkWell(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: isSelected
                      ? (isDark
                          ? const LinearGradient(
                              colors: [Color(0x0C316AFF), Color(0x38306AFF)],
                            )
                          : const LinearGradient(
                              colors: [
                                FlarelineColors.background,
                                FlarelineColors.gray
                              ],
                            ))
                      : null,
                  color: !isSelected && _isHovering
                      ? (isDark
                          ? Colors.white.withOpacity(0.05)
                          : FlarelineColors.gray.withOpacity(0.3))
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (e['icon'] != null)
                      Container(
                        width: 40,
                        alignment: Alignment.center,
                        child: AnimatedScale(
                          scale: _isHovering ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: SvgPicture.asset(
                            e['icon'],
                            width: 18,
                            height: 23,
                            color: isDark
                                ? Colors.white
                                : FlarelineColors.darkBlackText,
                          ),
                        ),
                      ),
                    if (!widget.isCollapsed) ...[
                      Expanded(
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOut,
                          child: Text(
                            itemMenuName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : FlarelineColors.darkBlackText,
                              fontWeight:
                                  _isHovering ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                      if (childList != null && childList.isNotEmpty)
                        ValueListenableBuilder(
                          valueListenable: widget.expandedMenuName,
                          builder: (ctx, menuName, child) {
                            bool expanded = menuName == itemMenuName;
                            return AnimatedOpacity(
                              opacity: widget.isCollapsed ? 0 : 1,
                              duration: const Duration(milliseconds: 100),
                              child: Container(
                                width: 24,
                                alignment: Alignment.center,
                                child: Icon(
                                  expanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: isDark
                                      ? Colors.white
                                      : FlarelineColors.darkBlackText,
                                  size: 20,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ],
                ),
              ),
              onTap: () {
                _removeCurrentTooltip();
                if (childList != null && childList.isNotEmpty) {
                  setExpandedMenuName(itemMenuName);
                } else {
                  pushOrJump(context, e);
                }
              },
              onHover: (hovering) {
                if (widget.isCollapsed) {
                  if (hovering) {
                    _scheduleTooltipShow(itemContext, e, isDark);
                  } else {
                    _scheduleTooltipRemoval();
                  }
                }
              },
            ),
          ),
        ),
        if (!widget.isCollapsed && childList != null && childList.isNotEmpty)
          ValueListenableBuilder(
            valueListenable: widget.expandedMenuName,
            builder: (ctx, menuName, child) {
              return AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: Visibility(
                  visible: menuName == itemMenuName,
                  child: Column(
                    children: childList
                        .map((e) => _itemSubMenuWidget(context, e, isDark))
                        .toList(),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _itemSubMenuWidget(BuildContext context, e, bool isDark) {
    bool isSelected = isSelectedPath(context, e['path'] ?? '');
    String itemMenuName = e['menuName'] ?? '';
    
    return _SubMenuItem(
      itemMenuName: itemMenuName,
      isSelected: isSelected,
      isDark: isDark,
      onTap: () {
        _removeCurrentTooltip();
        pushOrJump(context, e);
      },
    );
  }

  static void _removeCurrentTooltip() {
    _tooltipTimer?.cancel();
    _tooltipTimer = null;
    _showTimer?.cancel();
    _showTimer = null;

    if (_currentTooltip != null) {
      try {
        if (_currentTooltip!.mounted) {
          _currentTooltip!.remove();
        }
      } catch (e) {
        debugPrint('Error removing tooltip: $e');
      } finally {
        _currentTooltip = null;
      }
    }
  }

  void _scheduleTooltipShow(BuildContext context, dynamic e, bool isDark) {
    _tooltipTimer?.cancel();
    _showTimer?.cancel();
    _removeCurrentTooltip();

    _showTimer = Timer(const Duration(milliseconds: 300), () {
      if (context.mounted) {
        _showCollapsedMenuTooltip(context, e, isDark);
      }
    });
  }

  static void _scheduleTooltipRemoval() {
    _showTimer?.cancel();
    _showTimer = null;
    _tooltipTimer?.cancel();

    _tooltipTimer = Timer(const Duration(milliseconds: 100), () {
      _removeCurrentTooltip();
    });
  }

  void _showCollapsedMenuTooltip(BuildContext context, dynamic e, bool isDark) {
    _removeCurrentTooltip();

    if (!context.mounted) return;

    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.of(context).size;

    double left = offset.dx + renderBox.size.width + 8;
    double top = offset.dy;

    const tooltipWidth = 160.0;
    if (left + tooltipWidth > screenSize.width) {
      left = offset.dx - tooltipWidth - 8;
    }

    const tooltipMaxHeight = 200.0;
    if (top + tooltipMaxHeight > screenSize.height) {
      top = screenSize.height - tooltipMaxHeight - 8;
    }
    if (top < 0) {
      top = 8;
    }

    _currentTooltip = OverlayEntry(
      builder: (overlayContext) => Positioned(
        left: left,
        top: top,
        child: MouseRegion(
          onEnter: (_) {
            _tooltipTimer?.cancel();
            _tooltipTimer = null;
          },
          onExit: (_) {
            _scheduleTooltipRemoval();
          },
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 160,
              constraints: const BoxConstraints(maxWidth: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Text(
                      e['menuName'] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (e['childList'] != null && e['childList'].isNotEmpty) ...[
                    Divider(
                      height: 8,
                      thickness: 0.5,
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                    ),
                    ...e['childList'].map<Widget>((child) {
                      return _TooltipSubMenuItem(
                        menuName: child['menuName'] ?? '',
                        isDark: isDark,
                        onTap: () {
                          _removeCurrentTooltip();
                          pushOrJump(context, child);
                        },
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      overlay.insert(_currentTooltip!);
    } catch (e) {
      debugPrint('Error inserting tooltip: $e');
      _currentTooltip = null;
    }
  }

  void pushOrJump(BuildContext context, e) {
    _removeCurrentTooltip();

    if (Scaffold.of(context).isDrawerOpen) {
      Scaffold.of(context).closeDrawer();
    }

    String path = e['path'];
    String? routePath = ModalRoute.of(context)?.settings.name;

    if (path == routePath) {
      return;
    }
    Navigator.of(context).pushNamed(path);
  }
}

// Separate widget for submenu items with hover effect
class _SubMenuItem extends StatefulWidget {
  final String itemMenuName;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _SubMenuItem({
    required this.itemMenuName,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_SubMenuItem> createState() => _SubMenuItemState();
}

class _SubMenuItemState extends State<_SubMenuItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: InkWell(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(left: 8, right: 8),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: widget.isSelected
                ? (widget.isDark
                    ? FlarelineColors.darkBackground
                    : FlarelineColors.gray)
                : (_isHovering
                    ? (widget.isDark
                        ? Colors.white.withOpacity(0.05)
                        : FlarelineColors.gray.withOpacity(0.5))
                    : Colors.transparent),
          ),
          child: Row(
            children: [
              const SizedBox(width: 40),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: widget.isDark
                        ? Colors.white
                        : FlarelineColors.darkBlackText,
                    fontWeight: _isHovering ? FontWeight.w600 : FontWeight.normal,
                  ),
                  child: Text(widget.itemMenuName),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Separate widget for tooltip submenu items with hover effect
class _TooltipSubMenuItem extends StatefulWidget {
  final String menuName;
  final bool isDark;
  final VoidCallback onTap;

  const _TooltipSubMenuItem({
    required this.menuName,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_TooltipSubMenuItem> createState() => _TooltipSubMenuItemState();
}

class _TooltipSubMenuItemState extends State<_TooltipSubMenuItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: _isHovering
                ? (widget.isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.2))
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 150),
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isDark ? Colors.grey[300] : Colors.grey[700],
                    fontWeight: _isHovering ? FontWeight.w600 : FontWeight.normal,
                  ),
                  child: Text(
                    widget.menuName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}