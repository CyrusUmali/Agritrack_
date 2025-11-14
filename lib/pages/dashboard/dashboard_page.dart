import 'package:flareline/core/models/user_model.dart';
import 'package:flareline/pages/dashboard/analytics_widget.dart';
import 'package:flareline/pages/dashboard/channel_widget.dart';
import 'package:flareline/pages/dashboard/grid_card.dart';
import 'package:flareline/pages/dashboard/map/map_chart_widget.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flareline_uikit/service/year_picker_provider.dart';
import 'package:flutter/material.dart';
import 'package:flareline/pages/layout.dart';
import 'package:provider/provider.dart';
import 'package:flareline/providers/user_provider.dart';
import 'revenue_widget.dart';

class Dashboard extends LayoutWidget {
  const Dashboard({super.key});

  @override
  String breakTabTitle(BuildContext context) {
    return 'Home';
  }

  // Helper method to check if user is a farmer
  bool _isFarmer(UserModel? user) {
    return user?.role?.toLowerCase() == 'farmer';
  }

  @override
  Widget contentDesktopWidget(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final isFarmer = _isFarmer(user);

    return Column(
      children: [
        Consumer<YearPickerProvider>(
          builder: (context, yearProvider, child) {
            return GridCard(selectedYear: yearProvider.selectedYear);
          },
        ),

        const SizedBox(height: 16),

        // Show AnalyticsWidget for all roles including farmers
        Consumer<YearPickerProvider>(
          builder: (context, yearProvider, child) {
            return AnalyticsWidget(selectedYear: yearProvider.selectedYear);
          },
        ),

        const SizedBox(height: 30),

        // Show RevenueWidget for all roles except farmers
        if (!isFarmer) const RevenueWidget(),
        if (!isFarmer) const SizedBox(height: 20),

        // Show ChannelWidget for all roles except farmers
        if (!isFarmer) ChannelWidget(),
        if (!isFarmer) const SizedBox(height: 30),

        Consumer<YearPickerProvider>(
          builder: (context, yearProvider, child) {
            return SizedBox(
              height: 700,
              child: CommonCard(
                child: ConstrainedBox(
                  constraints: const BoxConstraints.expand(),
                  child:
                      MapChartWidget(selectedYear: yearProvider.selectedYear),
                ),
              ),
            );
          },
        ),
      

      const SizedBox(height: 10),
      
      ],
    );
  }

  @override
  Widget contentMobileWidget(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final isFarmer = _isFarmer(user);

    return Column(
      children: [
        Consumer<YearPickerProvider>(
          builder: (context, yearProvider, child) {
            return GridCard(selectedYear: yearProvider.selectedYear);
          },
        ),
        const SizedBox(height: 16),
        Consumer<YearPickerProvider>(
          builder: (context, yearProvider, child) {
            return AnalyticsWidget(selectedYear: yearProvider.selectedYear);
          },
        ),
        const SizedBox(height: 30),

        // Show RevenueWidget for all roles except farmers
        if (!isFarmer) const RevenueWidget(),
        if (!isFarmer) const SizedBox(height: 20),

        // Show ChannelWidget for all roles except farmers
        if (!isFarmer) ChannelWidget(),
        if (!isFarmer) const SizedBox(height: 30),

        Consumer<YearPickerProvider>(
          builder: (context, yearProvider, child) {
            return SizedBox(
              height: 800, 
              child: CommonCard(
                child: ConstrainedBox(
                  constraints: const BoxConstraints.expand(),
                  child:
                      MapChartWidget(selectedYear: yearProvider.selectedYear),
                ),
              ),
            );
          },
        ),
      ],
    );
  }


}
