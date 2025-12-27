import 'package:flareline/core/models/yield_model.dart';
import 'package:flutter/material.dart';
import 'barangay_model.dart';

class BarangayDataProvider extends ChangeNotifier {
  int _selectedYear;
  List<BarangayModel> _data = [];
  bool _isLoading = true;
  List<String> _selectedProducts = []; // Changed to List
  int _activeProductIndex = 0; // Track which product's heatmap to show
  List<String> _availableProducts = [];
  List<Yield> _yields = [];
  List<Yield> get yields => _yields;
  bool _disposed = false;

  List<BarangayModel> get data => _data;
  bool get isLoading => _isLoading;
  List<String> get selectedProducts => _selectedProducts; // Changed
  int get activeProductIndex => _activeProductIndex;
  String get activeProduct => _selectedProducts.isEmpty ? '' : _selectedProducts[_activeProductIndex];
  List<String> get availableProducts => _availableProducts;
  static const int maxProducts = 3;

  // Add a product to selection (max 3)
  void addProduct(String product) {
    if (!_selectedProducts.contains(product) && _selectedProducts.length < maxProducts) {
      _selectedProducts.add(product);
      _activeProductIndex = _selectedProducts.length - 1; // Set to newly added product
      updateColorsBasedOnYield();
      notifyListeners();
    }
  }

  // Remove a product from selection
  void removeProduct(String product) {
    final index = _selectedProducts.indexOf(product);
    if (index != -1) {
      _selectedProducts.removeAt(index);
      
      // Adjust active index if needed
      if (_activeProductIndex >= _selectedProducts.length) {
        _activeProductIndex = _selectedProducts.isEmpty ? 0 : _selectedProducts.length - 1;
      }
      
      updateColorsBasedOnYield();
      notifyListeners();
    }
  }

  // Set which product's heatmap to display
  void setActiveProduct(int index) {
    if (index >= 0 && index < _selectedProducts.length) {
      _activeProductIndex = index;
      updateColorsBasedOnYield();
      notifyListeners();
    }
  }

  // Clear all selected products
  void clearProducts() {
    _selectedProducts.clear();
    _activeProductIndex = 0;
    updateColorsBasedOnYield();
    notifyListeners();
  }

  BarangayDataProvider({
    List<String>? initialProducts,
    List<Yield> yields = const [],
    required int selectedYear,
    String? initialSelectedProduct,
  }) : _selectedYear = selectedYear {
    if (initialProducts != null) {
      _availableProducts = initialProducts;
    }
    _yields = yields;

    // Set initial selected product if provided and valid
    if (initialSelectedProduct != null &&
        initialSelectedProduct.isNotEmpty &&
        (initialProducts?.contains(initialSelectedProduct) ?? false)) {
      _selectedProducts.add(initialSelectedProduct);
    }

    _isLoading = true;
    init().then((_) {
      if (!_disposed) {
        notifyListeners();
      }
    });
  }

  List<BarangayModel> get filteredBarangays {
    if (_selectedProducts.isEmpty) {
      return _data;
    }

    final activeProductName = activeProduct;
    return _data.where((barangay) {
      final yield = barangay.yieldData[activeProductName] ?? 0;
      return yield > 0;
    }).toList();
  }

  List<BarangayModel> get sortedBarangays {
    final barangays = filteredBarangays;

    if (_selectedProducts.isEmpty) {
      return barangays;
    }

    final activeProductName = activeProduct;
    barangays.sort((a, b) {
      final yieldA = a.yieldData[activeProductName] ?? 0;
      final yieldB = b.yieldData[activeProductName] ?? 0;
      return yieldB.compareTo(yieldA);
    });

    return barangays;
  }

  List<Yield> _filterYieldsByYear(List<Yield> yields, int year) {
    return yields.where((yield) {
      DateTime harvestDate;
      if (yield.harvestDate is String) {
        harvestDate = DateTime.parse(yield.harvestDate as String);
      } else 
         harvestDate = yield.harvestDate;
    

      return harvestDate.year == year;
    }).toList();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      // print('🔔 notifyListeners called - isLoading: $_isLoading, data length: ${_data.length}');
      super.notifyListeners();
    }
  }

  void printBarangayColors() {
    // int nonZeroCount = 0;

    for (var barangay in _data) {
      final yield = activeProduct.isEmpty
          ? 0
          : barangay.yieldData[activeProduct] ?? 0;

      if (yield == 0) {
        continue;
      }

      // final color = barangay.color;

      // print('${barangay.name}:');
      // print('  - Color: ${color.toString()}');
      // print('  - HEX: #${color.value.toRadixString(16).padLeft(8, '0')}');
      // print('  - Yield: $yield');
      // print('  - Area: ${barangay.area} hectares');
      // print('  - Top Products: ${barangay.topProducts}');
      // print('  - Yield Data: ${barangay.yieldData}');
      // print('');

      // nonZeroCount++;
    }

    // print('Total barangays with non-zero yield: $nonZeroCount');
    // print('Total barangays processed: ${_data.length}');
    // print('================================\n');
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final filteredYields = _filterYieldsByYear(_yields, _selectedYear);

      final barangayNames =
          await GeoJsonParser.getBarangayNamesFromAsset('assets/barangay.json');
      barangayNames.sort();

      if (_availableProducts.isEmpty) {
        // print('No products provided, using fallback');
      }

      final Map<String, Map<int, double>> farmAreas = {};
      final Map<String, Map<String, double>> barangayYields = {};

      for (var _yield in filteredYields) {
        final barangay = _yield.barangay ?? 'Unknown';
        final farmId = _yield.farmId;
        final productName = _yield.productName ?? 'Unknown';
        final volume = _yield.volume;
        final hectare = _yield.hectare ?? 0.0;

        if (!farmAreas.containsKey(barangay)) {
          farmAreas[barangay] = {};
        }
        farmAreas[barangay]![farmId] = hectare;

        if (!barangayYields.containsKey(barangay)) {
          barangayYields[barangay] = {};
        }
        barangayYields[barangay]!.update(
          productName,
          (value) => value + volume,
          ifAbsent: () => volume,
        );
      }

      _data = barangayNames.map((barangay) {
        final totalArea = farmAreas[barangay]
                ?.values
                .fold(0.0, (previousValue, area) => previousValue + area) ??
            0.0;

        final yields = barangayYields[barangay] ?? {};

        final topProducts = yields.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topProductNames = topProducts.take(3).map((e) => e.key).toList();

        return BarangayModel(
          barangay,
          area: totalArea,
          yieldData: yields,
          farmer: topProducts.length,
          topProducts: topProductNames,
          color: getColorForIndex(
              barangayNames.indexOf(barangay), barangayNames.length),
        );
      }).toList();

      // print('📊 Created ${_data.length} barangay models');
    } catch (e) {
      _data = [];
      debugPrint('Error loading barangay data: $e');
    } finally {
      _isLoading = false;

      if (_selectedProducts.isNotEmpty) {
        // print('Updating colors for initial products: $_selectedProducts');
        updateColorsBasedOnYield();
      } else {
        notifyListeners();
      }
    }
  }

  void updateColorsBasedOnYield() {
    // print('\n🎨 === UPDATE COLORS DEBUG ===');
    // print('Selected Products: $_selectedProducts');
    // print('Active Product: $activeProduct');
    // print('Data length: ${_data.length}');

    if (_selectedProducts.isEmpty || activeProduct.isEmpty) {
      // print('No product selected - using default colors');
      for (var i = 0; i < _data.length; i++) {
        _data[i].color = getColorForIndex(i, _data.length);
      }
    } else {
      final yields = _data
          .map((barangay) => barangay.yieldData[activeProduct] ?? 0.0)
          .toList();

      // print('Total yields collected: ${yields.length}');

      if (yields.isEmpty) {
        // print('⚠️ No yields found - this should not happen');
        return;
      }

      final nonZeroYields = yields.where((y) => y > 0).toList();

      // print('Non-zero yields: ${nonZeroYields.length}');
      // print('Zero yields: ${yields.length - nonZeroYields.length}');

      if (nonZeroYields.isEmpty) {
        // print('All yields are zero - setting all to gray');
        for (var barangay in _data) {
          barangay.color = Colors.grey.withOpacity(0.7);
        }
      } else {
        final maxYield = nonZeroYields.reduce((a, b) => a > b ? a : b);
        final minYield = nonZeroYields.reduce((a, b) => a < b ? a : b);
        final range = maxYield - minYield;

        // print('Max yield: $maxYield');
        // print('Min yield: $minYield');
        // print('Range: $range');

        for (var barangay in _data) {
          final yieldValue = barangay.yieldData[activeProduct] ?? 0.0;

          if (yieldValue == 0) {
            barangay.color = Colors.grey.withOpacity(0.7);
            // print('${barangay.name}: ZERO yield → gray');
          } else {
            double normalized;

            if (range == 0) {
              normalized = 0.5;
              // print('${barangay.name}: Range is 0, using normalized = 0.5');
            } else {
              normalized = (yieldValue - minYield) / range;
            }

            normalized = normalized.clamp(0.0, 1.0);

            final color = Color.lerp(
              const Color.fromARGB(255, 245, 192, 112),
              Colors.red,
              normalized,
            )!
                .withOpacity(0.7);

            barangay.color = color;

            // print(
            //     '${barangay.name}: yield=$yieldValue, normalized=$normalized, color=${color.toString()}');
          }
        }

        // print('=== COLOR UPDATE COMPLETE ===\n');
      }
    }

    notifyListeners();
  }

  Color getColorForIndex(int index, int total) {
    final hue = (index * 360 / total) % 360;
    return HSLColor.fromAHSL(1.0, hue, 0.7, 0.6).toColor();
  }
}