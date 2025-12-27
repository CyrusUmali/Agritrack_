import 'package:flareline/pages/recommendation/suitability/widgets/suitabillity_helper.dart';
import 'package:flutter/material.dart';
import 'package:flareline/services/lanugage_extension.dart'; 
class ParameterAnalysisCard extends StatelessWidget {
  final Map<String, dynamic> parametersAnalysis;
  final double parameterConfidence; 
  final bool isSmallScreen;
  final double padding;

  const ParameterAnalysisCard({
    super.key,
    required this.parametersAnalysis,
    required this.isSmallScreen,
    required this.padding,
     required this.parameterConfidence,
  });

  @override
  Widget build(BuildContext context) {
    final optimalCount = parametersAnalysis.entries
        .where((e) => e.value['status'] == 'optimal')
        .length;
    final totalCount = parametersAnalysis.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

     final int percentage = (parameterConfidence * 100).round();

    // Define parameter order
    final List<String> parameterOrder = [
      'soil_ph',
      'humidity',
      'fertility_ec',
      'soil_temp',
      'soil_moisture',
      'sunlight',
    ];

    // Sort entries
    final sortedEntries = parametersAnalysis.entries.toList()
      ..sort((a, b) {
        final indexA = parameterOrder.indexOf(a.key);
        final indexB = parameterOrder.indexOf(b.key);
        if (indexA == -1) return 1;
        if (indexB == -1) return -1;
        return indexA.compareTo(indexB);
      });

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).cardTheme.color,
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.blue[900]!.withOpacity(0.3)
                        : Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.analytics,
                    color: isDark ? Colors.blue[300] : Colors.blue[600],
                    size: isSmallScreen ? 18 : 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  context.translate('Parameter Analysis'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[200] : Colors.grey[800],
                        fontSize: isSmallScreen ? 18 : 20,
                      ),
                ),
                const Spacer(),
             
             
             
              Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: SuitabilityHelpers.getOverallScoreColor(parameterConfidence)
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SuitabilityHelpers.getOverallScoreColor(parameterConfidence),
        ),
      ),
      child: Text(
        '$percentage%',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: SuitabilityHelpers.getOverallScoreColor(parameterConfidence),
          fontSize: isSmallScreen ? 14 : 16,
        ),
      ),
    ),
             
              ],
            ),

            SizedBox(height: isSmallScreen ? 16 : 20),

            Text(
              '$optimalCount of $totalCount ${context.translate('parameters optimal')}',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),

            SizedBox(height: isSmallScreen ? 16 : 20),

            // Parameters grid/list
            if (isSmallScreen)
              // Mobile: Single column
              Column(
                children: sortedEntries
                    .map((entry) => ParameterCard(
                          parameter: entry.key,
                          current: (entry.value['current'] as num).toDouble(),
                          min: (entry.value['ideal_min'] as num).toDouble(),
                          max: (entry.value['ideal_max'] as num).toDouble(),
                          status: entry.value['status'],
                          isSmallScreen: isSmallScreen,
                        ))
                    .toList(),
              )
            else
              // Desktop: Two-column grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 3.3,
                ),
                itemCount: sortedEntries.length,
                itemBuilder: (context, index) {
                  final entry = sortedEntries[index];
                  return ParameterCard(
                    parameter: entry.key,
                    current: (entry.value['current'] as num).toDouble(),
                    min: (entry.value['ideal_min'] as num).toDouble(),
                    max: (entry.value['ideal_max'] as num).toDouble(),
                    status: entry.value['status'],
                    isSmallScreen: false,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class ParameterCard extends StatelessWidget {
  final String parameter;
  final double current;
  final double min;
  final double max;
  final String status;
  final bool isSmallScreen;

  const ParameterCard({
    super.key,
    required this.parameter,
    required this.current,
    required this.min,
    required this.max,
    required this.status,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = SuitabilityHelpers.getStatusInfo(
        status, Theme.of(context).brightness);
    final progressValue =
        SuitabilityHelpers.calculateProgressValue(current, min, max);
    final progressColor =
        SuitabilityHelpers.getProgressBarColor(current, min, max);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusInfo.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusInfo.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(
                SuitabilityHelpers.getParameterIcon(parameter),
                color: statusInfo.color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  SuitabilityHelpers.formatParameterName(parameter),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 15 : 16,
                    color: isDark ? Colors.grey[200] : Colors.grey[800],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusInfo.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusInfo.color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Current value display
          Row(
            children: [
              Text(
                context.translate('Current: '),
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              Text(
                '${current.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: isSmallScreen ? 15 : 16,
                  fontWeight: FontWeight.bold,
                  color: statusInfo.color,
                ),
              ),
              Text(
                ' (${min.toStringAsFixed(1)}-${max.toStringAsFixed(1)})',
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Progress bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progressValue,
              child: Container(
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}