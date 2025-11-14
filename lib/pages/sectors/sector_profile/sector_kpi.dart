import 'package:flutter/material.dart';
import 'package:flareline/services/lanugage_extension.dart';

class SectorKpiCards extends StatelessWidget {
  final Map<String, dynamic> sector;
  final bool isMobile;

  const SectorKpiCards({
    super.key,
    required this.sector,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    // print('sectorcurrent');
    // print(sector);
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
    final stats = sector['stats'] ?? {};

    // Calculate growth percentage if annual yield data exists
    double? growthPercent;
    final annualYield = sector['annualYield'] as List?;
    if (annualYield != null && annualYield.length >= 2) {
      final currentYear = annualYield[0]['totalVolume'] as int?;
      final previousYear = annualYield[1]['totalVolume'] as int?;
      if (currentYear != null && previousYear != null && previousYear != 0) {
        growthPercent = ((currentYear - previousYear) / previousYear) * 100;
      }
    }

    return [
      _buildKpiCard(
        context,
        title: context.translate('Total Farms'),
        value: stats['totalFarms']?.toString() ?? 'N/A',
        icon: Icons.agriculture,
      ),
      _buildKpiCard(
        context,
        title: context.translate('Total Farmers'),
        value: stats['totalFarmers']?.toString() ?? 'N/A',
        icon: Icons.people,
      ),
      _buildKpiCard(
        context,
        title: context.translate('Avg Farm Size'),
        value:
            stats['avgFarmSize'] != null ? '${stats['avgFarmSize']} ha' : 'N/A',
        icon: Icons.landscape,
      ),
      _buildKpiCard(
        context,
        title: context.translate('Annual Yield'),
        value: stats['totalYieldVolume'] != null
            ? '${stats['totalYieldVolume']} kg'
            : 'N/A',
        icon: Icons.assessment,
      ),
      _buildKpiCard(
        context,
        title: context.translate('Growth %'),
        value: growthPercent != null
            ? '${growthPercent.toStringAsFixed(1)}%'
            : 'N/A',
        icon: growthPercent != null && growthPercent > 0
            ? Icons.trending_up
            : Icons.trending_down,
        isPositive: growthPercent != null && growthPercent > 0,
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
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                if (title == 'Growth %')
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive ? Icons.trending_up : Icons.trending_down,
                          size: 14,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPositive ? 'Up' : 'Down',
                          style: TextStyle(
                            fontSize: 12,
                            color: isPositive ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
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
