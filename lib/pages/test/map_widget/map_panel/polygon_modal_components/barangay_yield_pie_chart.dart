import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flareline/core/models/yield_model.dart';

enum LegendPosition {
  right, // Default - vertical on the right
  bottom, // Horizontal at the bottom
  horizontal // Horizontal beside the chart
}

class BarangayYieldPieChart extends StatefulWidget {
  final List<Yield> yields;
  final bool showByVolume;
  final String? selectedYear;
  final LegendPosition legendPosition;

  const BarangayYieldPieChart({
    super.key,
    required this.yields,
    this.showByVolume = true,
    this.selectedYear,
    this.legendPosition = LegendPosition.right,
  });

  @override
  State<BarangayYieldPieChart> createState() => _BarangayYieldPieChartState();
}

class _BarangayYieldPieChartState extends State<BarangayYieldPieChart>
    with TickerProviderStateMixin {
  late AnimationController _pieAnimationController;
  late AnimationController _legendAnimationController;
  late AnimationController _scaleAnimationController;
  late Animation<double> _pieAnimation;
  late Animation<double> _legendAnimation;
  late Animation<double> _scaleAnimation;

  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _pieAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _legendAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Create animations
    _pieAnimation = CurvedAnimation(
      parent: _pieAnimationController,
      curve: Curves.easeOutCubic,
    );

    _legendAnimation = CurvedAnimation(
      parent: _legendAnimationController,
      curve: Curves.easeOutQuart,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleAnimationController,
      curve: Curves.elasticOut,
    );

    // Start animations
    _startAnimations();
  }

  void _startAnimations() {
    _pieAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _legendAnimationController.forward();
      }
    });
  }

  @override
  void didUpdateWidget(BarangayYieldPieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Restart animations when data changes
    if (oldWidget.yields != widget.yields ||
        oldWidget.showByVolume != widget.showByVolume ||
        oldWidget.selectedYear != widget.selectedYear) {
      _pieAnimationController.reset();
      _legendAnimationController.reset();
      _startAnimations();
    }
  }

  @override
  void dispose() {
    _pieAnimationController.dispose();
    _legendAnimationController.dispose();
    _scaleAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final distributionData = _calculateDistribution();

    if (distributionData.isEmpty) {
      return Container(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 64,
                color: theme.hintColor,
              ),
              const SizedBox(height: 16),
              Text(
                'No data available',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: widget.legendPosition == LegendPosition.bottom ? 600 : 500,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnimatedHeader(theme),
          const SizedBox(height: 20),
          Expanded(
            child: _buildChartWithLegend(distributionData, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedHeader(ThemeData theme) {
    return AnimatedBuilder(
      animation: _legendAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _legendAnimation.value)),
          child: Opacity(
            opacity: _legendAnimation.value,
            child: Row(
              children: [
                Icon(
                  Icons.pie_chart,
                  color: theme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Yield Distribution ${widget.showByVolume ? '(by Volume)' : '(by Productivity)'}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.selectedYear != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.selectedYear!,
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChartWithLegend(
      Map<String, ProductDistribution> distributionData, ThemeData theme) {
    final pieChart = AnimatedBuilder(
      animation: _pieAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.3 + (0.7 * _pieAnimation.value),
          child: Opacity(
            opacity: _pieAnimation.value,
            child: PieChart(
              PieChartData(
                sections: _buildPieChartSections(distributionData, theme),
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                startDegreeOffset: -90,
                borderData: FlBorderData(show: false),
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        _scaleAnimationController.reverse();
                        return;
                      }
                      touchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                      _scaleAnimationController.forward();
                    });
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    switch (widget.legendPosition) {
      case LegendPosition.right:
        return Row(
          children: [
            Expanded(
              flex: 3,
              child: pieChart,
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: _buildVerticalLegend(distributionData, theme),
            ),
          ],
        );

      case LegendPosition.horizontal:
        return Row(
          children: [
            Expanded(
              flex: 2,
              child: pieChart,
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 3,
              child: _buildHorizontalLegend(distributionData, theme),
            ),
          ],
        );

      case LegendPosition.bottom:
        return Column(
          children: [
            Expanded(
              flex: 3,
              child: pieChart,
            ),
            const SizedBox(height: 20),
            Expanded(
              flex: 2,
              child: _buildHorizontalLegend(distributionData, theme),
            ),
          ],
        );
    }
  }

  Map<String, ProductDistribution> _calculateDistribution() {
    final distributionMap = <String, ProductDistribution>{};
    final filteredYields = widget.selectedYear != null
        ? widget.yields
            .where((y) => y.harvestDate.year.toString() == widget.selectedYear)
            .toList()
        : widget.yields;

    for (final yield in filteredYields) {
      final productName = yield.productName ?? 'Unknown';

      if (!distributionMap.containsKey(productName)) {
        distributionMap[productName] = ProductDistribution(
          productName: productName,
          totalVolume: 0,
          totalAreaHarvested: 0,
          recordCount: 0,
          productImage: yield.productImage,
        );
      }

      distributionMap[productName]!.totalVolume += yield.volume;
      distributionMap[productName]!.totalAreaHarvested +=
          yield.areaHarvested ?? 0;
      distributionMap[productName]!.recordCount += 1;
    }

    // Sort by volume or productivity depending on showByVolume flag
    final sortedEntries = distributionMap.entries.toList()
      ..sort((a, b) => widget.showByVolume
          ? b.value.totalVolume.compareTo(a.value.totalVolume)
          : b.value.productivity.compareTo(a.value.productivity));

    return Map.fromEntries(sortedEntries);
  }

  List<PieChartSectionData> _buildPieChartSections(
    Map<String, ProductDistribution> data,
    ThemeData theme,
  ) {
    final total = widget.showByVolume
        ? data.values.fold<double>(0, (sum, item) => sum + item.totalVolume)
        : data.values.fold<double>(0, (sum, item) => sum + item.productivity);

    final colors = _generateColors(data.length);
    final sections = <PieChartSectionData>[];

    int colorIndex = 0;
    for (final entry in data.entries) {
      final value = widget.showByVolume
          ? entry.value.totalVolume
          : entry.value.productivity;
      final percentage = (value / total * 100);
      final isTouched = colorIndex == touchedIndex;

      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: value * _pieAnimation.value, // Animated value
          title: percentage > 5 ? '${percentage.toStringAsFixed(1)}%' : '',
          radius: isTouched ? 90 : 80, // Expand on touch
          titleStyle: TextStyle(
            fontSize: isTouched ? 14 : 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: isTouched
                ? [
                    const Shadow(
                      color: Colors.black26,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ]
                : null,
          ),
          badgeWidget: percentage <= 5
              ? null
              : _buildAnimatedBadge(entry.value, theme, isTouched),
          badgePositionPercentageOffset: isTouched ? 1.4 : 1.3,
        ),
      );
      colorIndex++;
    }

    return sections;
  }

  Widget? _buildAnimatedBadge(
      ProductDistribution product, ThemeData theme, bool isTouched) {
    if (product.productImage != null) {
      return AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          final scale = isTouched ? 1.0 + (0.3 * _scaleAnimation.value) : 1.0;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: isTouched ? 3 : 2,
                ),
                boxShadow: isTouched
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
                image: DecorationImage(
                  image: NetworkImage(product.productImage!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      );
    }
    return null;
  }

  Widget _buildVerticalLegend(
      Map<String, ProductDistribution> data, ThemeData theme) {
    final colors = _generateColors(data.length);
    final total = widget.showByVolume
        ? data.values.fold<double>(0, (sum, item) => sum + item.totalVolume)
        : data.values.fold<double>(0, (sum, item) => sum + item.productivity);

    return AnimatedBuilder(
      animation: _legendAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - _legendAnimation.value), 0),
          child: Opacity(
            opacity: _legendAnimation.value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Products',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      return _buildAnimatedLegendItem(
                        data.entries.elementAt(index),
                        colors[index % colors.length],
                        total,
                        index,
                        theme,
                        false,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHorizontalLegend(
      Map<String, ProductDistribution> data, ThemeData theme) {
    final colors = _generateColors(data.length);
    final total = widget.showByVolume
        ? data.values.fold<double>(0, (sum, item) => sum + item.totalVolume)
        : data.values.fold<double>(0, (sum, item) => sum + item.productivity);

    return AnimatedBuilder(
      animation: _legendAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _legendAnimation.value)),
          child: Opacity(
            opacity: _legendAnimation.value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Products',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          widget.legendPosition == LegendPosition.bottom
                              ? 3
                              : 2,
                      childAspectRatio:
                          widget.legendPosition == LegendPosition.bottom
                              ? 3.5
                              : 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      return _buildAnimatedLegendItem(
                        data.entries.elementAt(index),
                        colors[index % colors.length],
                        total,
                        index,
                        theme,
                        true,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedLegendItem(
    MapEntry<String, ProductDistribution> entry,
    Color color,
    double total,
    int index,
    ThemeData theme,
    bool isCompact,
  ) {
    final product = entry.value;
    final value =
        widget.showByVolume ? product.totalVolume : product.productivity;
    final percentage = (value / total * 100);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, animationValue, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animationValue)),
          child: Opacity(
            opacity: animationValue,
            child: isCompact
                ? _buildCompactLegendItem(product, color, percentage, theme)
                : _buildFullLegendItem(product, color, percentage, theme),
          ),
        );
      },
    );
  }

  Widget _buildFullLegendItem(
    ProductDistribution product,
    Color color,
    double percentage,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.showByVolume
                          ? '${product.totalVolume.toStringAsFixed(1)} kg'
                          : '${product.productivity.toStringAsFixed(1)} kg/ha',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLegendItem(
    ProductDistribution product,
    Color color,
    double percentage,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  product.productName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                    fontSize: 10,
                  ),
                ),
                Text(
                  widget.showByVolume
                      ? '${product.totalVolume.toStringAsFixed(1)} kg'
                      : '${product.productivity.toStringAsFixed(1)} kg/ha',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _generateColors(int count) {
    return [
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF10B981), // Green
      const Color(0xFFF59E0B), // Yellow
      const Color(0xFFEF4444), // Red
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFF97316), // Orange
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFEC4899), // Pink
      const Color(0xFF84CC16), // Lime
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF14B8A6), // Teal
      const Color(0xFFFBBF24), // Amber
    ];
  }
}

class ProductDistribution {
  final String productName;
  double totalVolume;
  double totalAreaHarvested;
  int recordCount;
  final String? productImage;

  ProductDistribution({
    required this.productName,
    required this.totalVolume,
    required this.totalAreaHarvested,
    required this.recordCount,
    this.productImage,
  });

  double get productivity {
    if (totalAreaHarvested <= 0) return 0.0;
    return totalVolume / totalAreaHarvested;
  }
}
