import 'package:flareline/core/models/product_model.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/pages/products/product/product_filter_widget.dart';
import 'package:flareline/pages/toast/toast_helper.dart';
import 'package:flareline/pages/widget/network_error.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:flareline/pages/products/product/product_bloc.dart';
import 'package:flareline/pages/products/product_profile.dart';
import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flareline_uikit/components/modal/modal_dialog.dart';
import 'package:flareline_uikit/components/tables/table_widget.dart';
import 'package:flareline_uikit/entity/table_data_entity.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:toastification/toastification.dart';

class ProductsTable extends StatelessWidget {
  const ProductsTable({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout.builder(
      desktop: (context) => _productsWeb(context),
      mobile: (context) => _productsMobile(context),
      tablet: (context) => _productsMobile(context),
    );
  }

  Widget _productsWeb(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    double height;

    if (screenHeight < 400) {
      height = screenHeight * 0.7; // 70% for very small screens (old phones)
      // print('📏 Using SMALL screen height: 70% ($height)');
    } else if (screenHeight < 600) {
      height = screenHeight * 0.65; // 65% for small screens
      // print('📏 Using MEDIUM-SMALL screen height: 65% ($height)');
    } else if (screenHeight < 800) {
      height = screenHeight * 0.7; // 75% for medium screens (most phones)
      // print('📏 Using MEDIUM screen height: 75% ($height)');
    } else if (screenHeight < 1000) {
      height = screenHeight * 0.75; // 70% for large phones/tablets
      // print('📏 Using LARGE screen height: 70% ($height)');
    } else if (screenHeight < 1200) {
      height = screenHeight * 0.6; // 60% for small tablets
      // print('📏 Using TABLET screen height: 60% ($height)');
    } else if (screenHeight < 1600) {
      height = screenHeight * 0.5; // 50% for medium tablets
      // print('📏 Using LARGE TABLET screen height: 50% ($height)');
    } else {
      height = screenHeight * 0.4; // 40% for desktop/large screens
      // print('📏 Using DESKTOP screen height: 40% ($height)');
    }

    return BlocListener<ProductBloc, ProductState>(
      listenWhen: (previous, current) {
        return current is ProductsLoaded || current is ProductsError;
      },
      listener: (context, state) {
        if (state is ProductsLoaded && state.message != null) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.flat,
            title: Text(state.message!),
            alignment: Alignment.topRight,
            showProgressBar: false,
            autoCloseDuration: const Duration(seconds: 3),
          );
        } else if (state is ProductsError) {
          ToastHelper.showErrorToast(state.message, context, maxLines: 3);
        }
      },
      child: SizedBox(
        // height: 600,
        height: height,
        // height: MediaQuery.of(context).size.height * 0.80,

        child: Column(
          children: [
            const ProductFilterWidget(),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<ProductBloc, ProductState>(
                builder: (context, state) {
                  if (state is ProductsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ProductsError) {
                    return NetworkErrorWidget(
                      error: state.message,
                      onRetry: () {
                        context.read<ProductBloc>().add(LoadProducts());
                      },
                    );
                  } else if (state is ProductsLoaded) {
                    if (state.products.isEmpty) {
                      return _buildNoResultsWidget();
                    }
                    return Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DataTableWidget(
                            // Use a more comprehensive key that includes sort info
                            key: ValueKey(
                                'products_table_${state.products.length}_${context.read<ProductBloc>().sortColumn}_${context.read<ProductBloc>().sortAscending}'),
                            // Pass the current state instead of products
                            state: state,
                          ),
                        ),
                      ],
                    );
                  }
                  return _buildNoResultsWidget();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productsMobile(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    double height;

    if (screenHeight < 400) {
      height = screenHeight * 0.6;
    } else if (screenHeight < 600) { 
      height = screenHeight * 0.50;
    } else if (screenHeight < 800) {
      height = screenHeight * 0.70;
    } else {
      height = screenHeight * 0.73;
    }  

    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state is ProductsLoaded && state.message != null) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.flat,
            title: Text(state.message!),
            alignment: Alignment.topRight,
            showProgressBar: false,
            autoCloseDuration: const Duration(seconds: 3),
          );
        } else if (state is ProductsError) {
          ToastHelper.showErrorToast(state.message, context, maxLines: 3);
        }
      },
      child: Column(
        children: [
          const ProductFilterWidget(),
          const SizedBox(height: 16),
          SizedBox(
            // height: 850,
            height: height,
            child: BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {
                if (state is ProductsLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is ProductsError) {
                  return NetworkErrorWidget(
                    error: state.message,
                    onRetry: () {
                      context.read<ProductBloc>().add(LoadProducts());
                    },
                  );
                } else if (state is ProductsLoaded) {
                  if (state.products.isEmpty) {
                    return _buildNoResultsWidget();
                  }
                  return MobileProductListWidget(
                    key: ValueKey(
                        'products_table_${state.products.length}_${context.read<ProductBloc>().sortColumn}_${context.read<ProductBloc>().sortAscending}'),
                    state: state,
                  );
                }
                return _buildNoResultsWidget();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.disabled_by_default,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Products found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filter criteria',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class DataTableWidget extends TableWidget<ProductsViewModel> {
  final ProductsLoaded state;

  DataTableWidget({
    required this.state,
    super.key,
  });

  // Add getter for products for backward compatibility
  List<Product> get products => state.products;

  @override
  ProductsViewModel viewModelBuilder(BuildContext context) {
    return ProductsViewModel(context, state);
  }

  @override
  Widget headerBuilder(
      BuildContext context, String headerName, ProductsViewModel viewModel) {
    if (headerName == 'Action') {
      return Text(headerName);
    }

    return InkWell(
      onTap: () {
        context.read<ProductBloc>().add(SortProducts(headerName));
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              headerName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              if (state is ProductsLoaded) {
                final bloc = context.read<ProductBloc>();
                return Icon(
                  bloc.sortColumn == headerName
                      ? (bloc.sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward)
                      : Icons.unfold_more,
                  size: 16,
                  color: bloc.sortColumn == headerName
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                );
              }
              return const Icon(Icons.unfold_more,
                  size: 16, color: Colors.grey);
            },
          ),
        ],
      ),
    );
  }

  @override
  void onCellTap(BuildContext context, TableDataRowsTableDataRows columnData,
      ProductsViewModel viewModel) {
    final product = viewModel.products.firstWhere(
      (p) => p.id.toString() == columnData.id,
    );

    // Navigate to YieldProfile when any cell in the row is tapped
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductProfile(product: product),
      ),
    );
  }

  @override
  Widget actionWidgetsBuilder(
    BuildContext context,
    TableDataRowsTableDataRows columnData,
    ProductsViewModel viewModel,
  ) {
    final product = viewModel.products.firstWhere(
      (p) => p.id.toString() == columnData.id,
    );
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isFarmer = userProvider.isFarmer;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isFarmer)
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              ModalDialog.show(
                context: context,
                title: 'Delete Product',
                showTitle: true,
                showTitleDivider: true,
                modalType: ModalType.medium,
                onCancelTap: () => Navigator.of(context).pop(),
                onSaveTap: () {
                  context.read<ProductBloc>().add(DeleteProduct(product.id));
                  Navigator.of(context).pop();
                },
                child: Center(
                  child: Text(
                    'Are you sure you want to delete ${product.name}?',
                    textAlign: TextAlign.center,
                  ),
                ),
                footer: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 10.0,
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 120,
                          child: ButtonWidget(
                            btnText: 'Cancel',
                            textColor: FlarelineColors.darkBlackText,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 120,
                          child: ButtonWidget(
                            btnText: 'Delete',
                            onTap: () {
                              context
                                  .read<ProductBloc>()
                                  .add(DeleteProduct(product.id));
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
            },
          ),
        IconButton(
          icon: const Icon(Icons.chevron_right_outlined),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductProfile(product: product),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout.builder(
      desktop: (context) => _buildDesktopTable(),
      mobile: (context) => _buildMobileTable(context),
      tablet: (context) => _buildMobileTable(context),
    );
  }

  Widget _buildDesktopTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double tableWidth = constraints.maxWidth > 1200
            ? 1200
            : constraints.maxWidth > 800
                ? constraints.maxWidth * 0.9
                : constraints.maxWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: SizedBox(
              width: tableWidth,
              child: super.build(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileTable(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 800,
        child: super.build(context),
      ),
    );
  }
}

class ProductsViewModel extends BaseTableProvider {
  final ProductsLoaded state;

  ProductsViewModel(
    super.context,
    this.state,
  );

  // Add getter for backward compatibility
  List<Product> get products => state.products;

  @override
  Future loadData(BuildContext context) async {
    // Use the products from the state instead of constructor
    const headers = ["Product", "Sector", "Description", "Action"];

    List<List<TableDataRowsTableDataRows>> rows = [];

    for (final product in state.products) {
      List<TableDataRowsTableDataRows> row = [];

      // Product name with image
      var productCell = TableDataRowsTableDataRows()
        ..text = product.name
        ..imageUrl = product.imageUrl
        ..dataType = CellDataType.IMAGE_TEXT.type
        ..columnName = 'Product'
        ..id = product.id.toString();
      row.add(productCell);

      // Sector
      var sectorCell = TableDataRowsTableDataRows()
        ..text = product.sector
        ..dataType = CellDataType.TEXT.type
        ..columnName = 'Sector'
        ..id = product.id.toString();
      row.add(sectorCell);

      var descCell = TableDataRowsTableDataRows()
        ..text = product.description
        ..dataType = CellDataType.TEXT.type
        ..columnName = 'Description'
        ..id = product.id.toString();
      row.add(descCell);

      // Action
      var actionCell = TableDataRowsTableDataRows()
        ..text = ""
        ..dataType = CellDataType.ACTION.type
        ..columnName = 'Action'
        ..id = product.id.toString();
      row.add(actionCell);

      rows.add(row);
    }

    TableDataEntity tableData = TableDataEntity()
      ..headers = headers
      ..rows = rows;

    tableDataEntity = tableData;
  }
}

class MobileProductListWidget extends StatefulWidget {
  final ProductsLoaded state;
  final int itemsPerPage;

  const MobileProductListWidget({
    required this.state,
    this.itemsPerPage = 10, // Default items per page
    super.key,
  });

  @override
  State<MobileProductListWidget> createState() =>
      _MobileProductListWidgetState();
}

class _MobileProductListWidgetState extends State<MobileProductListWidget> {
  int currentPage = 0;

  int get totalPages =>
      (widget.state.products.length / widget.itemsPerPage).ceil();

  List<dynamic> get currentPageData {
    final startIndex = currentPage * widget.itemsPerPage;
    final endIndex = (startIndex + widget.itemsPerPage)
        .clamp(0, widget.state.products.length);
    return widget.state.products.sublist(startIndex, endIndex);
  }

  void _goToPage(int page) {
    setState(() {
      currentPage = page.clamp(0, totalPages - 1);
    });
  }

  void _previousPage() {
    if (currentPage > 0) {
      _goToPage(currentPage - 1);
    }
  }

  void _nextPage() {
    if (currentPage < totalPages - 1) {
      _goToPage(currentPage + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.read<UserProvider>();
    final isFarmer = userProvider.isFarmer;

    if (widget.state.products.isEmpty) {
      return CommonCard(
        margin: EdgeInsets.all(0),
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text('No products available'),
        ),
      );
    }

    return Column(
      children: [
        // List content
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(0),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: currentPageData.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final product = currentPageData[index];
              final sectorIcon = _getSectorIcon(product.sector);
              final sectorColor = _getSectorColor(product.sector);

              return CommonCard(
                margin: EdgeInsets.zero,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductProfile(product: product),
                    ),
                  ),
                  onLongPress: !isFarmer
                      ? () {
                          // Show delete confirmation on long press
                          _showDeleteDialog(context, product);
                        }
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Leading icon/avatar
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: sectorColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: product.imageUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      product.imageUrl!,
                                      fit: BoxFit.cover,
                                      width: 40,
                                      height: 40,
                                      errorBuilder: (_, __, ___) =>
                                          Icon(sectorIcon, color: sectorColor),
                                    ),
                                  )
                                : Icon(sectorIcon,
                                    color: sectorColor, size: 24),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Product info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product name and sector on the same row
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      product.name,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: sectorColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      product.sector,
                                      style: TextStyle(
                                        color: sectorColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 4),

                              if (product.description?.isNotEmpty ?? false) ...[
                                Text(
                                  product.description!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Trailing icon
                        Icon(
                          Icons.chevron_right,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Pagination controls
        if (totalPages > 1)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade300,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous button
                IconButton(
                  onPressed: currentPage > 0 ? _previousPage : null,
                  icon: Icon(
                    Icons.chevron_left,
                    color: currentPage > 0 ? GlobalColors.primary : Colors.grey,
                  ),
                ),

                // Page indicators
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Show page numbers (limited to 5 visible pages)
                      ...List.generate(
                        totalPages.clamp(0, 5),
                        (index) {
                          int pageIndex;
                          if (totalPages <= 5) {
                            pageIndex = index;
                          } else {
                            // Smart pagination: show current page in center
                            int start =
                                (currentPage - 2).clamp(0, totalPages - 5);
                            pageIndex = start + index;
                          }

                          return GestureDetector(
                            onTap: () => _goToPage(pageIndex),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: currentPage == pageIndex
                                    ? GlobalColors.primary
                                    : Colors.transparent,
                                border: Border.all(
                                  color: currentPage == pageIndex
                                      ? GlobalColors.primary
                                      : Colors.grey.shade400,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  '${pageIndex + 1}',
                                  style: TextStyle(
                                    color: currentPage == pageIndex
                                        ? Colors.white
                                        : null,
                                    fontSize: 12,
                                    fontWeight: currentPage == pageIndex
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Show ellipsis if there are more pages
                      if (totalPages > 5)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            '...',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),

                // Next button
                IconButton(
                  onPressed: currentPage < totalPages - 1 ? _nextPage : null,
                  icon: Icon(
                    Icons.chevron_right,
                    color: currentPage < totalPages - 1
                        ? GlobalColors.primary
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),

        // Page info
        if (totalPages > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Page ${currentPage + 1} of $totalPages • ${widget.state.products.length} total items',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, Product product) {
    ModalDialog.show(
      context: context,
      title: 'Delete Product',
      showTitle: true,
      showTitleDivider: true,
      modalType: ModalType.medium,
      onCancelTap: () => Navigator.of(context).pop(),
      onSaveTap: () {
        context.read<ProductBloc>().add(DeleteProduct(product.id));
        Navigator.of(context).pop();
      },
      child: Center(
        child: Text(
          'Are you sure you want to delete ${product.name}?',
          textAlign: TextAlign.center,
        ),
      ),
      footer: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20.0,
          vertical: 10.0,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 120,
                child: ButtonWidget(
                  btnText: 'Cancel',
                  textColor: FlarelineColors.darkBlackText,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 120,
                child: ButtonWidget(
                  btnText: 'Delete',
                  onTap: () {
                    context.read<ProductBloc>().add(DeleteProduct(product.id));
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

  IconData _getSectorIcon(String sector) {
    switch (sector.toLowerCase()) {
      case 'rice':
        return Icons.grass;
      case 'corn':
        return Icons.agriculture;
      case 'livestock':
        return Icons.agriculture;
      case 'fishery':
        return Icons.water;
      case 'hvc':
        return Icons.agriculture;
      case 'organic':
        return Icons.agriculture;
      default:
        return Icons.category;
    }
  }

  Color _getSectorColor(String sector) {
    switch (sector) {
      case 'Rice':
        return Colors.green;
      case 'Corn':
        return Colors.yellow;
      case 'Livestock':
        return Colors.deepOrange;
      case 'Fishery':
        return Colors.blue;
      case 'HVC':
        return Colors.purple;
      case 'Organic':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
