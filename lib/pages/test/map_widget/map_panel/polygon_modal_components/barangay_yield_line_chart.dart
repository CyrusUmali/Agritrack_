import 'package:flutter/material.dart';
import 'dart:math' as math;

enum LineChartDisplayMode { volume, yieldPerHa }

class MonthlyLineChart extends StatefulWidget {
  final String product;
  final int year;
  final Map<String, Map<String, double>> monthlyData;

  const MonthlyLineChart({
    super.key,
    required this.product,
    required this.year,
    required this.monthlyData,
  });

  @override
  State<MonthlyLineChart> createState() => _MonthlyLineChartState();
}

class _MonthlyLineChartState extends State<MonthlyLineChart>
    with TickerProviderStateMixin {
  LineChartDisplayMode _displayMode = LineChartDisplayMode.volume;
  late AnimationController _lineAnimationController;
  late AnimationController _switchAnimationController;
  late Animation<double> _lineAnimation;
  late Animation<double> _switchAnimation;

  Map<String, double> _previousData = {};
  Map<String, double> _currentData = {};

  @override
  void initState() {
    super.initState();

    // Animation controller for initial line drawing
    _lineAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Animation controller for switching between modes
    _switchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _lineAnimation = CurvedAnimation(
      parent: _lineAnimationController,
      curve: Curves.easeOut,
    );

    _switchAnimation = CurvedAnimation(
      parent: _switchAnimationController,
      curve: Curves.easeInOut,
    );

    _currentData = _getDisplayData();
    _lineAnimationController.forward();
  }

  @override
  void dispose() {
    _lineAnimationController.dispose();
    _switchAnimationController.dispose();
    super.dispose();
  }

  bool get _hasAreaData {
    return widget.monthlyData.values
        .any((data) => (data['areaHarvested'] ?? 0) > 0);
  }

  Map<String, double> _getDisplayData() {
    final displayData = <String, double>{};

    for (final entry in widget.monthlyData.entries) {
      final month = entry.key;
      final data = entry.value;
      final volume = data['volume'] ?? 0;
      final areaHarvested = data['areaHarvested'] ?? 0;

      if (_displayMode == LineChartDisplayMode.volume) {
        displayData[month] = volume;
      } else {
        final yieldPerHa = areaHarvested > 0 ? volume / areaHarvested : 0;
        displayData[month] = yieldPerHa.toDouble();
      }
    }

    return displayData;
  }

  void _switchDisplayMode(LineChartDisplayMode newMode) {
    if (newMode == _displayMode) return;

    setState(() {
      _previousData = Map.from(_currentData);
      _displayMode = newMode;
      _currentData = _getDisplayData();
    });

    _switchAnimationController.reset();
    _switchAnimationController.forward();
  }

  String _getUnit() {
    return _displayMode == LineChartDisplayMode.volume ? 'kg' : 'kg/ha';
  }

  String _getTitle() {
    final modeText = _displayMode == LineChartDisplayMode.volume
        ? 'Production'
        : 'Yield per Hectare';
    return '${widget.product} - Monthly $modeText (${widget.year})';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 450,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.show_chart,
                color: theme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _getTitle(),
                    key: ValueKey(_displayMode),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (_hasAreaData) _buildDisplayModeToggle(theme),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _currentData.isEmpty ||
                    _currentData.values.every((v) => v == 0)
                ? Center(
                    child: AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        _hasAreaData
                            ? 'No data available'
                            : _displayMode == LineChartDisplayMode.yieldPerHa
                                ? 'No area data available for yield calculation'
                                : 'No data available',
                        style: TextStyle(color: theme.hintColor),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : AnimatedBuilder(
                    animation:
                        Listenable.merge([_lineAnimation, _switchAnimation]),
                    builder: (context, child) {
                      return CustomPaint(
                        painter: LineChartPainter(
                          currentData: _currentData,
                          previousData: _previousData,
                          primaryColor: theme.primaryColor,
                          textColor:
                              theme.textTheme.bodyMedium?.color ?? Colors.black,
                          backgroundColor: theme.canvasColor,
                          isMonthly: true,
                          unit: _getUnit(),
                          lineAnimation: _lineAnimation.value,
                          switchAnimation: _switchAnimation.value,
                        ),
                        child: Container(),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayModeToggle(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
        color: theme.brightness == Brightness.dark
            ? theme.primaryColor.withOpacity(0.1)
            : Colors.grey.shade50,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            label: 'Volume',
            icon: Icons.inventory,
            isSelected: _displayMode == LineChartDisplayMode.volume,
            onTap: () => _switchDisplayMode(LineChartDisplayMode.volume),
            theme: theme,
          ),
          Container(
            width: 1,
            height: 28,
            color: theme.dividerColor,
          ),
          _buildToggleButton(
            label: 'Kg/Ha',
            icon: Icons.agriculture,
            isSelected: _displayMode == LineChartDisplayMode.yieldPerHa,
            onTap: () => _switchDisplayMode(LineChartDisplayMode.yieldPerHa),
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected
                ? theme.primaryColor.withOpacity(0.1)
                : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  size: 14,
                  color: isSelected
                      ? theme.primaryColor
                      : theme.iconTheme.color?.withOpacity(0.6),
                ),
              ),
              const SizedBox(width: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isSelected ? theme.primaryColor : null,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class YearlyLineChart extends StatefulWidget {
  final String product;
  final Map<String, Map<String, double>> yearlyData;

  const YearlyLineChart({
    super.key,
    required this.product,
    required this.yearlyData,
  });

  @override
  State<YearlyLineChart> createState() => _YearlyLineChartState();
}

class _YearlyLineChartState extends State<YearlyLineChart>
    with TickerProviderStateMixin {
  LineChartDisplayMode _displayMode = LineChartDisplayMode.volume;
  late AnimationController _lineAnimationController;
  late AnimationController _switchAnimationController;
  late Animation<double> _lineAnimation;
  late Animation<double> _switchAnimation;

  Map<String, double> _previousData = {};
  Map<String, double> _currentData = {};

  @override
  void initState() {
    super.initState();

    // Animation controller for initial line drawing
    _lineAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Animation controller for switching between modes
    _switchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _lineAnimation = CurvedAnimation(
      parent: _lineAnimationController,
      curve: Curves.easeOut,
    );

    _switchAnimation = CurvedAnimation(
      parent: _switchAnimationController,
      curve: Curves.easeInOut,
    );

    _currentData = _getDisplayData();
    _lineAnimationController.forward();
  }

  @override
  void dispose() {
    _lineAnimationController.dispose();
    _switchAnimationController.dispose();
    super.dispose();
  }

  bool get _hasAreaData {
    return widget.yearlyData.values
        .any((data) => (data['areaHarvested'] ?? 0) > 0);
  }

  Map<String, double> _getDisplayData() {
    final displayData = <String, double>{};

    for (final entry in widget.yearlyData.entries) {
      final year = entry.key;
      final data = entry.value;
      final volume = data['volume'] ?? 0;
      final areaHarvested = data['areaHarvested'] ?? 0;

      if (_displayMode == LineChartDisplayMode.volume) {
        displayData[year] = volume;
      } else {
        final yieldPerHa = areaHarvested > 0 ? volume / areaHarvested : 0;
        displayData[year] = yieldPerHa.toDouble();
      }
    }

    return displayData;
  }

  void _switchDisplayMode(LineChartDisplayMode newMode) {
    if (newMode == _displayMode) return;

    setState(() {
      _previousData = Map.from(_currentData);
      _displayMode = newMode;
      _currentData = _getDisplayData();
    });

    _switchAnimationController.reset();
    _switchAnimationController.forward();
  }

  String _getUnit() {
    return _displayMode == LineChartDisplayMode.volume ? 'kg' : 'kg/ha';
  }

  String _getTitle() {
    final modeText = _displayMode == LineChartDisplayMode.volume
        ? 'Production'
        : 'Yield per Hectare';
    return '${widget.product} - Yearly $modeText';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 450,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.show_chart,
                color: theme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _getTitle(),
                    key: ValueKey(_displayMode),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (_hasAreaData) _buildDisplayModeToggle(theme),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _currentData.isEmpty ||
                    _currentData.values.every((v) => v == 0)
                ? Center(
                    child: AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        _hasAreaData
                            ? 'No data available'
                            : _displayMode == LineChartDisplayMode.yieldPerHa
                                ? 'No area data available for yield calculation'
                                : 'No data available',
                        style: TextStyle(color: theme.hintColor),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : AnimatedBuilder(
                    animation:
                        Listenable.merge([_lineAnimation, _switchAnimation]),
                    builder: (context, child) {
                      return CustomPaint(
                        painter: LineChartPainter(
                          currentData: _currentData,
                          previousData: _previousData,
                          primaryColor: theme.primaryColor,
                          textColor:
                              theme.textTheme.bodyMedium?.color ?? Colors.black,
                          backgroundColor: theme.canvasColor,
                          isMonthly: false,
                          unit: _getUnit(),
                          lineAnimation: _lineAnimation.value,
                          switchAnimation: _switchAnimation.value,
                        ),
                        child: Container(),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayModeToggle(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
        color: theme.brightness == Brightness.dark
            ? theme.primaryColor.withOpacity(0.1)
            : Colors.grey.shade50,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            label: 'Volume',
            icon: Icons.inventory,
            isSelected: _displayMode == LineChartDisplayMode.volume,
            onTap: () => _switchDisplayMode(LineChartDisplayMode.volume),
            theme: theme,
          ),
          Container(
            width: 1,
            height: 28,
            color: theme.dividerColor,
          ),
          _buildToggleButton(
            label: 'Kg/Ha',
            icon: Icons.agriculture,
            isSelected: _displayMode == LineChartDisplayMode.yieldPerHa,
            onTap: () => _switchDisplayMode(LineChartDisplayMode.yieldPerHa),
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected
                ? theme.primaryColor.withOpacity(0.1)
                : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  size: 14,
                  color: isSelected
                      ? theme.primaryColor
                      : theme.iconTheme.color?.withOpacity(0.6),
                ),
              ),
              const SizedBox(width: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isSelected ? theme.primaryColor : null,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final Map<String, double> currentData;
  final Map<String, double> previousData;
  final Color primaryColor;
  final Color textColor;
  final Color backgroundColor;
  final bool isMonthly;
  final String unit;
  final double lineAnimation;
  final double switchAnimation;

  LineChartPainter({
    required this.currentData,
    required this.previousData,
    required this.primaryColor,
    required this.textColor,
    required this.backgroundColor,
    required this.isMonthly,
    required this.unit,
    required this.lineAnimation,
    required this.switchAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (currentData.isEmpty) return;

    // Interpolate between previous and current data for smooth transitions
    final Map<String, double> displayData = {};
    for (final key in currentData.keys) {
      final currentValue = currentData[key] ?? 0;
      final previousValue = previousData[key] ?? currentValue;

      // Use switchAnimation if we're transitioning between modes, otherwise use lineAnimation
      final animationValue =
          switchAnimation > 0 ? switchAnimation : lineAnimation;
      displayData[key] =
          previousValue + (currentValue - previousValue) * animationValue;
    }

    final linePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final pointPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = textColor.withOpacity(0.2)
      ..strokeWidth = 1;

    final textStyle = TextStyle(
      color: textColor,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    final labelTextStyle = TextStyle(
      color: textColor,
      fontSize: 10,
      fontWeight: FontWeight.w400,
    );

    // Chart dimensions
    const leftPadding = 70.0;
    const rightPadding = 20.0;
    const topPadding = 30.0;
    const bottomPadding = 40.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    // Find max value for scaling
    final maxValue = displayData.values.isNotEmpty
        ? displayData.values.reduce(math.max)
        : 1.0;
    final minValue = displayData.values.isNotEmpty
        ? displayData.values.reduce(math.min)
        : 0.0;
    final valueRange = maxValue - minValue;
    final adjustedMax =
        valueRange > 0 ? maxValue + (valueRange * 0.1) : maxValue + 1;

    // Sort data
    final sortedEntries = displayData.entries.toList();
    if (isMonthly) {
      final monthOrder = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
      sortedEntries.sort((a, b) {
        final aIndex = monthOrder.indexOf(a.key);
        final bIndex = monthOrder.indexOf(b.key);
        return aIndex.compareTo(bIndex);
      });
    } else {
      sortedEntries.sort((a, b) => a.key.compareTo(b.key));
    }

    // Draw Y-axis unit label with fade animation
    final unitOpacity = lineAnimation.clamp(0.0, 1.0);
    final unitPainter = TextPainter(
      text: TextSpan(
          text: '($unit)',
          style: textStyle.copyWith(
            fontSize: 10,
            color: textColor.withOpacity(unitOpacity),
          )),
      textDirection: TextDirection.ltr,
    );
    unitPainter.layout();
    canvas.save();
    canvas.translate(20, size.height / 2);
    canvas.rotate(-math.pi / 2);
    unitPainter.paint(canvas, Offset(-unitPainter.width / 2, 0));
    canvas.restore();

    // Draw grid lines and Y-axis labels with animation
    final gridLineCount = 5;
    for (int i = 0; i <= gridLineCount; i++) {
      final y = topPadding + (chartHeight * i / gridLineCount);
      final value = adjustedMax * (1 - i / gridLineCount);

      // Animate grid line opacity
      final gridOpacity = (lineAnimation * 2).clamp(0.0, 1.0);
      final animatedGridPaint = Paint()
        ..color = textColor.withOpacity(0.2 * gridOpacity)
        ..strokeWidth = 1;

      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(leftPadding + chartWidth, y),
        animatedGridPaint,
      );

      // Draw Y-axis label with fade in
      final textPainter = TextPainter(
        text: TextSpan(
          text: value >= 1000
              ? '${(value / 1000).toStringAsFixed(1)}k'
              : value.toStringAsFixed(0),
          style: textStyle.copyWith(
            color: textColor.withOpacity(gridOpacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(leftPadding - textPainter.width - 8, y - textPainter.height / 2),
      );
    }

    // Calculate points for the line chart
    final points = <Offset>[];
    final pointRadius = 5.0;

    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final x = leftPadding + (i * chartWidth / (sortedEntries.length - 1));
      final y = topPadding +
          chartHeight -
          ((entry.value / adjustedMax) * chartHeight);

      points.add(Offset(x, y));
    }

    // Draw the animated line path
    if (points.isNotEmpty) {
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);

      // Animate line drawing
      final totalLength = _calculatePathLength(points);
      final animatedLength = totalLength * lineAnimation;

      double currentLength = 0;
      for (int i = 1; i < points.length; i++) {
        final segmentLength = (points[i] - points[i - 1]).distance;
        if (currentLength + segmentLength <= animatedLength) {
          // Draw full segment
          path.lineTo(points[i].dx, points[i].dy);
          currentLength += segmentLength;
        } else {
          // Draw partial segment
          final remainingLength = animatedLength - currentLength;
          final ratio = remainingLength / segmentLength;
          final partialPoint = Offset(
            points[i - 1].dx + (points[i].dx - points[i - 1].dx) * ratio,
            points[i - 1].dy + (points[i].dy - points[i - 1].dy) * ratio,
          );
          path.lineTo(partialPoint.dx, partialPoint.dy);
          break;
        }
      }

      canvas.drawPath(path, linePaint);
    }

    // Draw animated points with staggered appearance
    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      // Stagger point animations
      final staggerDelay = i * 0.15;
      final pointAnimation =
          ((lineAnimation - staggerDelay) / (1 - staggerDelay)).clamp(0.0, 1.0);

      if (pointAnimation > 0) {
        // Draw point with scale animation
        final animatedRadius = pointRadius * pointAnimation;
        canvas.drawCircle(point, animatedRadius, pointPaint);

        // Draw point border
        canvas.drawCircle(
          point,
          animatedRadius,
          Paint()
            ..color = backgroundColor
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke,
        );

        // Animate value labels
        if (pointAnimation > 0.7) {
          final labelOpacity = ((pointAnimation - 0.7) / 0.3).clamp(0.0, 1.0);
          final value = sortedEntries[i].value;

          final valuePainter = TextPainter(
            text: TextSpan(
              text: value >= 1000
                  ? '${(value / 1000).toStringAsFixed(1)}k'
                  : value.toStringAsFixed(1),
              style: textStyle.copyWith(
                fontSize: 10,
                color: textColor.withOpacity(labelOpacity),
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          valuePainter.layout();
          valuePainter.paint(
            canvas,
            Offset(
              point.dx - valuePainter.width / 2,
              point.dy - valuePainter.height - pointRadius - 4,
            ),
          );
        }
      }
    }

    // Draw X-axis labels with fade in
    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final x = leftPadding + (i * chartWidth / (sortedEntries.length - 1));

      final labelOpacity = (lineAnimation * 1.5).clamp(0.0, 1.0);
      final displayLabel = isMonthly
          ? entry.key.length > 3
              ? entry.key.substring(0, 3)
              : entry.key
          : entry.key;

      final labelPainter = TextPainter(
        text: TextSpan(
            text: displayLabel,
            style: labelTextStyle.copyWith(
              color: textColor.withOpacity(labelOpacity),
            )),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(
          x - labelPainter.width / 2,
          topPadding + chartHeight + 8,
        ),
      );
    }

    // Draw animated chart border
    final borderOpacity = lineAnimation.clamp(0.0, 1.0);
    final borderPaint = Paint()
      ..color = textColor.withOpacity(0.3 * borderOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRect(
      Rect.fromLTWH(leftPadding, topPadding, chartWidth, chartHeight),
      borderPaint,
    );
  }

  double _calculatePathLength(List<Offset> points) {
    double length = 0;
    for (int i = 1; i < points.length; i++) {
      length += (points[i] - points[i - 1]).distance;
    }
    return length;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Always repaint for smooth animation
  }
}
