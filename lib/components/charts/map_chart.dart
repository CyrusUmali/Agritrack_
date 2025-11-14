import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_maps/maps.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flareline/services/lanugage_extension.dart';

class MapChartWidget extends StatelessWidget {
  const MapChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return _maps(context);
  }

  Widget _maps(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'City Map',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.normal,
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                // borderRadius: BorderRadius.circular(12),
                // boxShadow: [
                //   BoxShadow(
                //     color: Colors.black.withOpacity(0.1),
                //     blurRadius: 8,
                //     offset: const Offset(0, 4),
                //   )
                // ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: ChangeNotifierProvider(
                  create: (context) => _BarangayDataProvider(),
                  builder: (ctx, child) {
                    final provider = ctx.watch<_BarangayDataProvider>();

                    if (provider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (provider.data.isEmpty) {
                      return Center(
                        child: Text(
                          context.translate('No data available'),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      );
                    }

                    final MapZoomPanBehavior zoomPanBehavior =
                        MapZoomPanBehavior(
                      enableDoubleTapZooming: true,
                      enableMouseWheelZooming: true,
                      enablePinching: true,
                      zoomLevel: 1,
                      minZoomLevel: 1,
                      maxZoomLevel: 15,
                      enablePanning: true,
                    );

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        // For smaller screens, stack vertically
                        if (constraints.maxWidth < 800) {
                          return Column(
                            children: [
                              _buildProductSelector(provider, context),
                              const SizedBox(height: 16),
                              Expanded(
                                flex: 3,
                                child: _buildMap(provider, zoomPanBehavior),
                              ),
                              const SizedBox(height: 16),
                              _buildBarangayList(provider, context),
                            ],
                          );
                        }
                        // For larger screens, use horizontal layout
                        return Column(
                          children: [
                            _buildProductSelector(provider, context),
                            const SizedBox(height: 16),
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _buildMap(provider, zoomPanBehavior),
                                  ),
                                  const SizedBox(width: 16),
                                  _buildBarangayList(provider, context),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSelector(
      _BarangayDataProvider provider, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade400, // Solid border color
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(
            'Product: ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Autocomplete<String>(
              fieldViewBuilder: (context, textEditingController, focusNode,
                  onFieldSubmitted) {
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'Search or select product',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    suffixIcon: textEditingController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              textEditingController.clear();
                              provider.selectedProduct = '';
                              provider.updateColorsBasedOnYield();
                              FocusScope.of(context).requestFocus(focusNode);
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (value) => onFieldSubmitted(),
                );
              },
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return provider.availableProducts;
                }
                return provider.availableProducts.where((product) {
                  return product.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      );
                });
              },
              onSelected: (String selection) {
                provider.selectedProduct = selection;
                provider.updateColorsBasedOnYield();
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(
                        color: Colors.grey.shade400, // Solid border color
                        width: 1,
                      ),
                    ),
                    child: SizedBox(
                      width: 300, // Fixed width for dropdown
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 200, // Fixed max height
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final option = options.elementAt(index);
                            return InkWell(
                              onTap: () {
                                onSelected(option);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: index < options.length - 1
                                      ? Border(
                                          bottom: BorderSide(
                                            color: Colors
                                                .grey.shade300, // Divider color
                                            width: 1,
                                          ),
                                        )
                                      : null,
                                ),
                                child: Text(option),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
              displayStringForOption: (option) => option,
              initialValue: provider.selectedProduct.isNotEmpty
                  ? TextEditingValue(text: provider.selectedProduct)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

// Helper widget for consistent tooltip rows
  Widget _buildTooltipRow({
    required IconData icon,
    required String label,
    required String value,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: textColor.withOpacity(0.9),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(
      _BarangayDataProvider provider, MapZoomPanBehavior zoomPanBehavior) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          SfMaps(
            layers: [
              MapShapeLayer(
                zoomPanBehavior: zoomPanBehavior,
                source: MapShapeSource.asset(
                  'assets/barangay.json',
                  shapeDataField: 'name',
                  dataCount: provider.data.length,
                  primaryValueMapper: (int index) => provider.data[index].name,
                  dataLabelMapper: (int index) => provider.data[index].name,
                  shapeColorValueMapper: (int index) =>
                      provider.data[index].color,
                ),
                showDataLabels: true,
                shapeTooltipBuilder: (BuildContext context, int index) {
                  final barangay = provider.data[index];
                  final colorLightness = barangay.color.computeLuminance();
                  final textColor =
                      colorLightness > 0.5 ? Colors.black : Colors.white;

                  // Calculate yield percentage if a product is selected
                  double? yieldPercentage;
                  if (provider.selectedProduct.isNotEmpty) {
                    final yields = provider.data
                        .map((b) => b.yieldData[provider.selectedProduct] ?? 0)
                        .toList();
                    final maxYield = yields.reduce((a, b) => a > b ? a : b);
                    yieldPercentage =
                        (barangay.yieldData[provider.selectedProduct] ?? 0) /
                            maxYield *
                            100;
                  }

                  return Container(
                    width: 220,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: barangay.color.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Barangay Name Header
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: textColor),
                            const SizedBox(width: 4),
                            Text(
                              barangay.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Yield Data Section
                        if (provider.selectedProduct.isNotEmpty) ...[
                          _buildTooltipRow(
                            icon: Icons.agriculture,
                            label: '${provider.selectedProduct} Yield',
                            value:
                                '${barangay.yieldData[provider.selectedProduct]?.toStringAsFixed(1) ?? 'N/A'}',
                            textColor: textColor,
                          ),
                          if (yieldPercentage != null)
                            _buildTooltipRow(
                              icon: Icons.trending_up,
                              label: 'Yield Percentage',
                              value: '${yieldPercentage.toStringAsFixed(1)}%',
                              textColor: textColor,
                            ),
                          const SizedBox(height: 4),
                        ],

                        // General Information Section
                        _buildTooltipRow(
                          icon: Icons.landscape,
                          label: 'Area',
                          value: '${barangay.area.toStringAsFixed(2)} km²',
                          textColor: textColor,
                        ),
                        _buildTooltipRow(
                          icon: Icons.people,
                          label: 'Farmers',
                          value: barangay.farmer?.toStringAsFixed(0) ?? 'N/A',
                          textColor: textColor,
                        ),

                        // Additional Data Section
                        if (barangay.topProducts.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Top Products:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          ...barangay.topProducts
                              .map((product) => Padding(
                                    padding: const EdgeInsets.only(
                                        left: 8.0, top: 4),
                                    child: Text(
                                      '• $product',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: textColor.withOpacity(0.9),
                                      ),
                                    ),
                                  ))
                              .take(3),
                        ],
                      ],
                    ),
                  );
                },
                tooltipSettings: const MapTooltipSettings(
                  hideDelay: 0,
                ),
                strokeColor: Colors.white,
                strokeWidth: 0.8,
                dataLabelSettings: const MapDataLabelSettings(
                  textStyle: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          if (provider.selectedProduct.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              child: _buildLegend(provider),
            ),
        ],
      ),
    );
  }

  Widget _buildLegend(_BarangayDataProvider provider) {
    final yields = provider.data
        .map((b) => b.yieldData[provider.selectedProduct] ?? 0)
        .toList();
    final maxYield =
        yields.isNotEmpty ? yields.reduce((a, b) => a > b ? a : b) : 1;
    final minYield =
        yields.isNotEmpty ? yields.reduce((a, b) => a < b ? a : b) : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${provider.selectedProduct} Yield ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLegendItem(
                Colors.red[700]!,
                'High (${maxYield.toStringAsFixed(1)})',
              ),
              const SizedBox(width: 8),
              _buildLegendItem(
                Colors.orange[400]!,
                'Medium (${(maxYield * 0.66).toStringAsFixed(1)})',
              ),
              const SizedBox(width: 8),
              _buildLegendItem(
                Colors.green[400]!,
                'Low (${minYield.toStringAsFixed(1)})',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildBarangayList(
      _BarangayDataProvider provider, BuildContext context) {
    return Container(
      width: 200,
      constraints: const BoxConstraints(maxWidth: 250),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'Barangay List',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: provider.data.length,
                itemBuilder: (context, index) {
                  final barangay = provider.data[index];
                  return ListTile(
                    dense: true,
                    minLeadingWidth: 24,
                    leading: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: barangay.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    title: Text(
                      barangay.name,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: provider.selectedProduct.isNotEmpty
                        ? Text(
                            '${barangay.yieldData[provider.selectedProduct]?.toStringAsFixed(2) ?? 'N/A'}',
                            style: Theme.of(context).textTheme.bodySmall,
                          )
                        : null,
                    onTap: () {
                      // Potential feature: Highlight/zoom to selected barangay
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BarangayModel {
  BarangayModel(
    this.name, {
    required this.area,
    required this.yieldData,
    this.farmer,
    this.topProducts = const [],
    Color? color,
  }) : color = color ?? Colors.grey;

  final String name;
  final double area;
  final int? farmer;
  final Map<String, double> yieldData;
  final List<String> topProducts;
  Color color;
}

class _BarangayDataProvider extends ChangeNotifier {
  List<BarangayModel> _data = [];
  bool _isLoading = true;
  String _selectedProduct = '';
  final List<String> _availableProducts = [
    'Rice',
    'Corn',
    'Cow',
    'Coconut',
    'Banana',
  ];

  List<BarangayModel> get data => _data;
  bool get isLoading => _isLoading;
  String get selectedProduct => _selectedProduct;
  List<String> get availableProducts => _availableProducts;

  set selectedProduct(String value) {
    _selectedProduct = value;
    notifyListeners();
  }

  _BarangayDataProvider() {
    init();
  }

  Future<void> init() async {
    try {
      final barangayNames =
          await GeoJsonParser.getBarangayNamesFromAsset('assets/barangay.json');
      barangayNames.sort();

      // Generate mock yield data for demonstration
      _data = List.generate(
        barangayNames.length,
        (index) {
          final random = Random(index * 1000); // Using Dart's built-in Random
          final yields = <String, double>{};
          final products = ['Rice', 'Corn', 'Cow', 'Coconut', 'Banana'];

          // Generate random yield data
          for (var product in products) {
            yields[product] = 5 + random.nextDouble() * 20;
          }

          // Sort products by yield to get top products
          final sortedProducts = List<String>.from(products)
            ..sort((a, b) => yields[b]!.compareTo(yields[a]!));

          return BarangayModel(
            barangayNames[index],
            area: 1 + random.nextDouble() * 4,
            yieldData: yields,
            farmer: 1000 + random.nextInt(9000), // Now using proper nextInt()
            topProducts: sortedProducts.take(3).toList(),
            color: getColorForIndex(index, barangayNames.length),
          );
        },
      );
    } catch (e) {
      _data = [];
      debugPrint('Error loading barangay data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateColorsBasedOnYield() {
    if (_selectedProduct.isEmpty) {
      // Reset to default colors if no product selected
      for (var i = 0; i < _data.length; i++) {
        _data[i].color = getColorForIndex(i, _data.length);
      }
    } else {
      // Get all yield values for the selected product
      final yields = _data
          .map((barangay) => barangay.yieldData[_selectedProduct] ?? 0)
          .toList();

      if (yields.isEmpty) return;

      final maxYield = yields.reduce((a, b) => a > b ? a : b);
      final minYield = yields.reduce((a, b) => a < b ? a : b);
      final range = maxYield - minYield;

      if (range == 0) return; // All values are the same

      // Update colors based on yield
      for (var barangay in _data) {
        final yield = barangay.yieldData[_selectedProduct] ?? 0;
        final normalized = (yield - minYield) / range;

        // Create a heatmap color (red = high, green = low)
        barangay.color = Color.lerp(
          Colors.green,
          Colors.red,
          normalized,
        )!
            .withOpacity(0.7);
      }
    }

    notifyListeners();
  }
}

class GeoJsonParser {
  static Future<List<String>> getBarangayNamesFromAsset(
      String assetPath) async {
    final String data = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> jsonResult = json.decode(data);

    List<String> barangayNames = [];

    if (jsonResult.containsKey('features')) {
      for (var feature in jsonResult['features']) {
        if (feature['properties'] != null &&
            feature['properties']['name'] != null) {
          barangayNames.add(feature['properties']['name'].toString());
        }
      }
    }

    return barangayNames;
  }
}

Color getColorForIndex(int index, int total) {
  final hue = (index * (360.0 / total)) % 360.0;
  return HSLColor.fromAHSL(1.0, hue, 0.7, 0.6).toColor();
}
