import 'package:flareline/core/models/yield_model.dart';
import 'package:flareline/pages/dashboard/map/map_chart_ui.dart';
import 'package:flareline/pages/products/product/product_bloc.dart';
import 'package:flareline/pages/yields/yield_bloc/yield_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_maps/maps.dart';
import 'package:provider/provider.dart';
import 'barangay_data_provider.dart';

class MapChartWidget extends StatefulWidget {
  final int selectedYear;
  final String? selectedProduct;

  const MapChartWidget({
    super.key,
    required this.selectedYear,
    this.selectedProduct,
  });

  

  @override
  State<MapChartWidget> createState() => _MapChartWidgetState();
}

class _MapChartWidgetState extends State<MapChartWidget> {
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;

    // Only load data if not already available
    final productState = context.read<ProductBloc>().state;
    final yieldState = context.read<YieldBloc>().state;

    final needsProductLoad = productState is! ProductsLoaded;
    final needsYieldLoad = yieldState is! YieldsLoaded;

    if (needsProductLoad || needsYieldLoad) {
 
      _loadData();
    } else {
  
    }
  }

  void _loadData({bool forceRefresh = false}) {
 
    context.read<YieldBloc>().add(LoadYields());
    context.read<ProductBloc>().add(LoadProducts());
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MultiBlocListener(
      listeners: [
        BlocListener<ProductBloc, ProductState>(
          listener: (context, state) {
            if (state is ProductsError) {
              // Handle error if needed
            }
          },
        ),
        BlocListener<YieldBloc, YieldState>(
          listener: (context, state) {
            if (state is YieldsError) {
              // Handle error if needed
            }
          },
        ),
      ],
      child: BlocBuilder<ProductBloc, ProductState>(
        builder: (productContext, productState) {
         
          // Handle product loading states first
          if (productState is ProductsLoading) {
    
            return MapChartUIComponents.buildLoadingState();
          } else if (productState is ProductsError) {
            return MapChartUIComponents.buildErrorState(
              context,
              productState.message,
              () => _loadData(forceRefresh: true),
            );
          }

          // Get products list
          List<String> products = [];
          if (widget.selectedProduct != null) {
            products = [widget.selectedProduct!];
          } else if (productState is ProductsLoaded) {
            products = productState.products.map((p) => p.name).toList();
 
          }

          return BlocBuilder<YieldBloc, YieldState>(
            builder: (yieldContext, yieldState) {
            
              if (yieldState is YieldsLoading) {
        
                return MapChartUIComponents.buildLoadingState();
              } else if (yieldState is YieldsError) {
                return MapChartUIComponents.buildErrorState(
                  context,
                  yieldState.message,
                  () => _loadData(forceRefresh: true),
                );
              }

              // Get yields list
              List<Yield> yields = [];
              if (yieldState is YieldsLoaded) {
                yields = yieldState.yields;
     
              }

           
              return _buildMapsLayout(context, products, yields);
            },
          );
        },
      ),
    );
  }

  Widget _buildMapsLayout(
      BuildContext context, List<String> products, List<Yield> yields) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Barangay Map',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.normal,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: theme.iconTheme.color,
                ),
                onPressed: () => _loadData(forceRefresh: true),
                tooltip: 'Reload Data',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
              ),
              child: Padding(
                padding: const EdgeInsets.all(0),
                child: _buildMapContent(context, products, yields, theme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapContent(BuildContext context, List<String> products,
      List<Yield> yields, ThemeData theme) {
    // Check if there's no yield data
    if (yields.isEmpty) {
      return _buildNoDataIndicator(theme);
    }

    // Filter yields for the selected year (extracted from harvestDate)
    final selectedYear = widget.selectedYear;
    final filteredYields = yields
        .where((yield) => yield.harvestDate.year == selectedYear)
        .toList();

    if (filteredYields.isEmpty) {
      return _buildNoDataIndicator(theme, forYear: selectedYear);
    }

    // If we have a selected product, check if there's data for that specific product
    if (widget.selectedProduct != null) {
      final productYields = filteredYields
          .where((yield) =>
              yield.productName?.toLowerCase() ==
              widget.selectedProduct!.toLowerCase())
          .toList();

      if (productYields.isEmpty) {
        return _buildNoDataIndicator(theme,
            forYear: selectedYear, forProduct: widget.selectedProduct);
      }
    }

    return ChangeNotifierProvider(
      create: (context) {
   
        return BarangayDataProvider(
          initialProducts: products,
          yields: yields,
          selectedYear: widget.selectedYear,
          initialSelectedProduct: widget.selectedProduct,
        );
      },
      builder: (ctx, child) {
        final provider = ctx.watch<BarangayDataProvider>();

   
        if (provider.isLoading) {
          
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          );
        }
 

        final MapZoomPanBehavior zoomPanBehavior = MapZoomPanBehavior(
          enableDoubleTapZooming: true,
          enableMouseWheelZooming: false,
          enablePinching: true,
          zoomLevel: 1,
          minZoomLevel: 1,
          maxZoomLevel: 15,
          enablePanning: true,
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            // Only show product selector if no product is pre-selected
            final bool showProductSelector = widget.selectedProduct == null;

            if (constraints.maxWidth < 800) {
              return Column(
                children: [
                  if (showProductSelector) ...[
                    // Show selected products chips if any products are selected
             
                    // Show product selector for adding new products
                    MapChartUIComponents.buildProductSelector(
                        provider, context),
                    const SizedBox(height: 16),

                           if (provider.selectedProducts.isNotEmpty) ...[
                      MapChartUIComponents.buildSelectedProductsChips(
                          provider, context), 
                    ],
                  ],
                  Expanded(
                    flex: 3,
                    child: MapChartUIComponents.buildMap(
                        provider, zoomPanBehavior, context),
                  ),
                ],
              );
            }
            return Column(
              children: [
                if (showProductSelector) ...[
                  // Show selected products chips if any products are selected
              
                  // Show product selector for adding new products
                  MapChartUIComponents.buildProductSelector(provider, context),
                  const SizedBox(height: 16),

                      if (provider.selectedProducts.isNotEmpty) ...[
                    MapChartUIComponents.buildSelectedProductsChips(
                        provider, context),
              
                  ],
                ],
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: MapChartUIComponents.buildMap(
                            provider, zoomPanBehavior, context),
                      ),
                      const SizedBox(width: 16),
                      MapChartUIComponents.buildBarangayList(provider, context),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildNoDataIndicator(ThemeData theme,
      {int? forYear, String? forProduct}) {
    String message = 'No yield data available';
    String subtitle =
        'There is currently no yield information to display on the map.';

    if (forYear != null && forProduct != null) {
      message = 'No data for $forProduct in $forYear';
      subtitle =
          'There is no yield data available for $forProduct in the year $forYear.';
    } else if (forYear != null) {
      message = 'No data for $forYear';
      subtitle = 'There is no yield data available for the year $forYear.';
    } else if (forProduct != null) {
      message = 'No data for $forProduct';
      subtitle = 'There is no yield data available for $forProduct.';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 80,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _loadData(forceRefresh: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Reload Data'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}