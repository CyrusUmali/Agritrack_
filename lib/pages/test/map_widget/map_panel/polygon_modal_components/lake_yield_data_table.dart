import 'package:flareline/core/models/yield_model.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/pages/reports/export_utils.dart';
import 'package:flareline/pages/test/map_widget/map_panel/barangay_bar_chart.dart';
import 'package:flareline/pages/test/map_widget/map_panel/polygon_modal_components/barangay_yield_line_chart.dart';
import 'package:flareline/pages/test/map_widget/map_panel/polygon_modal_components/barangay_yield_pie_chart.dart';
import 'package:flareline/pages/test/map_widget/map_panel/polygon_modal_components/monthly_data_table.dart';
import 'package:flareline/pages/test/map_widget/map_panel/polygon_modal_components/yearly_data_table.dart';

import 'package:flareline/pages/yields/yield_bloc/yield_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'product_selection_card.dart';

enum DataViewType { table, barchart, linechart, piechart }

class LakeYieldDataTable extends StatefulWidget {
  final String lake;

  const LakeYieldDataTable({super.key, required this.lake});

  @override
  State<LakeYieldDataTable> createState() => _LakeYieldDataTableState();
}

class _LakeYieldDataTableState extends State<LakeYieldDataTable> {
  late String _selectedProduct;
  bool _showMonthlyData = false;
  DataViewType _viewType = DataViewType.table;
  int selectedYear = DateTime.now().year;
  List<Yield> _yields = [];

  bool _showPieByVolume = true; // true = by volume, false = by records
  bool _showPieChartToggle = true; // Controls visibility of toggle buttons

  bool _isExporting = false;
  OverlayEntry? _loadingOverlay;

  @override
  void initState() {
    super.initState();
    _selectedProduct = _getInitialProduct();
    _loadYieldData();
  }

  void _showLoadingDialog(String message) {
    setState(() {
      _isExporting = true;
    });

    _loadingOverlay = OverlayEntry(
      builder: (context) => Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(message),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_loadingOverlay!);
  }

  void _closeLoadingDialog() {
    _loadingOverlay?.remove();
    _loadingOverlay = null;
    setState(() {
      _isExporting = false;
    });
  }

  Future<void> _exportData({bool isPDF = false}) async {
    if (isPDF) {
      await YieldExportUtils.exportYieldDataToPDF(
        context: context,
        yields: _yields,
        polygonName: widget.lake ?? 'Unknown',
        selectedProduct: _selectedProduct,
        isMonthlyView: _showMonthlyData,
        selectedYear: selectedYear,
        showLoadingDialog: _showLoadingDialog,
        closeLoadingDialog: _closeLoadingDialog,
      );
    } else {
      await YieldExportUtils.exportYieldDataToExcel(
        context: context,
        yields: _yields,
        polygonName: widget.lake ?? 'Unknown',
        selectedProduct: _selectedProduct,
        isMonthlyView: _showMonthlyData,
        selectedYear: selectedYear,
        showLoadingDialog: _showLoadingDialog,
        closeLoadingDialog: _closeLoadingDialog,
      );
    }
  }

  String _getInitialProduct() {
    final products = _getUniqueProducts();
    if (products.isNotEmpty) {
      return products.first;
    }
    return 'Mixed Crops';
  }

  List<String> _getUniqueProducts() {
    if (_yields.isEmpty) return [];
    return _yields.map((y) => y.productName ?? 'Unknown').toSet().toList();
  }

  String? _getProductImage(String productName) {
    for (final yield in _yields) {
      if (yield.productName == productName) {
        return yield.productImage;
      }
    }
    return null;
  }

  void _loadYieldData() {
    final yieldBloc = context.read<YieldBloc>();
    yieldBloc.add(GetYieldByLake(widget.lake));

    yieldBloc.stream.listen((state) {
      if (state is YieldsLoaded && mounted) {
        setState(() {
          _yields = state.yields;
          print('Yields loaded: ${_yields.length}');
          // print(_yields.map((y) => y.areaHarvested).toSet());
          print(_yields[0]);
          final currentProducts = _getUniqueProducts();
          if (currentProducts.isNotEmpty &&
              !currentProducts.contains(_selectedProduct)) {
            _selectedProduct = _getInitialProduct();
          }
        });
      }
    });
  }

  Map<String, Map<String, Map<String, double>>> _getYieldData() {
    final data = <String, Map<String, Map<String, double>>>{};
    final products = _getUniqueProducts();

    for (final product in products) {
      final productData = <String, Map<String, double>>{};
      final yearGroups = <int, List<Yield>>{};

      for (final yield in _yields.where((y) => y.productName == product)) {
        final year = yield.harvestDate?.year ?? DateTime.now().year;
        yearGroups.putIfAbsent(year, () => []).add(yield);
      }

      for (final entry in yearGroups.entries) {
        final totalVolume = entry.value
            .fold<double>(0, (sum, yield) => sum + (yield.volume ?? 0));

        final totalAreaHarvested = entry.value
            .where((yield) => yield.sectorId != 4) // Exclude livestock
            .fold<double>(0, (sum, yield) => sum + (yield.areaHarvested ?? 0));

        productData[entry.key.toString()] = {
          'volume': totalVolume,
          'areaHarvested': totalAreaHarvested,
        };
      }

      data[product] = productData;
    }

    return data;
  }

  Map<String, Map<String, double>> _getMonthlyYieldData(
      String product, int year) {
    final monthlyData = <String, Map<String, double>>{};
    final monthNames = [
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

    // Initialize all months with zero values
    for (final month in monthNames) {
      monthlyData[month] = {
        'volume': 0.0,
        'areaHarvested': 0.0,
      };
    }

    // Filter out yields where sectorId is 4 (Livestock)
    final relevantYields = _yields.where((yield) {
      final yieldYear = yield.harvestDate?.year ?? DateTime.now().year;
      return yield.productName == product &&
          yieldYear == year &&
          (yield.sectorId == null || yield.sectorId != 4);
    });

    for (final yield in relevantYields) {
      final month = yield.harvestDate?.month ?? 1;
      final monthName = monthNames[month - 1];

      monthlyData[monthName]!['volume'] =
          (monthlyData[monthName]!['volume'] ?? 0) + (yield.volume ?? 0);

      if (yield.sectorId != 4) {
        monthlyData[monthName]!['areaHarvested'] =
            (monthlyData[monthName]!['areaHarvested'] ?? 0) +
                (yield.areaHarvested ?? 0);
      }
    }

    return monthlyData;
  }

  Future<void> _showYearPicker(BuildContext context) async {
    final int? pickedYear = await showDialog<int>(
      context: context,
      builder: (context) {
        int tempYear = selectedYear;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Year',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).cardTheme.color
                  : Colors.white,
              content: SizedBox(
                height: 300,
                width: 300,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: Colors.blue,
                      onPrimary: Colors.white,
                      onSurface: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                    dividerTheme: DividerThemeData(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      thickness: 1,
                      space: 0,
                    ),
                  ),
                  child: YearPicker(
                    selectedDate: DateTime(tempYear),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2030),
                    onChanged: (DateTime dateTime) {
                      setState(() {
                        tempYear = dateTime.year;
                      });
                    },
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, tempYear);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );

    if (pickedYear != null) {
      setState(() {
        selectedYear = pickedYear;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWeb = kIsWeb;
    final screenWidth = MediaQuery.of(context).size.width;

    return BlocBuilder<YieldBloc, YieldState>(
      builder: (context, state) {
        // Handle loading state
        if (state is YieldsLoading) {
          return SizedBox(
            height: MediaQuery.of(context).size.height *
                0.5, // 50% of screen height
            child: Center(
              child: LoadingAnimationWidget.inkDrop(
                color: Theme.of(context).primaryColor,
                size: 50,
              ),
            ),
          );
        }

        if (state is YieldsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 50,
                ),
                SizedBox(height: 16),
                Text(
                  'Failed to load yield data',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadYieldData,
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is YieldsLoaded) {
          _yields = state.yields;
          final currentProducts = _getUniqueProducts();
          if (currentProducts.isNotEmpty &&
              !currentProducts.contains(_selectedProduct)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _selectedProduct = _getInitialProduct();
                });
              }
            });
          }
        }

        return Padding(
          padding: EdgeInsets.all(isWeb ? 24.0 : 0),
          child: _buildMainContent(theme, isWeb, screenWidth),
        );
      },
    );
  }

  Widget _buildMainContent(ThemeData theme, bool isWeb, double screenWidth) {
    final yieldData = _getYieldData();
    final products = _getUniqueProducts();

    return isWeb && screenWidth > 1200
        ? _buildWideScreenLayout(theme, yieldData, products)
        : _buildMobileLayout(theme, yieldData, products);
  }

  Widget _buildWideScreenLayout(
      ThemeData theme,
      Map<String, Map<String, Map<String, double>>> yieldData,
      List<String> products) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBarangayHeader(theme),
              const SizedBox(height: 20),
              ProductSelectionCard(
                products: products,
                selectedProduct: _selectedProduct,
                onProductSelected: (product) {
                  setState(() {
                    _selectedProduct = product;
                  });
                },
                isVertical: true,
                getProductImage: _getProductImage,
              ),
              const SizedBox(height: 20),
              _buildControlPanel(theme),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildDataDisplayCard(theme, yieldData),
        ),
      ],
    );
  }

  Widget _buildBarangayHeader(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, size: 24, color: theme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  widget.lake,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Agricultural Production Data',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataDisplayCard(ThemeData theme,
      Map<String, Map<String, Map<String, double>>> yieldData) {
    final productImage = _getProductImage(_selectedProduct);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;

                return isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (productImage != null &&
                                  _viewType != DataViewType.piechart)
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage: NetworkImage(productImage),
                                )
                              else if (_viewType != DataViewType.piechart)
                                Icon(Icons.analytics,
                                    color: theme.primaryColor, size: 24),
                              if (_viewType == DataViewType.piechart)
                                Icon(Icons.pie_chart,
                                    color: theme.primaryColor, size: 24)
                              else
                                const SizedBox.shrink(),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _viewType == DataViewType.piechart
                                      ? 'Yield Distribution - ${widget.lake}'
                                      : 'Production Data - $_selectedProduct',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.normal),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildViewTypeToggle(theme),
                                  const SizedBox(width: 12),
                                  if (_viewType == DataViewType.piechart)
                                    _buildPieChartModeToggle(theme),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color:
                                          theme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _showMonthlyData
                                          ? 'Monthly View'
                                          : 'Yearly View',
                                      style: TextStyle(
                                        color: theme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          if (productImage != null &&
                              _viewType != DataViewType.piechart)
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: NetworkImage(productImage),
                            )
                          else if (_viewType != DataViewType.piechart)
                            Icon(Icons.analytics,
                                color: theme.primaryColor, size: 24),
                          if (_viewType == DataViewType.piechart)
                            Icon(Icons.pie_chart,
                                color: theme.primaryColor, size: 24)
                          else
                            const SizedBox.shrink(),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _viewType == DataViewType.piechart
                                  ? 'Yield Distribution - ${widget.lake}'
                                  : 'Production Data - $_selectedProduct',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.normal),
                            ),
                          ),
                          const Spacer(),
                          _buildViewTypeToggle(theme),
                          const SizedBox(width: 12),
                          if (_viewType == DataViewType.piechart)
                            _buildPieChartModeToggle(theme)
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _showMonthlyData
                                    ? 'Monthly View'
                                    : 'Yearly View',
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      );
              },
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildDataDisplay(yieldData),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // New method: Pie chart mode toggle (Volume vs Records)
  Widget _buildPieChartModeToggle(ThemeData theme) {
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
          _buildPieToggleButton(
            label: 'Volume',
            icon: Icons.scale,
            isSelected: _showPieByVolume,
            onTap: () => setState(() => _showPieByVolume = true),
            theme: theme,
          ),
          Container(
            width: 1,
            height: 28,
            color: theme.dividerColor,
          ),
          _buildPieToggleButton(
            label: 'Records',
            icon: Icons.analytics,
            isSelected: !_showPieByVolume,
            onTap: () => setState(() => _showPieByVolume = false),
            theme: theme,
          ),
        ],
      ),
    );
  }

  // New method: Individual pie toggle button
  Widget _buildPieToggleButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return InkWell(
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
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? theme.primaryColor
                  : theme.iconTheme.color?.withOpacity(0.6),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? theme.primaryColor : null,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewTypeToggle(ThemeData theme) {
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
          _buildViewToggleButton(
            icon: Icons.table_chart,
            isSelected: _viewType == DataViewType.table,
            onTap: () => setState(() => _viewType = DataViewType.table),
            theme: theme,
            tooltip: 'Table View',
          ),
          Container(
            width: 1,
            height: 32,
            color: theme.dividerColor,
          ),
          _buildViewToggleButton(
            icon: Icons.bar_chart,
            isSelected: _viewType == DataViewType.barchart,
            onTap: () => setState(() => _viewType = DataViewType.barchart),
            theme: theme,
            tooltip: 'Bar Chart View',
          ),
          Container(
            width: 1,
            height: 32,
            color: theme.dividerColor,
          ),
          _buildViewToggleButton(
            icon: Icons.stacked_line_chart,
            isSelected: _viewType == DataViewType.linechart,
            onTap: () => setState(() => _viewType = DataViewType.linechart),
            theme: theme,
            tooltip: 'Line Chart View',
          ),
          Container(
            width: 1,
            height: 32,
            color: theme.dividerColor,
          ),
          _buildViewToggleButton(
            icon: Icons.pie_chart,
            isSelected: _viewType == DataViewType.piechart,
            onTap: () => setState(() => _viewType = DataViewType.piechart),
            theme: theme,
            tooltip: 'Pie Chart View',
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected
                ? theme.primaryColor.withOpacity(0.1)
                : Colors.transparent,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isSelected
                ? theme.primaryColor
                : theme.iconTheme.color?.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildDataDisplay(
      Map<String, Map<String, Map<String, double>>> yieldData) {
    final ScrollController scrollController = ScrollController();
    Widget chartWidget;

    if (_viewType == DataViewType.table) {
      chartWidget = _showMonthlyData
          ? MonthlyDataTable(
              product: _selectedProduct,
              year: selectedYear,
              monthlyData: _getMonthlyYieldData(_selectedProduct, selectedYear),
            )
          : YearlyDataTable(
              product: _selectedProduct,
              yearlyData: yieldData[_selectedProduct] ?? {});
    } else if (_viewType == DataViewType.barchart) {
      chartWidget = _showMonthlyData
          ? MonthlyBarChart(
              product: _selectedProduct,
              year: selectedYear,
              monthlyData: _getMonthlyYieldData(_selectedProduct, selectedYear),
            )
          : YearlyBarChart(
              product: _selectedProduct,
              yearlyData: yieldData[_selectedProduct] ?? {});
    } else if (_viewType == DataViewType.linechart) {
      chartWidget = _showMonthlyData
          ? MonthlyLineChart(
              product: _selectedProduct,
              year: selectedYear,
              monthlyData: _getMonthlyYieldData(_selectedProduct, selectedYear),
            )
          : YearlyLineChart(
              product: _selectedProduct,
              yearlyData: yieldData[_selectedProduct] ?? {});
    } else {
      // Filter yields for pie chart (exclude sectorId 4)

      chartWidget = BarangayYieldPieChart(
        yields: _yields,
        showByVolume: _showPieByVolume,
        selectedYear: _showMonthlyData ? selectedYear.toString() : null,
      );
    }

    final isChart = _viewType == DataViewType.barchart ||
        _viewType == DataViewType.linechart ||
        _viewType == DataViewType.piechart;

    if (isChart) {
      return Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        trackVisibility: true,
        thickness: 8.0,
        radius: const Radius.circular(4.0),
        interactive: true,
        child: SingleChildScrollView(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Container(
            width: _showMonthlyData ? 800 : 600,
            child: chartWidget,
          ),
        ),
      );
    }

    return chartWidget;
  }

  Widget _buildControlPanel(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline,
                    size: 20, color: colorScheme.onSurface.withOpacity(0.6)),
                const SizedBox(width: 8),
                Text(
                  'Time Period',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildToggleOption(
                      'Monthly',
                      Icons.calendar_month,
                      _showMonthlyData,
                      () async {
                        await _showYearPicker(context);
                        setState(() {
                          _showMonthlyData = true;
                        });
                      },
                      theme,
                    ),
                  ),
                  Expanded(
                    child: _buildToggleOption(
                      'Yearly',
                      Icons.calendar_month,
                      !_showMonthlyData,
                      () {
                        setState(() {
                          _showMonthlyData = false;
                        });
                      },
                      theme,
                    ),
                  ),
                ],
              ),
            ),
            if (_showMonthlyData) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.event,
                      color: colorScheme.onSurface.withOpacity(0.6), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Selected Year: $selectedYear',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showYearPicker(context),
                    icon: const Icon(
                      Icons.edit,
                    ),
                    label: const Text(
                      'Change',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            // _buildExportButton(theme),

            Row(
              children: [
                // Excel button (green)
                Expanded(
                  child: _buildExportButton(theme, isPDF: false),
                ),
                const SizedBox(width: 8),
                // PDF button (red)
                Expanded(
                  child: _buildExportButton(theme, isPDF: true),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton(ThemeData theme, {bool isPDF = false}) {
    final Color buttonColor = isPDF ? Colors.red : Colors.green;
    final String buttonText = isPDF ? ' PDF' : 'Excel';
    final IconData buttonIcon = isPDF ? Icons.picture_as_pdf : Icons.download;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isExporting ? null : () => _exportData(isPDF: isPDF),
        icon: _isExporting
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(buttonIcon, size: 18, color: Colors.white),
        label: Text(_isExporting ? 'Exporting...' : buttonText),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleOption(String label, IconData icon, bool isSelected,
      VoidCallback onTap, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).brightness == Brightness.dark
                  ? GlobalColors.primary
                  : theme.primaryColor
              : Theme.of(context).brightness == Brightness.dark
                  ? null
                  : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : colorScheme.onSurface.withOpacity(0.6),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
      ThemeData theme,
      Map<String, Map<String, Map<String, double>>> yieldData,
      List<String> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // _buildBarangayHeader(theme),
        // const SizedBox(height: 16),
        ProductSelectionCard(
          products: products,
          selectedProduct: _selectedProduct,
          onProductSelected: (product) {
            setState(() {
              _selectedProduct = product;
            });
          },
          isVertical: false,
          getProductImage: _getProductImage,
        ),
        const SizedBox(height: 16),
        _buildControlPanel(theme),
        const SizedBox(height: 16),
        _buildDataDisplayCard(theme, yieldData),
      ],
    );
  }
}
