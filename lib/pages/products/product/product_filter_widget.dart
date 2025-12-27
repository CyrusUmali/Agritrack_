import 'package:flareline/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/pages/products/add_product_modal.dart';
import 'package:flareline/pages/products/product/product_bloc.dart'; 
import 'package:provider/provider.dart';

class ProductFilterWidget extends StatelessWidget {
  const ProductFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardTheme = theme.cardTheme;
    final iconTheme = theme.iconTheme;
    final textTheme = theme.textTheme;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isFarmer = userProvider.isFarmer;
    return Container(
      decoration: BoxDecoration(
        color: cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: cardTheme.surfaceTintColor ?? Colors.grey[300]!,
        ),
        boxShadow: [
          BoxShadow(
            color: cardTheme.shadowColor ?? Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: textTheme.bodyMedium?.copyWith(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: TextStyle(color: theme.hintColor),
                prefixIcon: Icon(Icons.search, color: iconTheme.color),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (query) {
                context.read<ProductBloc>().add(SearchProducts(query));
              },
            ),
          ),
          VerticalDivider(
            thickness: 1,
            indent: 8,
            endIndent: 8,
            color: cardTheme.surfaceTintColor ?? Colors.grey[300],
          ),
          BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              final sectorFilter = context.read<ProductBloc>().sectorFilter;
              return DropdownButton<String>(
                value: sectorFilter,
                underline: Container(),
                icon: Icon(
                  Icons.arrow_drop_down,
                  size: 24,
                  color: iconTheme.color,
                ),
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: textTheme.bodyMedium?.color,
                ),
                dropdownColor: cardTheme.color,
                items: const [
                  DropdownMenuItem(value: "All", child: Text("All Sectors")),
                  DropdownMenuItem(value: "Rice", child: Text("Rice")),
                  DropdownMenuItem(
                      value: "Livestock", child: Text("Livestock")),
                  DropdownMenuItem(value: "Fishery", child: Text("Fishery")),
                  DropdownMenuItem(value: "Corn", child: Text("Corn")),
                  DropdownMenuItem(value: "HVC", child: Text("HVC")),
                  DropdownMenuItem(value: "Organic", child: Text("Organic")), 
                ],
                onChanged: (value) {
                  context.read<ProductBloc>().add(FilterProducts(value!));
                },
              );
            },
          ),
          VerticalDivider(
            thickness: 1,
            indent: 8,
            endIndent: 8,
            color: cardTheme.surfaceTintColor ?? Colors.grey[300],
          ),
          if (!isFarmer)
            IconButton(
              icon: Icon(Icons.add, color: theme.primaryColor),
              onPressed: () => AddProductModal.show(context),
              tooltip: 'Add Product',
            ),
        ],
      ),
    );
  }
}
