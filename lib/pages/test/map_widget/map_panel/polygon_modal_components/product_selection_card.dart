import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flutter/material.dart';
import 'package:flareline/core/theme/global_colors.dart';

class ProductSelectionCard extends StatelessWidget {
  final List<String> products;
  final String selectedProduct;
  final ValueChanged<String> onProductSelected;
  final bool isVertical;
  final String? Function(String) getProductImage;

  const ProductSelectionCard({
    super.key,
    required this.products,
    required this.selectedProduct,
    required this.onProductSelected,
    required this.isVertical,
    required this.getProductImage,
  });

  bool isDarkTheme(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                Icon(Icons.agriculture_outlined,
                    size: 20, color: colorScheme.onSurface.withOpacity(0.6)),
                const SizedBox(width: 8),
                Text(
                  'Select Product',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: isVertical ? null : 100,
              child: products.isEmpty
                  ? const Center(child: Text('No products available'))
                  : isVertical
                      ? _buildVerticalProductList(theme)
                      : _buildHorizontalProductList(theme),
            ),
          ],
        ),
      ),
    );
  }

//  return SizedBox(
//       height: 200,
//       child: SingleChildScrollView(
//         child: Column(
  // children: products.map((product) {
  //   final isSelected = _se

  Widget _buildVerticalProductList(ThemeData theme) {
    return SizedBox(
        height: 200,
        child: SingleChildScrollView(
          child: Column(
            children: products.map((product) {
              final isSelected = selectedProduct == product;
              final productImage = getProductImage(product);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => onProductSelected(product),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected
                          ? theme.primaryColor.withOpacity(0.1)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? theme.primaryColor
                            : theme.dividerColor,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: productImage != null
                              ? NetworkImage(productImage)
                              : null,
                          child: productImage == null
                              ? const Icon(Icons.eco, size: 20)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            product,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected ? theme.primaryColor : null,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, color: theme.primaryColor),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ));
  }

  Widget _buildHorizontalProductList(ThemeData theme) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: products.length,
      separatorBuilder: (context, index) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final product = products[index];
        final productImage = getProductImage(product);
        return ChoiceChip(
          label: Text(product),
          selected: selectedProduct == product,
          onSelected: (selected) => onProductSelected(product),
          avatar: CircleAvatar(
            backgroundImage:
                productImage != null ? NetworkImage(productImage) : null,
            child:
                productImage == null ? const Icon(Icons.eco, size: 16) : null,
          ),
          labelPadding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color.fromARGB(255, 74, 76, 80)
              : Colors.grey.shade100,
          selectedColor: Theme.of(context).brightness == Brightness.dark
              ? FlarelineColors.darkerBackground
              : theme.primaryColor.withOpacity(0.2),
        );
      },
    );
  }
}
