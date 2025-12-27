 
import 'package:flareline/pages/users/DAProfile/profile_info_card.dart';
import 'package:flareline/pages/users/DAProfile/stats_card.dart';
import 'package:flutter/material.dart';
import 'package:flareline/pages/layout.dart'; 
import 'package:responsive_builder/responsive_builder.dart';

class DAOfficerProfile extends LayoutWidget {
  final Map<String, dynamic> daUser;

  const DAOfficerProfile({super.key, required this.daUser});

  @override
  String breakTabTitle(BuildContext context) {
    return 'Profile';
  }

  @override
  Widget contentDesktopWidget(BuildContext context) {
    return ScreenTypeLayout.builder(
      desktop: _desktopWidget,
      mobile: _mobileWidget,
      tablet: _mobileWidget,
    );
  }

  Widget _desktopWidget(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ProfileHeader(user: daUser),
            // const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: UserInfoCard(user: daUser),
                  flex: 2,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatsCard(user: daUser),
                  flex: 1,
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobileWidget(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // ProfileHeader(user: daUser, isMobile: true),
            // const SizedBox(height: 16),
            UserInfoCard(user: daUser, isMobile: true),
            const SizedBox(height: 16),
            StatsCard(user: daUser, isMobile: true),
          ],
        ),
      ),
    );
  }
}