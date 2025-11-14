import 'package:flareline/core/models/yield_model.dart';
import 'package:flareline/pages/sectors/components/chart_annotation_manager.dart';
import 'package:flareline/pages/sectors/components/sector_products_selector.dart';
import 'package:flareline/pages/yields/yield_bloc/yield_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flareline/pages/widget/network_error.dart';
import 'package:syncfusion_flutter_charts/charts.dart' as chart;
import 'components/sector_line_chart_widget.dart';
import './components/sector_data_model.dart';

class SectorLineChart extends StatefulWidget {
  const SectorLineChart({super.key});

  @override
  State<SectorLineChart> createState() => _SectorLineChartState();
}

class _SectorLineChartState extends State<SectorLineChart> {
  String selectedSector = 'All';
  int selectedFromYear = 2020;
  int selectedToYear = 2025;
  List<Yield> yieldData = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  final Map<String, List<String>> _sectorProductSelections = {};

  // Chart and annotation state
  final GlobalKey _chartKey = GlobalKey();
  late ChartAnnotationManager _annotationManager;

  @override
  void initState() {
    super.initState();
    _annotationManager = ChartAnnotationManager(setState: setState);
    _annotationManager.setContext(context); // Set the context first

    final yieldBloc = context.read<YieldBloc>();
    if (yieldBloc.state is YieldsLoaded) {
      isLoading = false;
      yieldData = (yieldBloc.state as YieldsLoaded).yields;
      sectorData = buildSectorDataFromYields(yieldData);
    }

    yieldBloc.stream.listen((state) async {
      if (state is YieldsLoaded) {
        setState(() {
          isLoading = false;
          hasError = false;
          yieldData = state.yields;
          sectorData = buildSectorDataFromYields(yieldData);
        });
        await _annotationManager.loadAnnotations();
      } else if (state is YieldsLoading) {
        setState(() {
          isLoading = true;
          hasError = false;
        });
      } else if (state is YieldsError) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = state.message;
          //  error: state.message,
        });
      }
    });
  }

  void _retryLoading() {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    context.read<YieldBloc>().add(LoadYields());
  }

  void _printYieldData() {
    if (yieldData.isEmpty) {
      print('No yield data available');
      return;
    }

    print('\n===== YIELD DATA (${yieldData.length} records) =====');

    for (var i = 0; i < yieldData.length; i++) {
      final yield = yieldData[i];
      print('\nRecord #${i + 1}:');
      print('  ID: ${yield.id}');
      print('  Farmer: ${yield.farmerName} (ID: ${yield.farmerId})');
      print('  Product: ${yield.productName} (ID: ${yield.productId})');
      print('  Sector: ${yield.sector} (ID: ${yield.sectorId})');
      print('  Barangay: ${yield.barangay}');
      print('  Volume: ${yield.volume}');
      print('  Area (ha): ${yield.hectare}');
      print('  Status: ${yield.status}');
      print('  Created At: ${yield.createdAt}');
      print('  Farm ID: ${yield.farmId}');
      print('----------------------------------');
    }

    print('===== END OF YIELD DATA =====\n');
  }

  Widget _buildLoadingContent() {
    return CommonCard(
      child: SizedBox(
        height: 500, // Adjust height as needed
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorContent() {
    return CommonCard(
      child: NetworkErrorWidget(
        error: errorMessage,
        onRetry: _retryLoading,
      ),
    );
  }

  Future<void> _selectYearRange(BuildContext context) async {
    final List<int>? picked = await showDialog<List<int>>(
      context: context,
      builder: (BuildContext context) {
        int tempFromYear = selectedFromYear;
        int tempToYear = selectedToYear;

        return StatefulBuilder(
          builder: (context, setState) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  onPrimary: Colors.white, // Selected year text color
                  primary: Theme.of(context)
                      .colorScheme
                      .primary, // Selected year background color
                ),
              ),
              child: AlertDialog(
                title: const Text('Select Year Range'),
                backgroundColor: Theme.of(context).cardTheme.color,
                content: SizedBox(
                  height: 400,
                  width: 300,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'From Year:',
                      ),
                      SizedBox(
                        height: 150,
                        child: YearPicker(
                          selectedDate: DateTime(tempFromYear),
                          firstDate: DateTime(2018),
                          lastDate: DateTime(2025),
                          onChanged: (DateTime dateTime) {
                            setState(() {
                              tempFromYear = dateTime.year;
                              if (tempFromYear > tempToYear) {
                                tempToYear = tempFromYear;
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'To Year:',
                      ),
                      SizedBox(
                        height: 150,
                        child: YearPicker(
                          selectedDate: DateTime(tempToYear),
                          firstDate: DateTime(tempFromYear),
                          lastDate: DateTime(2025),
                          onChanged: (DateTime dateTime) {
                            setState(() {
                              tempToYear = dateTime.year;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, [tempFromYear, tempToYear]);
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (picked != null && picked.length == 2) {
      setState(() {
        selectedFromYear = picked[0];
        selectedToYear = picked[1];
      });
    }
  }

  void _handleChartTap(TapDownDetails details) {
    final filteredData = _getFilteredData();
    _annotationManager.handleChartTap(details, _chartKey, selectedFromYear,
        selectedToYear, filteredData, context);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingContent();
    }

    if (hasError) {
      return _buildErrorContent();
    }

    final scrollBreakpoint = 600.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final needsScrolling = screenWidth < scrollBreakpoint;
    final useVerticalHeader = screenWidth < 550;
    final filteredData = _getFilteredData();

    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (useVerticalHeader) ...[
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Agricultural Performance',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        _buildSectorDropdown(),
                        if (selectedSector != 'All') ...[
                          const SizedBox(height: 12),
                          _buildSelectProductsButton(),
                        ],
                        const SizedBox(height: 12),
                        _buildYearRangePickerButton(context),
                      ],
                    ),
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Agricultural Performance',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Row(
                        children: [
                          _buildSectorDropdown(),
                          if (selectedSector != 'All') ...[
                            const SizedBox(width: 12),
                            _buildSelectProductsButton(),
                          ],
                          const SizedBox(width: 12),
                          _buildYearRangePickerButton(context),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTapDown: _handleChartTap,
            child: SizedBox(
              height: 380,
              child: needsScrolling
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        width: scrollBreakpoint,
                        child: SectorLineChartWidget(
                          key: _chartKey,
                          title: '',
                          dropdownItems: [],
                          datas: filteredData,
                          annotations: _annotationManager.customAnnotations,
                          unit: selectedSector == 'Livestock' ? 'heads' : 'kg',
                        ),
                      ),
                    )
                  : SectorLineChartWidget(
                      key: _chartKey,
                      title: '',
                      dropdownItems: [],
                      datas: filteredData,
                      annotations: _annotationManager.customAnnotations,
                      unit: selectedSector == 'Livestock' ? 'heads' : 'kg',
                    ),
            ),
          ),
          if (_annotationManager.customAnnotations.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Tap annotations to edit ',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  List<SectorData> _getFilteredData() {
    if (selectedSector == 'All') {
      final Map<String, List<Map<String, dynamic>>> sectorGroupedData = {};
      final Map<String, Color> sectorColors = {};

      sectorData.forEach((sectorKey, sectorItems) {
        for (final item in sectorItems) {
          for (final point in item.data) {
            final year = point['x'];
            final value = point['y'].toDouble();

            final yearInt = int.parse(year);
            if (yearInt >= selectedFromYear && yearInt <= selectedToYear) {
              if (!sectorGroupedData.containsKey(sectorKey)) {
                sectorGroupedData[sectorKey] = [];
                sectorColors[sectorKey] = item.color;
              }

              final existingIndex = sectorGroupedData[sectorKey]!
                  .indexWhere((e) => e['x'] == year);

              if (existingIndex >= 0) {
                sectorGroupedData[sectorKey]![existingIndex]['y'] += value;
              } else {
                sectorGroupedData[sectorKey]!.add({
                  'x': year,
                  'y': value,
                });
              }
            }
          }
        }

        // Sort the years for each sector
        if (sectorGroupedData.containsKey(sectorKey)) {
          sectorGroupedData[sectorKey]!
              .sort((a, b) => int.parse(a['x']).compareTo(int.parse(b['x'])));
        }
      });

      return sectorGroupedData.entries
          .map((entry) {
            return SectorData(
              name: entry.key,
              color: sectorColors[entry.key] ?? Colors.grey,
              data: entry.value,
              annotations: null,
            );
          })
          .where((sector) => sector.data.isNotEmpty)
          .toList();
    } else {
      if (!_sectorProductSelections.containsKey(selectedSector)) {
        final sectorProducts = sectorData[selectedSector] ?? [];
        _sectorProductSelections[selectedSector] =
            sectorProducts.take(8).map((product) => product.name).toList();
      }

      final currentSelections = _sectorProductSelections[selectedSector] ?? [];

      return (sectorData[selectedSector] ?? [])
          .where((sector) =>
              currentSelections.isEmpty ||
              currentSelections.contains(sector.name))
          .map((sector) {
            final filteredSeriesData = sector.data.where((point) {
              final year = int.parse(point['x']);
              return year >= selectedFromYear && year <= selectedToYear;
            }).toList()
              ..sort((a, b) =>
                  int.parse(a['x']).compareTo(int.parse(b['x']))); // Sort here

            return SectorData(
              name: sector.name,
              color: sector.color,
              data: filteredSeriesData,
              annotations: sector.annotations,
            );
          })
          .where((sector) => sector.data.isNotEmpty)
          .toList();
    }
  }

  Widget _buildSelectProductsButton() {
    return InkWell(
      onTap: () {
        SectorProductSelectionModal.show(
          context: context,
          sector: selectedSector,
          maxProducts: 8,
          initialSelections: _sectorProductSelections[selectedSector]?.toList(),
          onProductsSelected: (products) {
            setState(() {
              _sectorProductSelections[selectedSector] = List.from(products);
            });
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select Products'),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectorDropdown() {
    return PopupMenuButton<String>(
      initialValue: selectedSector,
      onSelected: (String value) {
        setState(() {
          selectedSector = value;
        });
      },
      itemBuilder: (BuildContext context) {
        return ['All', 'Rice', 'Corn', 'Fishery', 'Livestock', 'Organic', 'HVC']
            .map((String item) {
          return PopupMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(selectedSector),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildYearRangePickerButton(BuildContext context) {
    return InkWell(
      onTap: () => _selectYearRange(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$selectedFromYear - $selectedToYear'),
            const SizedBox(width: 8),
            const Icon(Icons.calendar_today, size: 16),
          ],
        ),
      ),
    );
  }
}
