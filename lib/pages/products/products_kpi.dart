import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:iconify_flutter_plus/iconify_flutter_plus.dart';
import 'package:iconify_flutter_plus/icons/mdi.dart';

import 'package:flareline/services/lanugage_extension.dart';

class FarmProductsKpi extends StatelessWidget {
  const FarmProductsKpi({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout.builder(
      desktop: (context) => _desktopLayout(context),
      mobile: (context) => _mobileLayout(context),
      tablet: (context) => _mobileLayout(context),
    );
  }

  Widget _desktopLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _buildKpiCard(
          context,
          const Iconify(Mdi.sack, color: Colors.orange),
          '12,450 t',
          context.translate('Total Production'),
          DeviceScreenType.desktop,
          Colors.orange[50]!,
        )),
        const SizedBox(width: 12),
        Expanded(
            child: _buildKpiCard(
          context,
          const Iconify(Mdi.trending_up, color: Colors.green),
          '+8.2%',
          'Annual Growth',
          DeviceScreenType.desktop,
          Colors.green[50]!,
        )),
        const SizedBox(width: 12),
        Expanded(
            child: _buildKpiCard(
          context,
          const Iconify(Mdi.warehouse, color: Colors.blue),
          '3,280 t',
          'In Storage',
          DeviceScreenType.desktop,
          Colors.blue[50]!,
        )),
        const SizedBox(width: 12),
        Expanded(
            child: _buildKpiCard(
          context,
          const Iconify(Mdi.truck_delivery, color: Colors.purple),
          '7,150 t',
          'This Season',
          DeviceScreenType.desktop,
          Colors.purple[50]!,
        )),
      ],
    );
  }

  Widget _mobileLayout(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildKpiCard(
          context,
          const Iconify(Mdi.sack, color: Colors.orange),
          '12,450 t',
          context.translate('Total Production'),
          DeviceScreenType.mobile,
          Colors.orange[50]!,
        ),
        _buildKpiCard(
          context,
          const Iconify(Mdi.trending_up, color: Colors.green),
          '+8.2%',
          context.translate('Annual Growth'),
          DeviceScreenType.mobile,
          Colors.green[50]!,
        ),
        _buildKpiCard(
          context,
          const Iconify(Mdi.warehouse, color: Colors.blue),
          '3,280 t',
          'In Storage',
          DeviceScreenType.mobile,
          Colors.blue[50]!,
        ),
        _buildKpiCard(
          context,
          const Iconify(Mdi.truck_delivery, color: Colors.purple),
          '7,150 t',
          'This Season',
          DeviceScreenType.mobile,
          Colors.purple[50]!,
        ),
      ],
    );
  }

  Widget _buildKpiCard(
    BuildContext context,
    Widget icon,
    String value,
    String title,
    DeviceScreenType screenType,
    Color iconBgColor,
  ) {
    final isDesktop = screenType == DeviceScreenType.desktop;

    return CommonCard(
      height: isDesktop ? 100 : 90,
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 16 : 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon Column
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: icon,
            ),
            const SizedBox(width: 12),

            // Content Column
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: isDesktop ? 16 : 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: isDesktop ? 20 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
