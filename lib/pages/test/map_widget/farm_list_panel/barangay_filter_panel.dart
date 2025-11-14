// ignore_for_file: unnecessary_to_list_in_spreads, avoid_print

import 'dart:convert';
import 'package:flareline/services/lanugage_extension.dart';
import 'package:flareline/pages/test/map_widget/polygon_manager.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BarangayFilterPanel extends StatefulWidget {
  final BarangayManager barangayManager;
  final PolygonManager polygonManager;
  final List<String> selectedBarangays;
  final List<String> selectedProducts;
  final VoidCallback onClose;
  final Function(
          List<String>, List<String>, Map<String, bool>, Map<String, bool>)
      onFiltersChanged;

  static Map<String, bool> filterOptions = {
    'Rice': true,
    'Fishery': true,
    'Corn': true,
    'Organic': true,
    'Livestock': true,
    'HVC': true,
  };

  // User-based filter options
  static Map<String, bool> userFilterOptions = {
    'showOwnedOnly': true, // For farmers: show only owned farms
    'showActiveOnly': true, // For non-farmers: show only active farms
  };

  const BarangayFilterPanel({
    Key? key,
    required this.barangayManager,
    required this.polygonManager,
    required this.selectedBarangays,
    required this.selectedProducts,
    required this.onFiltersChanged,
    required this.onClose,
  }) : super(key: key);

  @override
  _BarangayFilterPanelState createState() => _BarangayFilterPanelState();
}

class _BarangayFilterPanelState extends State<BarangayFilterPanel> {
  late List<String> _tempSelectedBarangays;
  late List<String> _tempSelectedProducts;
  late Map<String, bool> _tempFilterOptions;
  late Map<String, bool> _tempUserFilterOptions;
  String searchQuery = '';
  bool showProductFilter = false; // Toggle between barangay and product filters

  @override
  void initState() {
    super.initState();
    _tempSelectedBarangays = List.from(widget.selectedBarangays);
    _tempSelectedProducts = List.from(widget.selectedProducts);
    _tempFilterOptions = Map.from(BarangayFilterPanel.filterOptions);
    _tempUserFilterOptions = Map.from(BarangayFilterPanel.userFilterOptions);
    _logBarangays();
  }

  void _logBarangays() {
    final barangayNames =
        widget.barangayManager.barangays.map((b) => b.name).toList();
    final barangayJson = {
      "barangays": barangayNames,
    };
    // print('Barangay List:');
    // print(jsonEncode(barangayJson));
  }

  void _toggleAllBarangays(bool selectAll) {
    setState(() {
      _tempSelectedBarangays = selectAll
          ? widget.barangayManager.barangays.map((b) => b.name).toList()
          : [];
    });
  }

  void _toggleAllProducts(bool selectAll) {
    setState(() {
      _tempSelectedProducts = selectAll ? _getAllAvailableProducts() : [];
    });
  }

  List<String> _getAllAvailableProducts() {
    final allProducts = <String>{};
    for (final polygon in widget.polygonManager.polygons) {
      if (polygon.products != null) {
        allProducts.addAll(polygon.products!);
      }
    }
    return allProducts.toList()..sort();
  }

  // Helper method to extract display name from product string
  String _getProductDisplayName(String product) {
    final colonIndex = product.indexOf(':');
    if (colonIndex != -1) {
      return product.substring(colonIndex + 1).trim();
    }
    return product;
  }

  List<String> _getFilteredProducts() {
    final allProducts = _getAllAvailableProducts();
    if (searchQuery.isEmpty) return allProducts;

    return allProducts
        .where((product) => _getProductDisplayName(product)
            .toLowerCase()
            .contains(searchQuery.toLowerCase()))
        .toList();
  }

  Widget _buildUserFilterToggle(ThemeData theme, bool isFarmer) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surface.withOpacity(0.05),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text(
              //   isFarmer ? 'Show Farms' : 'Farm Status',
              //   style: theme.textTheme.bodyMedium?.copyWith(
              //     fontWeight: FontWeight.w600,
              //   ),
              // ),
              // SizedBox(height: 2),
              Text(
                isFarmer
                    ? (_tempUserFilterOptions['showOwnedOnly'] == true
                        ? 'Only my farms'
                        : 'All farms')
                    : (_tempUserFilterOptions['showActiveOnly'] == true
                        ? 'Active farms only'
                        : 'All farms'),
                // style: theme.textTheme.bodySmall?.copyWith(
                //   color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                // ),

                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: theme.colorScheme.surface.withOpacity(0.1),
            ),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Text(
                //   isFarmer
                //       ? (_tempUserFilterOptions['showOwnedOnly'] == true
                //           ? 'Owned'
                //           : 'All')
                //       : (_tempUserFilterOptions['showActiveOnly'] == true
                //           ? 'Active'
                //           : 'All'),
                //   // style: theme.textTheme.bodySmall?.copyWith(
                //   //   // fontSize: 10,
                //   //   fontWeight: FontWeight.w600,
                //   // ),

                //   style: theme.textTheme.bodyMedium?.copyWith(
                //     fontWeight: FontWeight.w600,
                //     fontSize: 10,
                //   ),
                // ),
                SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isFarmer) {
                        _tempUserFilterOptions['showOwnedOnly'] =
                            !(_tempUserFilterOptions['showOwnedOnly'] ?? true);
                      } else {
                        _tempUserFilterOptions['showActiveOnly'] =
                            !(_tempUserFilterOptions['showActiveOnly'] ?? true);
                      }
                    });
                  },
                  child: Container(
                    width: 50, // Increased from 30
                    height: 24, // Increased from 16
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                          12), // Increased to match new height
                      color: (isFarmer
                              ? (_tempUserFilterOptions['showOwnedOnly'] ??
                                  true)
                              : (_tempUserFilterOptions['showActiveOnly'] ??
                                  true))
                          ? theme.colorScheme.primary
                          : Colors.grey.shade300,
                    ),
                    child: AnimatedAlign(
                      alignment: (isFarmer
                              ? (_tempUserFilterOptions['showOwnedOnly'] ??
                                  true)
                              : (_tempUserFilterOptions['showActiveOnly'] ??
                                  true))
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      duration: Duration(milliseconds: 200),
                      child: Container(
                        width: 20, // Increased from 12
                        height: 20, // Increased from 12
                        margin: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isFarmer = userProvider.isFarmer;

    final sortedBarangays = List.from(widget.barangayManager.barangays)
      ..sort((a, b) => a.name.compareTo(b.name));
    final filteredProducts = _getFilteredProducts();

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        border: Border(
          left: BorderSide(
              color: theme.cardTheme.surfaceTintColor ?? Colors.grey,
              width: 2.0),
        ),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
                onPressed: widget.onClose,
              ),
              Expanded(
                child: Text(
                  'Filters',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.filter_list, color: theme.iconTheme.color),
                color: theme.cardTheme.color,
                surfaceTintColor: theme.cardTheme.color,
                padding: EdgeInsets.zero,
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem(
                      padding: EdgeInsets.zero,
                      height: 0, // This removes the default height constraint
                      child: StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return Container(
                            padding: EdgeInsets.all(
                                8), // Add padding only inside the container
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Farm Type Filters',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Divider(color: Colors.white.withOpacity(0.5)),
                                ..._tempFilterOptions.entries.map((entry) {
                                  return CheckboxListTile(
                                    title: Text(
                                      entry.key,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(),
                                    ),
                                    value: entry.value,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _tempFilterOptions[entry.key] =
                                            value ?? false;
                                      });
                                    },
                                    checkColor: Colors.white,
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                  );
                                }).toList(),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
          SizedBox(height: 16),

          // Toggle buttons for Barangay/Product filters
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: theme.colorScheme.surface.withOpacity(0.1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => showProductFilter = false),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: !showProductFilter
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                      ),
                      child: Text(
                        'Barangays',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: !showProductFilter
                              ? Colors.white
                              : theme.textTheme.bodyMedium?.color,
                          fontWeight: !showProductFilter
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => showProductFilter = true),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: showProductFilter
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                      ),
                      child: Text(
                        'Products',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: showProductFilter
                              ? Colors.white
                              : theme.textTheme.bodyMedium?.color,
                          fontWeight: showProductFilter
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12),

          // User-based filter - NEW PLACEMENT
          _buildUserFilterToggle(theme, isFarmer),

          SizedBox(height: 16),

          Text(
            showProductFilter ? 'Products' : 'Barangays',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: showProductFilter
                  ? 'Search products...'
                  : 'Search barangays...',
              prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) => setState(() => searchQuery = value),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                child: Text(context.translate('Select All'),
                    style: TextStyle(color: theme.colorScheme.primary)),
                onPressed: () => showProductFilter
                    ? _toggleAllProducts(true)
                    : _toggleAllBarangays(true),
              ),
              TextButton(
                child: Text(context.translate('Clear All'),
                    style: TextStyle(color: theme.colorScheme.primary)),
                onPressed: () => showProductFilter
                    ? _toggleAllProducts(false)
                    : _toggleAllBarangays(false),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              children: showProductFilter
                  ? filteredProducts.map((product) {
                      return CheckboxListTile(
                        title: Text(_getProductDisplayName(product),
                            style: theme.textTheme.bodyMedium),
                        value: _tempSelectedProducts.contains(product),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              if (!_tempSelectedProducts.contains(product)) {
                                _tempSelectedProducts.add(product);
                              }
                            } else {
                              _tempSelectedProducts.remove(product);
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: theme.colorScheme.primary,
                        checkColor: Colors.white,
                      );
                    }).toList()
                  : sortedBarangays
                      .where((barangay) => barangay.name
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase()))
                      .map((barangay) {
                      return CheckboxListTile(
                        title: Text(barangay.name,
                            style: theme.textTheme.bodyMedium),
                        value: _tempSelectedBarangays.contains(barangay.name),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              if (!_tempSelectedBarangays
                                  .contains(barangay.name)) {
                                _tempSelectedBarangays.add(barangay.name);
                              }
                            } else {
                              _tempSelectedBarangays.remove(barangay.name);
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: theme.colorScheme.primary,
                        checkColor: Colors.white,
                      );
                    }).toList(),
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              widget.onFiltersChanged(
                  List.from(_tempSelectedBarangays),
                  List.from(_tempSelectedProducts),
                  Map.from(_tempFilterOptions),
                  Map.from(_tempUserFilterOptions));
              widget.onClose();
            },
            child: Text(context.translate('Apply Filters')),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 40),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
