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
      // onEnter: isCollapsible
      //     ? (_) {
      //         // if (!sidebarProvider.isPinned) {
      //         //   sidebarProvider.setCollapsed(false);
      //         // }
      //       }
      //     : null,
      // onExit: isCollapsible
      //     ? (_) {
      //         if (!sidebarProvider.isPinned) {
      //           sidebarProvider.setCollapsed(true);
      //         }
      //       }
      //     : null,
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
                width: 40, // Fixed width to match menu items
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
                    // fontWeight: FontWeight.bold,
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
        future: DefaultAssetBundle.of(context).loadString(sideBarAsset!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          try {
            List listMenu = json.decode(snapshot.data.toString());
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

  Widget _itemBuilder(
    BuildContext context,
    int index,
    List listMenu,
    bool isDark,
    bool isCollapsed,
  ) {
    var groupElement = listMenu.elementAt(index);
    List menuList = groupElement['menuList'] ?? [];
    String groupName = groupElement['groupName'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // if (groupName.isNotEmpty && !isCollapsed) ...[
        //   const SizedBox(height: 10),
        //   Text(
        //     groupName,
        //     style: TextStyle(
        //       fontSize: 12,
        //       color: isDark ? Colors.white60 : FlarelineColors.darkBlackText,
        //       fontWeight: FontWeight.bold,
        //     ),
        //   ),
        //   const SizedBox(height: 10),
        // ],
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
