import 'package:flareline/pages/flareline_layout.dart';
import 'package:flareline/pages/toolbar.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flareline/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

abstract class LayoutWidget extends FlarelineLayoutWidget {
  const LayoutWidget({super.key});

  @override
  String sideBarAsset(BuildContext context) {
    // Remove listen: false to listen for changes
    final userProvider = Provider.of<UserProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    final role = userProvider.user?.role ?? 'guest';
    final languageCode = languageProvider.currentLanguageCode;

    // Combine role and language for the asset path
    return 'assets/routes/menu_route_${role}_$languageCode.json';
  }

  @override
  Widget? toolbarWidget(BuildContext context, bool showDrawer) {
    return ToolBarWidget(
      showMore: showDrawer,
      showChangeTheme: true,
      userInfoWidget: _userInfoWidget(context),
    );
  }

  Widget _userInfoWidget(BuildContext context) {
    return const Row(
      children: [
        Column(
          children: [
            // Text('Demo'),
          ],
        ),
        SizedBox(
          width: 10,
        ),
        CircleAvatar(
          backgroundImage: AssetImage('assets/user/user-01.png'),
          radius: 22,
        )
      ],
    );
  }
}