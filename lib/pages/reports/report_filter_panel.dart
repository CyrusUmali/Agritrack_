import 'package:flareline/pages/assoc/assoc_bloc/assocs_bloc.dart';
import 'package:flareline/pages/farmers/farmer/farmer_bloc.dart';
import 'package:flareline/pages/farms/farm_bloc/farm_bloc.dart';
import 'package:flareline/pages/products/product/product_bloc.dart';
import 'package:flareline/pages/reports/filter_configs/filter_combo-box.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/services/lanugage_extension.dart';
import 'package:provider/provider.dart';
import 'date_range_picker.dart';
import 'filters/segmented_filter.dart';
import 'filters/column_selector.dart';
import 'filter_configs/filter_options.dart';

class ReportFilterPanel extends StatelessWidget {
  final DateTimeRange dateRange;
  final ValueChanged<DateTimeRange> onDateRangeChanged;
  final String selectedBarangay;
  final String selectedFarmer;

  final String selectedCount;
  final ValueChanged<String> onCountChanged;
  final String selectedView;

  final ValueChanged<String> onViewChanged;
  final ValueChanged<String> onFarmerChanged;
  final ValueChanged<String> onBarangayChanged;
  final String selectedSector;
  final ValueChanged<String> onSectorChanged;
  final String selectedProduct;
  final ValueChanged<String> onProductChanged;

  final String selectedAssoc;
  final ValueChanged<String> onAssocChanged;

  final String selectedFarm;
  final ValueChanged<String> onFarmChanged;
  final String reportType;
  final ValueChanged<String> onReportTypeChanged;
  final String outputFormat;
  final ValueChanged<String> onOutputFormatChanged;
  final Set<String> selectedColumns;
  final ValueChanged<Set<String>> onColumnsChanged;
  final VoidCallback onGeneratePressed;
  final bool isLoading;

  const ReportFilterPanel({
    super.key,
    required this.dateRange,
    required this.onDateRangeChanged,
    required this.selectedBarangay,
    required this.selectedFarmer,
    required this.selectedView,
    required this.selectedCount,
    required this.onCountChanged,
    required this.onViewChanged,
    required this.onBarangayChanged,
    required this.onFarmerChanged,
    required this.selectedSector,
    required this.onSectorChanged,
    required this.selectedAssoc,
    required this.onAssocChanged,
    required this.selectedProduct,
    required this.onProductChanged,
    required this.selectedFarm,
    required this.onFarmChanged,
    required this.reportType,
    required this.onReportTypeChanged,
    required this.outputFormat,
    required this.onOutputFormatChanged,
    required this.selectedColumns,
    required this.onColumnsChanged,
    required this.onGeneratePressed,
    required this.isLoading,
  });
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final _isFarmer = userProvider.isFarmer;
    final _farmerId = userProvider.farmer?.id;
 
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 1000;
        final isTablet = constraints.maxWidth > 600;

        return CommonCard(
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.translate('Report Filters'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).cardTheme.surfaceTintColor ??
                          Colors.grey[300]!,
                      width: 1.0,
                    ),
                  ),
                ),
                child: Column(
                  children: [


     if (!_isFarmer)
  SegmentedFilter(
    label: context.translate('Report Type'),
    options: FilterOptions.getFilteredReportTypes(_isFarmer),
    selected: reportType,
    onChanged: onReportTypeChanged,
  ),
                  
                    const SizedBox(height: 16),
                    // This will force a rebuild when reportType changes
                    _FiltersSection(
                      reportType: reportType,
                      dateRange: dateRange,
                      onDateRangeChanged: onDateRangeChanged,
                      selectedBarangay: selectedBarangay,
                      selectedFarmer: selectedFarmer,
                      selectedView: selectedView,
                      onCountChanged: onCountChanged,
                      selectedCount: selectedCount,
                      selectedSector: selectedSector,
                      selectedProduct: selectedProduct,
                      onProductChanged: onProductChanged,
                      selectedAssoc: selectedAssoc,
                      onAssocChanged: onAssocChanged,
                      selectedFarm: selectedFarm,
                      onBarangayChanged: onBarangayChanged,
                      onFarmerChanged: onFarmerChanged,
                      onSectorChanged: onSectorChanged,
                      onFarmChanged: onFarmChanged,
                      onViewChanged: onViewChanged,
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).cardTheme.surfaceTintColor ??
                          Colors.grey[300]!,
                      width: 1.0,
                    ),
                  ),
                ),
                child: ColumnSelector(
                  reportType: reportType,
                  selectedColumns: selectedColumns,
                  onColumnsChanged: onColumnsChanged,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: SizedBox(
                  width: isDesktop ? 201 : double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).cardTheme.color ?? Colors.white,
                      foregroundColor:
                          Theme.of(context).textTheme.bodyMedium?.color,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: Theme.of(context).cardTheme.surfaceTintColor ??
                              Colors.grey[300]!,
                          width: 1.0,
                        ),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    onPressed: isLoading ? null : onGeneratePressed,
                    child: isLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          )
                        : Text(
                            context.translate('Generate Report'),
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

class _FiltersSection extends StatelessWidget {
  final String reportType;
  final DateTimeRange dateRange;
  final ValueChanged<DateTimeRange> onDateRangeChanged;
  final String selectedBarangay;
  final String selectedFarmer;
  final String selectedView;
  final String selectedCount;
  final ValueChanged<String> onCountChanged;
  final String selectedSector;

  final String selectedProduct;
  final ValueChanged<String> onProductChanged;

  final String selectedAssoc;
  final ValueChanged<String> onAssocChanged;

  final String selectedFarm;
  final ValueChanged<String> onBarangayChanged;
  final ValueChanged<String> onFarmerChanged;
  final ValueChanged<String> onSectorChanged;

  final ValueChanged<String> onFarmChanged;
  final ValueChanged<String> onViewChanged;
  final bool isDesktop;
  final bool isTablet;

  const _FiltersSection({
    required this.reportType,
    required this.dateRange,
    required this.onDateRangeChanged,
    required this.selectedBarangay,
    required this.selectedFarmer,
    required this.selectedView,
    required this.selectedCount,
    required this.onCountChanged,
    required this.selectedSector,
    required this.selectedProduct,
    required this.onProductChanged,
    required this.selectedAssoc,
    required this.onAssocChanged,
    required this.selectedFarm,
    required this.onBarangayChanged,
    required this.onFarmerChanged,
    required this.onSectorChanged,
    required this.onFarmChanged,
    required this.onViewChanged,
    required this.isDesktop,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    if (reportType == 'products' ||
        reportType == 'sectors' ||
        reportType == 'farmer' ||
        reportType == 'barangay') {
      return isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDesktopFilters(context),
              ],
            )
          : Column(
              children: [
                
              Center(
  child: LayoutBuilder(
    builder: (context, constraints) {
      final parentWidth = constraints.maxWidth;
      // final desiredWidth = parentWidth > 300 ? 280.0 : parentWidth * 1; // Use 180.0 instead of 180
      
      return DateRangePickerWidget(
        width: parentWidth,
        dateRange: dateRange,
        onDateRangeChanged: onDateRangeChanged,
      );
    },
  ),
),
              
                const SizedBox(height: 16),
                isTablet
                    ? _buildTabletFilters(context)
                    : _buildMobileFilters(context),
              ],
            );
    } else {
      return isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_buildDesktopFilters(context)],
            )
          : isTablet
              ? _buildTabletFilters(context)
              : _buildMobileFilters(context);
    }
  }

  Widget _buildDesktopFilters(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        if (reportType == 'products' ||
            reportType == 'sectors' ||
            reportType == 'farmer' ||
            reportType == 'barangay')
          DateRangePickerWidget(
            dateRange: dateRange,
            onDateRangeChanged: onDateRangeChanged,
          ),
        ..._buildDynamicFilters(context, true),
      ],
    );
  }

  Widget _buildTabletFilters(BuildContext context) {
    return Column(
      children: [
        for (var filter in _buildDynamicFilters(context, false))
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SizedBox(width: double.infinity, child: filter),
          ),
      ],
    );
  }

  Widget _buildMobileFilters(BuildContext context) {
    return Column(
      children: [
        for (var filter in _buildDynamicFilters(context, false))
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: filter,
          ),
      ],
    );
  }

  List<Widget> _buildDynamicFilters(BuildContext context, bool isDesktop) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final _isFarmer = userProvider.isFarmer;
    final _farmerId = userProvider.farmer?.id;

    // Common filter widgets that can be reused
    Widget barangayFilter = buildComboBox(
      context: context,
      hint: 'Barangay',
      options: FilterOptions.barangays,
      selectedValue: selectedBarangay,
      onSelected: onBarangayChanged,
      width: isDesktop ? 130 : double.infinity,
    );

    Widget sectorFilter = buildComboBox(
      hint: 'Sector',
      context: context,
      options: FilterOptions.sectors,
      selectedValue: selectedSector,
      onSelected: onSectorChanged,
      width: isDesktop ? 130 : double.infinity,
    );

    Widget assocFilter = _RetryComboboxBuilder<AssocsBloc, AssocsState>(
      blocBuilder: (context) => BlocProvider.of<AssocsBloc>(context),
      buildWidget: (context) => buildComboBox(
        context: context,
        hint: 'Association',
        options: FilterOptions.getAssocs(context),
        selectedValue: selectedAssoc,
        onSelected: onAssocChanged,
        width: isDesktop ? 130 : double.infinity,
      ),
      onRetry: (context) {
        context.read<AssocsBloc>().add(LoadAssocs());
      },
    );

    Widget countFilter = buildComboBox(
      context: context,
      hint: 'Count',
      options: FilterOptions.Count,
      selectedValue: selectedCount,
      onSelected: onCountChanged,
      width: isDesktop ? 130 : double.infinity,
    );

    Widget viewByFilter = buildComboBox(
      context: context,
      hint: 'View By',
      options: FilterOptions.viewBy,
      selectedValue: selectedView,
      onSelected: onViewChanged,
      width: isDesktop ? 130 : double.infinity,
    );

    Widget farmerFilter = _RetryComboboxBuilder<FarmerBloc, FarmerState>(
      blocBuilder: (context) => BlocProvider.of<FarmerBloc>(context),
      buildWidget: (context) => buildComboBox(
        context: context,
        hint: 'Farmer',
        options: FilterOptions.getFarmers(context),
        selectedValue: selectedFarmer,
        onSelected: onFarmerChanged,
        width: isDesktop ? 130 : double.infinity,
      ),
      onRetry: (context) {
        context.read<FarmerBloc>().add(LoadFarmers());
      },
    );

    Widget productFilter = _RetryComboboxBuilder<ProductBloc, ProductState>(
      blocBuilder: (context) => BlocProvider.of<ProductBloc>(context),
      buildWidget: (context) => buildComboBox(
        context: context,
        hint: 'Product',
        options: FilterOptions.getProducts(context),
        selectedValue: selectedProduct,
        onSelected: onProductChanged,
        width: isDesktop ? 130 : double.infinity,
      ),
      onRetry: (context) {
        context.read<ProductBloc>().add(LoadProducts());
      },
    );

    Widget farmFilter = _RetryComboboxBuilder<FarmBloc, FarmState>(
      blocBuilder: (context) => BlocProvider.of<FarmBloc>(context),
      buildWidget: (context) => buildComboBox(
        context: context,
        hint: 'Farm',
        options: FilterOptions.getFarms(context, _farmerId),
        selectedValue: selectedFarm,
        onSelected: onFarmChanged,
        width: isDesktop ? 130 : double.infinity,
      ),
      onRetry: (context) {
        context.read<FarmBloc>().add(LoadFarms());
      },
    );

    switch (reportType) {
      case 'farmers':
        return [
          if (!_isFarmer) barangayFilter,
          sectorFilter,
          if (!_isFarmer) assocFilter,
          countFilter,
        ];
      case 'farmer':
        return [
          if (!_isFarmer) farmerFilter,
          productFilter,
          farmFilter,
          if (!_isFarmer) assocFilter,
          viewByFilter,
          countFilter,
        ];
      case 'products':
        return [
          productFilter,
          viewByFilter,
          if (!_isFarmer) barangayFilter,
          if (!_isFarmer) sectorFilter,
          countFilter,
        ];
      case 'barangay':
        return [
          barangayFilter,
          productFilter,
          viewByFilter,
          sectorFilter,
          countFilter,
        ];
      case 'sectors':
        return [
          sectorFilter,
          viewByFilter,
          countFilter,
        ];
      default:
        return [];
    }
  }
}

// Generic retry widget for comboboxes that can fail to load data
class _RetryComboboxBuilder<B extends BlocBase<S>, S> extends StatelessWidget {
  final B Function(BuildContext) blocBuilder;
  final Widget Function(BuildContext) buildWidget;
  final void Function(BuildContext) onRetry;

  const _RetryComboboxBuilder({
    required this.blocBuilder,
    required this.buildWidget,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<B, S>(
      builder: (context, state) {
        // Check if state indicates an error
        final hasError = _checkForErrorState(state);

        if (hasError) {
          return _buildErrorRetryWidget(context, _getErrorMessage(state));
        }

        return buildWidget(context);
      },
    );
  }

  bool _checkForErrorState(S state) {
    // Check for specific error states based on the state type
    if (state is FarmersError) {
      return true;
    }
    // Add similar checks for other bloc states when you define their error states
    if (state is AssocsState && state is AssocsError) {
      return true;
    }
    if (state is ProductState && state is ProductsError) {
      return true;
    }
    if (state is FarmState && state is FarmsError) {
      return true;
    }
    return false;
  }

  String _getErrorMessage(S state) {
    if (state is FarmersError) {
      return state.message;
    }
    // Add similar getters for other error states
    if (state is AssocsState && state is AssocsError) {
      return state.message;
    }
    if (state is ProductState && state is ProductsError) {
      return state.message;
    }
    if (state is FarmState && state is FarmsError) {
      return state.message;
    }
    return 'Failed to load data';
  }








Widget _buildErrorRetryWidget(BuildContext context, String errorMessage) {
  return LayoutBuilder(builder: (context, constraints) {
    final isDesktop = constraints.maxWidth > 1000;
    
    return MouseRegion(
      child: StatefulBuilder(
        builder: (context, setState) {
          bool isHovered = false;
          final cardColor = Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor;
          
          return Container(
            width: isDesktop ? 130 : double.infinity,
            height: 40,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onRetry(context),
                borderRadius: BorderRadius.circular(8),
                onHover: (hovering) {
                  setState(() {
                    isHovered = hovering;
                  });
                },
                child: Ink(
                  decoration: BoxDecoration(
                    color: isHovered ? 
                      cardColor.withOpacity(0.8) : // Slightly transparent on hover
                      cardColor,
                    border: Border.all(
                      color: Colors.red.shade300,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          color: Colors.red.shade700,
                          size: 17,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Failed to load',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  });
}


}
