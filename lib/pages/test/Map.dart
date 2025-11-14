import 'package:flareline/pages/farmers/farmer/farmer_bloc.dart';
import 'package:flareline/pages/products/product/product_bloc.dart';
import 'package:flareline/pages/test/map_widget/farm_service.dart';
import 'package:flareline/repositories/farmer_repository.dart';
import 'package:flareline/repositories/product_repository.dart';
import 'package:flutter/material.dart';
import 'package:flareline/pages/layout.dart';
import 'package:flareline/pages/test/map_widget/map_widget.dart';
import 'package:flareline/services/api_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class Map extends LayoutWidget {
  const Map({super.key, required this.routeObserver});

  final RouteObserver<PageRoute> routeObserver;

  @override
  bool get showTitle => false;

  @override
  String breakTabTitle(BuildContext context) {
    return "";
  }

  @override
  Widget contentDesktopWidget(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => ApiService()),
        RepositoryProvider(
            create: (_) => FarmService(RepositoryProvider.of<ApiService>(_))),
        RepositoryProvider(
            create: (_) => ProductRepository(
                apiService: RepositoryProvider.of<ApiService>(_))),
        RepositoryProvider(
            create: (_) => FarmerRepository(
                apiService: RepositoryProvider.of<ApiService>(_))),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => ProductBloc(
              productRepository:
                  RepositoryProvider.of<ProductRepository>(context),
            )..add(LoadProducts()),
          ),
          BlocProvider(
            create: (context) => FarmerBloc(
              farmerRepository:
                  RepositoryProvider.of<FarmerRepository>(context),
            )..add(LoadFarmers()),
          ),
        ],
        child: Builder(
          builder: (context) {
            final farmService = RepositoryProvider.of<FarmService>(context);

            return BlocBuilder<ProductBloc, ProductState>(
              builder: (context, productState) {
                return BlocBuilder<FarmerBloc, FarmerState>(
                  builder: (context, farmerState) {
// Solution 2: Use SizedBox with full height and Center
                    if (productState is ProductsLoading &&
                        farmerState is FarmersLoading) {
                      return SizedBox(
                        height: MediaQuery.of(context).size.height,
                        child: Center(
                          child: LoadingAnimationWidget.inkDrop(
                            color: Colors.blue,
                            size: 50,
                          ),
                        ),
                      );
                    }
// Replace your current error handling with this:
                    if (productState is ProductsError ||
                        farmerState is FarmersError) {
                      String errorMessage = '';
                      bool isFarmerError = farmerState is FarmersError;
                      bool isProductError = productState is ProductsError;

                      if (isProductError && isFarmerError) {
                        errorMessage =
                            'Failed to load both products and farmers';
                      } else if (isProductError) {
                        errorMessage =
                            'Failed to load products: ${(productState as ProductsError).message}';
                      } else if (isFarmerError) {
                        errorMessage =
                            'Failed to load farmers: ${(farmerState as FarmersError).message}';

                        // Add specific retry for farmers
                        Future.delayed(Duration.zero, () {
                          context.read<FarmerBloc>().add(LoadFarmers());
                        });
                      }

                      return SizedBox(
                        height: MediaQuery.of(context).size.height,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 50,
                              ),
                              SizedBox(height: 16),
                              Text(errorMessage,
                                  style: TextStyle(color: Colors.red)),
                              SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isFarmerError)
                                    ElevatedButton(
                                      onPressed: () {
                                        context
                                            .read<FarmerBloc>()
                                            .add(LoadFarmers());
                                      },
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor:
                                            Theme.of(context).primaryColor,
                                        backgroundColor:
                                            Theme.of(context).cardTheme.color,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text('Retry Farmers'),
                                    ),
                                  const SizedBox(width: 12),
                                  if (isProductError)
                                    ElevatedButton(
                                      onPressed: () {
                                        context
                                            .read<ProductBloc>()
                                            .add(LoadProducts());
                                      },
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor:
                                            Theme.of(context).primaryColor,
                                        backgroundColor:
                                            Theme.of(context).cardTheme.color,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text('Retry Products'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Both data loaded successfully
                    if (productState is ProductsLoaded &&
                        farmerState is FarmersLoaded) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          return MapWidget(
                            routeObserver: routeObserver,
                            farmService: farmService,
                            products: productState.products,
                            farmers: farmerState.farmers,
                          );
                        },
                      );
                    }

                    // If we have partial data, show what we have
                    if (productState is ProductsLoaded ||
                        farmerState is FarmersLoaded) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          return MapWidget(
                            routeObserver: routeObserver,
                            farmService: farmService,
                            products: productState is ProductsLoaded
                                ? productState.products
                                : [],
                            farmers: farmerState is FarmersLoaded
                                ? farmerState.farmers
                                : [],
                          );
                        },
                      );
                    }

                    // Fallback - should theoretically never reach here
                    return const Center(child: Text('Unexpected state'));
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  @override
  EdgeInsetsGeometry? get customPadding => const EdgeInsets.only(top: 0);

  @override
  PreferredSizeWidget? appBarWidget(BuildContext context) {
    return AppBar(
      title: Text(breakTabTitle(context)),
      centerTitle: true,
      elevation: 0,
    );
  }

  @override
  Widget loadingWidget(BuildContext context) {
    return Center(
      child: LoadingAnimationWidget.inkDrop(
        color: Colors.blue,
        size: 50,
      ),
    );
  }
}
