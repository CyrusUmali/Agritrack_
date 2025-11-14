library flareline_uikit;

import 'package:flareline/pages/toolbar.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flareline_uikit/components/sidebar/side_bar.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flareline_uikit/service/sidebar_provider.dart';
import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/breaktab.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:responsive_builder/responsive_builder.dart';

abstract class FlarelineLayoutWidget extends StatelessWidget {
  ValueNotifier<bool> get _sidebarPinnedNotifier => ValueNotifier(false);

  const FlarelineLayoutWidget({super.key});

  String get appName => 'AgriTrack';
  bool get showTitle => true;
  bool get isAlignCenter => false;
  bool get showSideBar => true;

  bool showToolBar(BuildContext context) => true;
  bool get showDrawer => false;
  bool get isContentScroll => true;
  double get logoFontSize => 30;
  Color get sideBarDarkColor => FlarelineColors.darkBackground;
  Color get sideBarLightColor => Colors.white;
  double get sideBarWidth => 240;
  double get sideBarCollapsedWidth => 100;
  bool get isSidebarCollapsible => true;

  String sideBarAsset(BuildContext context) =>
      'assets/routes/menu_route_en.json';

  bool isDarkTheme(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  EdgeInsetsGeometry? get customPadding => null;
  EdgeInsetsGeometry? get padding =>
      const EdgeInsets.symmetric(horizontal: 20, vertical: 16);

  String? get logoImageAsset => null;


Widget? logoWidget(BuildContext context) {
  final sidebarProvider = Provider.of<SidebarProvider>(context, listen: false);
  bool isDark = isDarkTheme(context);
  
  Widget buildLogo() {
    if (logoImageAsset != null) {
      if (logoImageAsset!.endsWith('svg')) {
        return SvgPicture.asset(
          logoImageAsset!,
          height: 32,
        );
      }
      return Image.asset(
        logoImageAsset!,
        width: 32,
        height: 32,
      );
    }
    return SvgPicture.asset(
      'assets/logo/logo_${isDark ? 'white' : 'dark'}.svg',
      height: 32,
    );
  }

  return _HoverableLogo(
    onTap: () => sidebarProvider.togglePin(),
    child: buildLogo(),
  );
}

  Widget? footerWidget(BuildContext context) {
    return null;
  }

  Widget? toolbarWidget(BuildContext context, bool showDrawer) {
    return null;
  }

  Widget? breakTabRightWidget(BuildContext context) {
    return null;
  }

  String breakTabTitle(BuildContext context) {
    return '';
  }

  List<BreadcrumbItem>? breakTabBreadcrumbs(BuildContext context) {
    return null; // Default: use standard breadcrumb
  }

  Widget? breakTabWidget(BuildContext context) {
    return null;
  }

  Widget contentDesktopWidget(BuildContext context);
  Widget contentMobileWidget(BuildContext context) =>
      contentDesktopWidget(context);

  Color? backgroundColor(BuildContext context) {
    return isDarkTheme(context) ? FlarelineColors.darkerBackground : null;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final farmer = userProvider.farmer;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: backgroundColor(context),
      appBar: AppBar(toolbarHeight: 0),
      body: ResponsiveBuilder(
        builder: (context, sizingInformation) {
          final sidebarProvider = Provider.of<SidebarProvider>(context);

          if (sizingInformation.deviceScreenType == DeviceScreenType.desktop) {
            return Row(
              children: [
                if (showSideBar)
                  sideBarWidget(context, sidebarProvider.isCollapsed),
                Expanded(child: rightContentWidget(context))
              ],
            );
          }
          return rightContentWidget(context);
        },
      ),
      drawer: sideBarWidget(context, false),
    );
  }

  Widget sideBarWidget(BuildContext context, bool isCollapsed) {
    return SideBarWidget(
      isDark: isDarkTheme(context),
      darkBg: sideBarDarkColor,
      lightBg: sideBarLightColor,
      appName: appName,
      sideBarAsset: sideBarAsset(context),
      width: isCollapsed ? sideBarCollapsedWidth : sideBarWidth,
      logoWidget: logoWidget(context),
      footerWidget: footerWidget(context),
      logoFontSize: logoFontSize,
      isCollapsible: isSidebarCollapsible,
    );
  }

  Widget rightContentWidget(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final farmer = userProvider.farmer;

    Widget contentWidget = Column(
      children: [
        if (showTitle && breakTabTitle(context).isNotEmpty)
          SizedBox(
            height: 50,
            child: breakTabWidget(context) ??
                BreakTab(
                  breakTabTitle(context),
                  breadcrumbs: breakTabBreadcrumbs(context),
                  rightWidget: breakTabRightWidget(context),
                ),
          ),
        if (showTitle) const SizedBox(height: 10),
        isContentScroll
            ? ScreenTypeLayout.builder(
                desktop: contentDesktopWidget,
                mobile: contentMobileWidget,
                tablet: contentMobileWidget,
              )
            : Expanded(
                child: ScreenTypeLayout.builder(
                  desktop: contentDesktopWidget,
                  mobile: contentMobileWidget,
                  tablet: contentMobileWidget,
                ),
              ),
      ],
    );

    return Column(
      children: [
        if (showToolBar(context))
          ToolBarWidget(
                showMore: showDrawer,
                showChangeTheme: true,
                userInfoWidget: CircleAvatar(
                  backgroundImage: farmer?.imageUrl != null
                      ? NetworkImage(farmer!.imageUrl!)
                      : AssetImage('assets/user/user-01.png') as ImageProvider,
                  radius: 22,
                ),
              ) ??
              const SizedBox.shrink(),
        if (showToolBar(context)) const SizedBox(height: 0),
        Expanded(
          child: Container(
            width: double.maxFinite,
            height: double.maxFinite,
            alignment: isAlignCenter ? Alignment.center : null,
            padding: customPadding ?? padding,
            child: isContentScroll
                ? SingleChildScrollView(child: contentWidget)
                : contentWidget,
          ),
        ),
      ],
    );
  }
}





class _HoverableLogo extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _HoverableLogo({
    required this.onTap,
    required this.child,
  });

  @override
  State<_HoverableLogo> createState() => _HoverableLogoState();
}

class _HoverableLogoState extends State<_HoverableLogo> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isHovered
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(0),
            child: AnimatedScale(
              scale: _isHovered ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
 