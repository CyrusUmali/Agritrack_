import 'package:flareline/core/models/assocs_model.dart';
import 'package:flutter/material.dart';
import 'package:flareline/services/lanugage_extension.dart';

class AssocKpiCards extends StatelessWidget {
  final Association association;
  final bool isMobile;

  const AssocKpiCards({
    super.key,
    required this.association,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    // print('sectorcurrent');
    // print(sector);

    print(association.totalFarms);
    return isMobile ? _buildMobileGrid(context) : _buildDesktopRow(context);
  }

  Widget _buildMobileGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: _buildAllCards(context),
    );
  }

  Widget _buildDesktopRow(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _buildAllCards(context)
            .map((card) => Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 200,
                    height: 160,
                    child: card,
                  ),
                ))
            .toList(),
      ),
    );
  }

  List<Widget> _buildAllCards(BuildContext context) {
    // Access stats from the nested object

    return [
      _buildKpiCard(
        context,
        title: context.translate('Total Farms'),
        value: association.totalFarms?.toString() ?? 'N/A',
        icon: Icons.agriculture,
      ),
      _buildKpiCard(
        context,
        title: context.translate('Total Farmers'),
        value: association.totalMembers?.toString() ?? 'N/A',
        icon: Icons.people,
      ),
      _buildKpiCard(
        context,
        title: context.translate('Avg Farm Size'),
        value: association.avgFarmSize != null
            ? '${association.avgFarmSize} ha'
            : 'N/A',
        icon: Icons.landscape,
      ),
      _buildKpiCard(
        context,
        title: context.translate('Annual Yield'),
        value: association.volume != null ? '${association.volume} kg' : 'N/A',
        icon: Icons.assessment,
      ),
      _buildKpiCard(
        context,
        title: context.translate('Area Harvested'),
        value: association.areaHarvested != null
            ? '${association.areaHarvested} ha'
            : 'N/A',
        icon: Icons.area_chart,
      ),
      _buildKpiCard(
        context,
        title: context.translate('Annual Production'),
        value: association.production != null
            ? '${association.production} mt'
            : 'N/A',
        icon: Icons.assessment,
      ),
    ];
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    bool isPositive = true,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 80,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
