import 'package:flareline/pages/toast/toast_helper.dart';
import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/modal/modal_dialog.dart';
import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/pages/yields/yield_bloc/yield_bloc.dart';
import 'package:flareline/core/models/yield_model.dart';

class SectorProductSelectionModal {
  // Store selections per sector
  static final Map<String, List<String>> _sectorSelections = {};
  static String? _currentSector;

  static void show({
    required BuildContext context,
    required String sector,
    int maxProducts = 8,
    required Function(List<String>) onProductsSelected,
    List<String>? initialSelections,
  }) {
    bool isLoading = true;
    List<String> allProducts = [];

    print('initialSelections');
    print(initialSelections);

    // Reset if sector has changed
    if (_currentSector != null && _currentSector != sector) {
      _sectorSelections.remove(_currentSector);
    }
    _currentSector = sector;

    // Initialize selected products - prioritize initialSelections if provided
    List<String> selectedProducts = [];
    if (initialSelections != null) {
      selectedProducts = initialSelections.take(maxProducts).toList();
    } else if (_sectorSelections.containsKey(sector)) {
      selectedProducts = _sectorSelections[sector]!.take(maxProducts).toList();
    }

    // Initialize with yield data if already loaded
    final yieldBloc = context.read<YieldBloc>();
    if (yieldBloc.state is YieldsLoaded) {
      final yields = (yieldBloc.state as YieldsLoaded).yields;
      final sectorYields = yields.where((y) => y.sector == sector).toList();
      allProducts =
          sectorYields.map((y) => y.productName ?? 'Unknown').toSet().toList();

      // If no initial selections, choose first products up to maxProducts
      if (selectedProducts.isEmpty && allProducts.isNotEmpty) {
        selectedProducts = allProducts.take(maxProducts).toList();
      }

      // Ensure we don't exceed maxProducts
      if (selectedProducts.length > maxProducts) {
        selectedProducts = selectedProducts.take(maxProducts).toList();
      }

      _sectorSelections[sector] = List.from(selectedProducts);
      isLoading = false;
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 600;

    ModalDialog.show(
      context: context,
      title: '$sector Products',
      showTitle: true,
      showTitleDivider: true,
      modalType: isSmallScreen ? ModalType.small : ModalType.medium,
      onCancelTap: () => Navigator.of(context).pop(),
      onSaveTap: () {
        // Save the current selection for this sector
        _sectorSelections[sector] = List.from(selectedProducts);
        Navigator.of(context).pop();
        onProductsSelected(selectedProducts);
      },
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          // Listen to yield bloc updates
          yieldBloc.stream.listen((state) {
            if (state is YieldsLoaded) {
              final yields = state.yields;
              final sectorYields =
                  yields.where((y) => y.sector == sector).toList();
              final products = sectorYields
                  .map((y) => y.productName ?? 'Unknown')
                  .toSet()
                  .toList();

              setModalState(() {
                allProducts = products;

                // If we have existing selections, filter them to only include valid products
                selectedProducts = selectedProducts
                    .where((product) => products.contains(product))
                    .take(maxProducts)
                    .toList();

                // If we don't have enough selections, add more up to maxProducts
                if (selectedProducts.length < maxProducts) {
                  final remaining = maxProducts - selectedProducts.length;
                  final newProducts = products
                      .where((product) => !selectedProducts.contains(product))
                      .take(remaining)
                      .toList();
                  selectedProducts.addAll(newProducts);
                }

                _sectorSelections[sector] = List.from(selectedProducts);
                isLoading = false;
              });
            } else if (state is YieldsLoading) {
              setModalState(() => isLoading = true);
            }
          });

          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (allProducts.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('No products found for $sector sector'),
            );
          }

          return Padding(
            padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select up to $maxProducts products',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: allProducts.map((product) {
                    final isSelected = selectedProducts.contains(product);
                    return FilterChip(
                      label: Text(product),
                      selected: isSelected,
                      onSelected: (selected) {
                        setModalState(() {
                          if (selected) {
                            if (selectedProducts.length < maxProducts) {
                              selectedProducts.add(product);
                            } else {
                              ToastHelper.showErrorToast(
                                'Maximum $maxProducts products allowed',
                                context,
                              );
                            }
                          } else {
                            selectedProducts.remove(product);
                          }
                        });
                      },
                      selectedColor:
                          Theme.of(context).primaryColor.withOpacity(0.2),
                      checkmarkColor: Theme.of(context).primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.black,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
      footer: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth < 600 ? 10.0 : 20.0,
          vertical: 10.0,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: screenWidth < 600 ? 100 : 120,
                child: ButtonWidget(
                  btnText: 'Cancel',
                  textColor: FlarelineColors.darkBlackText,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              SizedBox(width: screenWidth < 600 ? 10 : 20),
              SizedBox(
                width: screenWidth < 600 ? 100 : 120,
                child: ButtonWidget(
                  btnText: 'Confirm',
                  onTap: () {
                    // Save the current selection for this sector
                    _sectorSelections[sector] = List.from(selectedProducts);
                    Navigator.of(context).pop();
                    onProductsSelected(selectedProducts);
                  },
                  type: ButtonType.primary.type,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Optional: Clear all stored selections
  static void clearSelections() {
    _sectorSelections.clear();
    _currentSector = null;
  }
}
