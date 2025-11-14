import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/pages/layout.dart';
import 'package:flareline/pages/products/products_table.dart';
import 'package:flareline/pages/products/product/product_bloc.dart';
import 'package:flareline/repositories/product_repository.dart';
import 'package:flareline/services/api_service.dart';

class ProductsPage extends LayoutWidget {
  const ProductsPage({super.key});

  @override
  String breakTabTitle(BuildContext context) {
    return 'Products';
  }

  @override
  Widget contentDesktopWidget(BuildContext context) {
    return RepositoryProvider(
      create: (context) => ProductRepository(apiService: ApiService()),
      child: BlocProvider(
        create: (context) => ProductBloc(
          productRepository: RepositoryProvider.of<ProductRepository>(context),
        )..add(LoadProducts()),
        child: Builder(
          builder: (context) {
            return Column(
              children: [
                const SizedBox(height: 16),
                const ProductsTable(),
              ],
            );
          },
        ),
      ),
    );
  }
}
