library flareline_uikit;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flareline_uikit/service/sidebar_provider.dart';
import 'package:flareline_uikit/service/year_picker_provider.dart';
import 'package:flareline_uikit/service/theme_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:responsive_builder/responsive_builder.dart';

class ToolBarWidget extends StatelessWidget {
  final bool? showMore;
  final bool? showChangeTheme;
  final Widget? userInfoWidget;

  const ToolBarWidget({
    super.key,
    this.showMore,
    this.showChangeTheme,
    this.userInfoWidget,
  });

  @override
  Widget build(BuildContext context) {
    return _toolsBarWidget(context);
  }

  Widget _toolsBarWidget(BuildContext context) {
    final sidebarProvider =
        Provider.of<SidebarProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Container(
      color: Theme.of(context).appBarTheme.backgroundColor,
      padding: const EdgeInsets.all(10),
      child: Row(children: [
        ResponsiveBuilder(
          builder: (context, sizingInformation) {
            final showMoreButton = (showMore ?? false) ||
                sizingInformation.deviceScreenType != DeviceScreenType.desktop;

            // Automatically pin the sidebar when the more button is shown
            if (showMoreButton) {
              final provider =
                  Provider.of<SidebarProvider>(context, listen: false);
              if (!provider.isPinned) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  provider.togglePin(); // Ensure sidebar is pinned
                });
              }
            }

            return Row(
              children: [
                if (!showMoreButton) // Show toggle button when not showing more button
                  InkWell(
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Colors.grey.shade200, width: 1),
                        color: Colors.transparent,
                      ),
                      child: Icon(
                        Icons.menu,
                      ),
                    ),
                    onTap: () {
                      final provider =
                          Provider.of<SidebarProvider>(context, listen: false);
                      provider.togglePin();
                      if (kDebugMode) {}
                    },
                  ),
                if (showMoreButton) // Show more button when appropriate
                  InkWell(
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Colors.grey.shade200, width: 1),
                      ),
                      child: const Icon(Icons.more_vert),
                    ),
                    onTap: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
              ],
            );
          },
        ),

        const Spacer(),

        // Year Picker with toggle-like styling
        const YearPickerWidget(),

        const SizedBox(width: 10),

        // Theme toggle
        if (showChangeTheme ?? false)
          ToggleWidget(themeProvider: themeProvider),

        const SizedBox(width: 10),

        // User info
        if (userInfoWidget != null) userInfoWidget!,

        // User menu dropdown
        InkWell(
          child: Container(
            margin: const EdgeInsets.only(left: 6),
            child: const Icon(Icons.arrow_drop_down),
          ),
          onTap: () async {
            await showMenu(
              color: Colors.white,
              context: context,
              position: RelativeRect.fromLTRB(
                  MediaQuery.of(context).size.width - 100, 80, 0, 0),
              items: <PopupMenuItem<String>>[
                PopupMenuItem<String>(
                  value: 'profile',
                  child: const Text('My Profile'),
                  onTap: () => onProfileClick(context),
                ),
                PopupMenuItem<String>(
                  value: 'settings',
                  child: const Text('Settings'),
                  onTap: () {},
                ),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: const Text('Log out'),
                  onTap: () => onLogoutClick(context),
                ),
              ],
            );
          },
        ),
      ]),
    );
  }

  void onProfileClick(BuildContext context) {
    Navigator.of(context).pushNamed('/profile');
  }

  void onContactClick(BuildContext context) {
    Navigator.of(context).pushNamed('/contacts');
  }

  Future<void> onLogoutClick(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/signIn');
  }
}

class YearPickerWidget extends StatelessWidget {
  const YearPickerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final yearProvider = Provider.of<YearPickerProvider>(context);

    return InkWell(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        decoration: BoxDecoration(
          color: FlarelineColors.background,
          borderRadius: BorderRadius.circular(45),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.calendar_today,
                size: 16,
                color: FlarelineColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              yearProvider.selectedYear.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: FlarelineColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: FlarelineColors.primary,
            ),
          ],
        ),
      ),
      onTap: () => _showYearPicker(context),
    );
  }

  void _showYearPicker(BuildContext context) {
    final yearProvider =
        Provider.of<YearPickerProvider>(context, listen: false);
    final currentYear = DateTime.now().year;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Year'),
          backgroundColor: Colors.red,
          content: SizedBox(
            width: 300,
            height: 400,
            child: YearPicker(
              firstDate: DateTime(currentYear - 20),
              lastDate: DateTime(currentYear + 10),
              initialDate: DateTime(yearProvider.selectedYear),
              selectedDate: DateTime(yearProvider.selectedYear),
              onChanged: (DateTime dateTime) {
                yearProvider.setYear(dateTime.year);
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
    );
  }
}

class ToggleWidget extends StatelessWidget {
  final ThemeProvider themeProvider;

  const ToggleWidget({
    super.key,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = themeProvider.isDark;

    return InkWell(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 3),
        decoration: BoxDecoration(
          color: FlarelineColors.background,
          borderRadius: BorderRadius.circular(45),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: isDark ? Colors.transparent : Colors.white,
              child: SvgPicture.asset(
                'assets/toolbar/sun.svg',
                width: 18,
                height: 18,
                color: isDark
                    ? FlarelineColors.darkTextBody
                    : FlarelineColors.primary,
              ),
            ),
            CircleAvatar(
              radius: 15,
              backgroundColor: isDark ? Colors.white : Colors.transparent,
              child: SvgPicture.asset(
                'assets/toolbar/moon.svg',
                width: 18,
                height: 18,
                color: isDark
                    ? FlarelineColors.primary
                    : FlarelineColors.darkTextBody,
              ),
            ),
          ],
        ),
      ),
      onTap: () {
        themeProvider.toggleThemeMode();
      },
    );
  }
}
