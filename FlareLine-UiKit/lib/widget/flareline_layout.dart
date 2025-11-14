// library flareline_uikit;

// import 'package:flareline_uikit/components/sidebar/side_bar.dart';
// import 'package:flareline_uikit/components/toolbar/toolbar.dart';
// import 'package:flareline_uikit/core/theme/flareline_colors.dart';
// import 'package:flareline_uikit/service/sidebar_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:flareline_uikit/components/breaktab.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:provider/provider.dart';
// import 'package:responsive_builder/responsive_builder.dart';

// abstract class FlarelineLayoutWidget extends StatelessWidget {
//   ValueNotifier<bool> get _sidebarPinnedNotifier => ValueNotifier(false);

//   const FlarelineLayoutWidget({super.key});

//   // Fixed: Made this a getter instead of final field to avoid const constructor issues

//   String get appName => 'AgriTrack';
//   bool get showTitle => true;
//   bool get isAlignCenter => false;
//   bool get showSideBar => true;

//   bool showToolBar(BuildContext context) => true;
//   bool get showDrawer => false;
//   bool get isContentScroll => true;
//   double get logoFontSize => 30;
//   Color get sideBarDarkColor => FlarelineColors.darkBackground;
//   Color get sideBarLightColor => Colors.white;
//   Color? get backgroundColor => null;
//   double get sideBarWidth => 240;
//   double get sideBarCollapsedWidth => 100;
//   bool get isSidebarCollapsible => true;

//   String sideBarAsset(BuildContext context) =>
//       'assets/routes/menu_route_en.json';

//   bool isDarkTheme(BuildContext context) =>
//       Theme.of(context).brightness == Brightness.dark;

//   EdgeInsetsGeometry? get customPadding => null;
//   EdgeInsetsGeometry? get padding =>
//       const EdgeInsets.symmetric(horizontal: 20, vertical: 16);

//   String? get logoImageAsset => null;

//   Widget? logoWidget(BuildContext context) {
//     bool isDark = isDarkTheme(context);
//     if (logoImageAsset != null) {
//       if (logoImageAsset!.endsWith('svg')) {
//         return SvgPicture.asset(
//           logoImageAsset!,
//           height: 32,
//         );
//       }
//       return Image.asset(
//         logoImageAsset!,
//         width: 32,
//         height: 32,
//       );
//     }
//     return SvgPicture.asset(
//       'assets/logo/logo_${isDark ? 'white' : 'dark'}.svg',
//       height: 32,
//     );
//   }

//   Widget? footerWidget(BuildContext context) {
//     return null;
//   }

//   Widget? toolbarWidget(BuildContext context, bool showDrawer) {
//     return null;
//   }

//   Widget? breakTabRightWidget(BuildContext context) {
//     return null;
//   }

//   String breakTabTitle(BuildContext context) {
//     return '';
//   }

//   Widget? breakTabWidget(BuildContext context) {
//     return null;
//   }

//   Widget contentDesktopWidget(BuildContext context);
//   Widget contentMobileWidget(BuildContext context) =>
//       contentDesktopWidget(context);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: backgroundColor,
//       appBar: AppBar(toolbarHeight: 0),
//       body: ResponsiveBuilder(
//         builder: (context, sizingInformation) {
//           final sidebarProvider = Provider.of<SidebarProvider>(context);

//           if (sizingInformation.deviceScreenType == DeviceScreenType.desktop) {
//             return Row(
//               children: [
//                 if (showSideBar)
//                   sideBarWidget(context, sidebarProvider.isCollapsed),
//                 Expanded(child: rightContentWidget(context))
//               ],
//             );
//           }
//           return rightContentWidget(context);
//         },
//       ),
//       drawer: sideBarWidget(context, false),
//     );
//   }

//   Widget sideBarWidget(BuildContext context, bool isCollapsed) {
//     return SideBarWidget(
//       isDark: isDarkTheme(context),
//       darkBg: sideBarDarkColor,
//       lightBg: sideBarLightColor,
//       appName: appName,
//       sideBarAsset: sideBarAsset(context),
//       width: isCollapsed ? sideBarCollapsedWidth : sideBarWidth,
//       logoWidget: logoWidget(context),
//       footerWidget: footerWidget(context),
//       logoFontSize: logoFontSize,
//       // isCollapsed: isCollapsed,
//       isCollapsible: isSidebarCollapsible,
//       // pinnedNotifier: _sidebarPinnedNotifier,
//     );
//   }

//   Widget rightContentWidget(BuildContext context) {
//     Widget contentWidget = Column(
//       children: [
//         if (showTitle && breakTabTitle(context).isNotEmpty)
//           SizedBox(
//             height: 50,
//             child: breakTabWidget(context) ??
//                 BreakTab(
//                   breakTabTitle(context),
//                   rightWidget: breakTabRightWidget(context),
//                 ),
//           ),
//         if (showTitle) const SizedBox(height: 10),
//         isContentScroll
//             ? ScreenTypeLayout.builder(
//                 desktop: contentDesktopWidget,
//                 mobile: contentMobileWidget,
//                 tablet: contentMobileWidget,
//               )
//             : Expanded(
//                 child: ScreenTypeLayout.builder(
//                   desktop: contentDesktopWidget,
//                   mobile: contentMobileWidget,
//                   tablet: contentMobileWidget,
//                 ),
//               ),
//       ],
//     );

//     return Column(
//       children: [
//         if (showToolBar(context))
//           ToolBarWidget(
//                 showMore: showDrawer,
//                 showChangeTheme: true, // Add this to show theme switch
//                 userInfoWidget: CircleAvatar(
//                   backgroundImage: AssetImage('assets/user/user-01.png'),
//                   radius: 22,
//                 ),
//               ) ??
//               const SizedBox.shrink(),
//         if (showToolBar(context)) const SizedBox(height: 0),
//         Expanded(
//           child: Container(
//             width: double.maxFinite,
//             height: double.maxFinite,
//             alignment: isAlignCenter ? Alignment.center : null,
//             padding: customPadding ?? padding,
//             child: isContentScroll
//                 ? SingleChildScrollView(child: contentWidget)
//                 : contentWidget,
//           ),
//         ),
//       ],
//     );
//   }
// }
