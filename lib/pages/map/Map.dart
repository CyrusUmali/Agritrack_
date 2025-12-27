import 'package:flareline/pages/farmers/farmer/farmer_bloc.dart';
import 'package:flareline/pages/products/product/product_bloc.dart';
import 'package:flareline/pages/map/map_widget/farm_service.dart';
import 'package:flareline/repositories/farmer_repository.dart';
import 'package:flareline/repositories/product_repository.dart';
import 'package:flutter/material.dart';
import 'package:flareline/pages/layout.dart';
import 'package:flareline/pages/map/map_widget/map_widget.dart';
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
                    // Loading state
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

                    // Error state
                    if (productState is ProductsError ||
                        farmerState is FarmersError) {
                      String errorMessage = '';
                      List<Widget> retryButtons = [];

                      // Determine error messages
                      if (productState is ProductsError) {
                        errorMessage = productState.message;
                      }
                      if (farmerState is FarmersError) {
                        errorMessage = farmerState.message;
                      }
                      if (productState is ProductsError &&
                          farmerState is FarmersError) {
                        errorMessage = 'Failed to load data';
                      }

                      // Add retry buttons for each failed state
                      // if (productState is ProductsError) {
                      //   retryButtons.add(
                      //     _buildRetryButton(
                      //       context,
                      //       label: 'Retry Products',
                      //       onPressed: () => context
                      //           .read<ProductBloc>()
                      //           .add(LoadProducts()),
                      //     ),
                      //   );
                      // }

                      // if (farmerState is FarmersError) {
                      //   retryButtons.add(
                      //     _buildRetryButton(
                      //       context,
                      //       label: 'Retry Farmers',
                      //       onPressed: () => context
                      //           .read<FarmerBloc>()
                      //           .add(LoadFarmers()),
                      //     ),
                      //   );
                      // }

                      // Add retry all button if both failed
                      if (productState is ProductsError ||
                          farmerState is FarmersError) {
                        retryButtons.add(
                          _buildRetryButton(
                            context,
                            label: 'Retry ',
                            onPressed: () {
                              context.read<ProductBloc>().add(LoadProducts());
                              context.read<FarmerBloc>().add(LoadFarmers());
                            },
                          ),
                        );
                      }

                      return _buildErrorWidget(
                        context,
                        errorMessage: errorMessage,
                        retryButtons: retryButtons,
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
                    return _buildErrorWidget(
                      context,
                      errorMessage: 'Unexpected state occurred',
                      retryButtons: [
                        _buildRetryButton(
                          context,
                          label: 'Retry All',
                          onPressed: () {
                            context.read<ProductBloc>().add(LoadProducts());
                            context.read<FarmerBloc>().add(LoadFarmers());
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Helper method to build retry button
  Widget _buildRetryButton(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Theme.of(context).primaryColor,
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  // Helper method to build error widget
  Widget _buildErrorWidget(
    BuildContext context, {
    required String errorMessage,
    required List<Widget> retryButtons,
  }) {
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
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (retryButtons.isNotEmpty)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: retryButtons,
              ),
          ],
        ),
      ),
    );
  }

  @override
  EdgeInsetsGeometry? get customPadding => const EdgeInsets.only(top: 0);

  PreferredSizeWidget? appBarWidget(BuildContext context) {
    return AppBar(
      title: Text(breakTabTitle(context)),
      centerTitle: true,
      elevation: 0,
    );
  }

  Widget loadingWidget(BuildContext context) {
    return Center(
      child: LoadingAnimationWidget.inkDrop(
        color: Colors.blue,
        size: 50,
      ),
    );
  }
}