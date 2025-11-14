// ignore_for_file: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member

import 'package:flareline/pages/products/product/product_bloc.dart';
import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flareline_uikit/components/modal/modal_dialog.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/repositories/product_repository.dart';
import 'package:flareline/core/models/product_model.dart';

void showProductsModal(
  BuildContext context, {
  required Function(List<String>) onProductsSelected,
  List<String> initialSelection = const [],
}) {
  // Get products from ProductBloc
  final productBloc = BlocProvider.of<ProductBloc>(context);
  final List<Product> allProductsFromBloc = productBloc.allProducts;

  // Convert to format "id: name"
  final List<String> allProducts = allProductsFromBloc
      .map((product) => '${product.id}: ${product.name}')
      .toList();

  final double screenWidth = MediaQuery.of(context).size.width;

  // State management
  final selectedProducts = <String>{...initialSelection};
  final searchController = TextEditingController();
  final filteredProducts = ValueNotifier<List<String>>(allProducts);
  final focusNode = FocusNode();

  // Search function
  void filterProducts(String query) {
    if (query.isEmpty) {
      filteredProducts.value = allProducts;
    } else {
      filteredProducts.value = allProducts
          .where(
              (product) => product.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  ModalDialog.show(
    context: context,
    title: 'Select Products',
    showTitle: true,
    showTitleDivider: true,
    modalType: ModalType.medium,
    onCancelTap: () => Navigator.of(context).pop(),
    onSaveTap: () {
      onProductsSelected(selectedProducts.toList());
      Navigator.of(context).pop();
    },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search input (Material 3 style)
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: SearchBar(
            controller: searchController,
            focusNode: focusNode,
            hintText: 'Search products...',
            leading: const Icon(Icons.search),
            trailing: [
              if (searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    searchController.clear();
                    filterProducts('');
                    focusNode.unfocus();
                  },
                ),
            ],
            onChanged: filterProducts,
            elevation: MaterialStateProperty.all(1.0),
            shape: MaterialStateProperty.all(
              const ContinuousRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
        ),
        // Select All checkbox
        SizedBox(
          height: 48,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (selectedProducts.length == allProducts.length) {
                  selectedProducts.clear();
                } else {
                  selectedProducts.addAll(allProducts);
                }
                filteredProducts.notifyListeners();
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Checkbox(
                      value: selectedProducts.length == allProducts.length,
                      onChanged: (value) {
                        if (value == true) {
                          selectedProducts.addAll(allProducts);
                        } else {
                          selectedProducts.clear();
                        }
                        filteredProducts.notifyListeners();
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      visualDensity: VisualDensity.compact,
                      activeColor: FlarelineColors.primary,
                      checkColor: Colors.white,
                    ),
                    const Text(
                      'Select All',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Divider
        const Divider(height: 1),
        // Products list with checkboxes
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: ValueListenableBuilder<List<String>>(
            valueListenable: filteredProducts,
            builder: (context, filteredList, _) {
              if (filteredList.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No products found'),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final product = filteredList[index];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (selectedProducts.contains(product)) {
                          selectedProducts.remove(product);
                        } else {
                          selectedProducts.add(product);
                        }
                        filteredProducts.notifyListeners();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          children: [
                            Checkbox(
                              value: selectedProducts.contains(product),
                              onChanged: (value) {
                                if (value == true) {
                                  selectedProducts.add(product);
                                } else {
                                  selectedProducts.remove(product);
                                }
                                filteredProducts.notifyListeners();
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              visualDensity: VisualDensity.compact,
                              activeColor: FlarelineColors.primary,
                              checkColor: Colors.white,
                            ),
                            Text(
                              product,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
    footer: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
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
            const SizedBox(width: 20),
            SizedBox(
              width: screenWidth < 600 ? 100 : 120,
              child: ButtonWidget(
                btnText: 'Apply',
                onTap: () {
                  onProductsSelected(selectedProducts.toList());
                  Navigator.of(context).pop();
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
