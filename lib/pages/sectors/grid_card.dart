import 'package:flareline/core/theme/global_colors.dart';
import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:responsive_builder/responsive_builder.dart';

import 'package:iconify_flutter_plus/iconify_flutter_plus.dart';
import 'package:iconify_flutter_plus/icons/mdi.dart';

class SectorsGridCard extends StatelessWidget {
  const SectorsGridCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout.builder(
      desktop: (context) => contentDesktopWidget(context),
      mobile: (context) => contentMobileWidget(context),
      tablet: (context) => contentMobileWidget(context),
    );
  }

  Widget contentDesktopWidget(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _itemCardWidget(
                context,
                const Iconify(Mdi.rice),
                '120 Farmers',
                '10,000 ha',
                '85%',
                true,
                DeviceScreenType.desktop)),
        const SizedBox(width: 14),
        Expanded(
            child: _itemCardWidget(
                context,
                const Iconify(Mdi.corn),
                '90 Farmers',
                '8,500 ha',
                '78%',
                true,
                DeviceScreenType.desktop)),
        const SizedBox(width: 16),
        Expanded(
            child: _itemCardWidget(context, const Iconify(Mdi.cow),
                '100 Farmers', 'N/A', '90%', true, DeviceScreenType.desktop)),
        const SizedBox(width: 16),
        Expanded(
            child: _itemCardWidget(
                context,
                const Iconify(Mdi.leaf),
                '35 Farmers',
                '5,200 ha',
                '88%',
                true,
                DeviceScreenType.desktop)),
        const SizedBox(width: 16),
        Expanded(
            child: _itemCardWidget(
                context,
                const Iconify(Mdi.fish),
                '60 Farmers',
                '15,000 ha',
                '82%',
                true,
                DeviceScreenType.desktop)),
        const SizedBox(width: 16),
        Expanded(
            child: _itemCardWidget(
                context,
                const Iconify(Mdi.fruit_grapes_outline),
                '50 Farmers',
                '7,300 ha',
                '87%',
                true,
                DeviceScreenType.desktop)),
      ],
    );
  }

  Widget contentMobileWidget(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: [
        _itemCardWidget(context, const Iconify(Mdi.rice), '120 Farmers',
            '10,000 ha', '85%', true, DeviceScreenType.mobile),
        _itemCardWidget(context, const Iconify(Mdi.corn), '90 Farmers',
            '8,500 ha', '78%', true, DeviceScreenType.mobile),
        _itemCardWidget(context, const Iconify(Mdi.cow), '100 Farmers', 'N/A',
            '90%', true, DeviceScreenType.mobile),
        _itemCardWidget(context, const Iconify(Mdi.leaf), '35 Farmers',
            '5,200 ha', '88%', true, DeviceScreenType.mobile),
        _itemCardWidget(context, const Iconify(Mdi.fish), '60 Farmers',
            '15,000 ha', '82%', true, DeviceScreenType.mobile),
        _itemCardWidget(context, const Iconify(Mdi.fruit_grapes_outline),
            '50 Farmers', '7,300 ha', '87%', true, DeviceScreenType.mobile),
      ],
    );
  }

  _itemCardWidget(
      BuildContext context,
      Widget icon,
      String farmers,
      String landCovered,
      String performance,
      bool isGrow,
      DeviceScreenType screenType) {
    double farmersTextSize = screenType == DeviceScreenType.desktop ? 12 : 7;
    double landCoveredTextSize =
        screenType == DeviceScreenType.desktop ? 12 : 10;
    double performanceTextSize =
        screenType == DeviceScreenType.desktop ? 12 : 10;

    return CommonCard(
      height: 180,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipOval(
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                color: Colors.grey.shade200,
                child: icon,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              farmers,
              style: TextStyle(
                  fontSize: farmersTextSize, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            if (landCovered.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                landCovered,
                style: TextStyle(
                    fontSize: landCoveredTextSize, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Production:",
                  style: TextStyle(
                      fontSize: performanceTextSize, color: Colors.green),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
                const Spacer(),
                Text(
                  performance,
                  style: TextStyle(
                    fontSize: performanceTextSize,
                    color: isGrow ? Colors.green : Colors.lightBlue,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  isGrow ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isGrow ? Colors.green : Colors.lightBlue,
                  size: 12,
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
