import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';

import 'package:flareline/pages/sectors/sector_line_Chart.dart';
import 'package:flareline/pages/sectors/sector_bar_Chart.dart';

class RevenueWidget extends StatelessWidget {
  const RevenueWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return _revenueWidget();
  }

  Widget _revenueWidget() {
    return ScreenTypeLayout.builder(
      desktop: _revenueWidgetDesktop,
      mobile: _revenueWidgetMobile,
      tablet: _revenueWidgetMobile,
    );
  }

  Widget _revenueWidgetDesktop(BuildContext context) {
    return SizedBox(
      height: 500,
      child: Row(
        children: [
          Expanded(
            child: SectorLineChart(),
            flex: 2,
          ),
          const SizedBox(
            width: 16,
          ),
          Expanded(
            child: SectorBarChart(),
            flex: 1,
          ),
        ],
      ),
    );
  }

  Widget _revenueWidgetMobile(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 600,
          child: SectorLineChart(),
        ),
        const SizedBox(
          height: 16,
        ),
        SizedBox(
          height: 460,
          child: SectorBarChart(),
        ),
      ],
    );
  }
}
