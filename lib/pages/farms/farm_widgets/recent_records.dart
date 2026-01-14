import 'dart:async';

import 'package:flareline/core/models/yield_model.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/pages/farms/farm_widgets/export_farm_records.dart';
import 'package:flareline/pages/map/map_widget/map_panel/polygon_modal.dart';
import 'package:flareline/pages/map/map_widget/pin_style.dart';
import 'package:flareline/pages/products/product/product_bloc.dart';
import 'package:flareline/pages/map/map_widget/stored_polygons.dart'; 
import 'package:flareline/pages/yields/farm_add_yield_record.dart';
import 'package:flareline/pages/yields/yield_bloc/yield_bloc.dart'; 
import 'package:flareline/pages/yields/yield_profile2.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:flareline_uikit/components/modal/modal_dialog.dart';
import 'package:flareline_uikit/components/tables/table_widget.dart';
import 'package:flareline_uikit/entity/table_data_entity.dart';
import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:toastification/toastification.dart';
import 'package:flareline/pages/widget/combo_box.dart';

  class RecentRecord extends StatefulWidget {
    final List<Yield> yields;
    final ModalLayout modalLayout;
    final int? farmId;
    final int? farmerId;
    final double ? farmArea; // New parameter for farm area

    const RecentRecord(
        {super.key,
        this.modalLayout = ModalLayout.centerDialog,
        this.farmId,
        this.farmArea,
        this.farmerId,
        required this.yields}); // Update constructor

    @override
    State<RecentRecord> createState() => _RecentRecordWidgetState();
  }

  class _RecentRecordWidgetState extends State<RecentRecord> {
 
    String selectedProduct = '';
    String selectedStatus = '';
      String selectedYear = 'All';
      // Add these class-level variables
Timer? _filterDebounceTimer;
static const Duration _filterDebounceDuration = Duration(milliseconds: 300);

      String searchQuery = '';

      late List<Yield> filteredYields;

    late List<String> barangayNames;

    @override
    void initState() {
      super.initState();
  
    filteredYields = widget.yields;
      barangayNames = barangays.map((b) => b['name'] as String).toList();
    }


void _applyFilters() {
  // Cancel any existing timer
  _filterDebounceTimer?.cancel();
  
  // Start a new timer
  _filterDebounceTimer = Timer(_filterDebounceDuration, () {
    setState(() {
      // Check if all filters are empty/default
      final allFiltersEmpty = 
          (selectedProduct == 'All' || selectedProduct.isEmpty) &&
          (selectedStatus == 'All' || selectedStatus.isEmpty) && 
          searchQuery.isEmpty;
      
      // If all filters are empty, reset to original widget.yields
      if (allFiltersEmpty) {
        filteredYields = widget.yields;
        return; // Exit early, no need to filter
      } 
      // Otherwise, apply filters to widget.yields (THE ORIGINAL SOURCE)
      filteredYields = widget.yields.where((yield) {
        // Product filter
        final matchesProduct = selectedProduct == 'All' ||
            selectedProduct.isEmpty ||
            (yield.productName != null && 
            yield.productName!.toLowerCase() == selectedProduct.toLowerCase());

        if (!matchesProduct) return false;

        // Status filter
        final matchesStatus = selectedStatus == 'All' ||
            selectedStatus.isEmpty ||
            (yield.status != null &&
            yield.status!.toLowerCase() == selectedStatus.toLowerCase());

        if (!matchesStatus) return false;

        // Year filter
        final matchesYear = selectedYear == 'All' ||
            selectedYear.isEmpty ||
            (yield.harvestDate.year.toString() == selectedYear);

        if (!matchesYear) return false;

        // Search filter
        if (searchQuery.isEmpty) return true;

        final query = searchQuery.toLowerCase();
        return (yield.notes?.toLowerCase().contains(query) ?? false) ||
            (yield.farmerName?.toLowerCase().contains(query) ?? false) ||
            (yield.status?.toLowerCase().contains(query) ?? false) ||
            (yield.harvestDate.toString().contains(query)) ||
            (yield.id.toString().contains(query)) ||
            (yield.volume.toString().contains(query)) ||
            (yield.value?.toString().contains(query) ?? false) ||
            (yield.productName?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  });
}


@override
void dispose() {
  _filterDebounceTimer?.cancel();
  super.dispose();
}

  void _showToast(BuildContext context, String message, {bool isError = false}) {
      toastification.show(
        context: context,
        type: isError ? ToastificationType.error : ToastificationType.success,
        style: ToastificationStyle.flat,
        title: Text(message),
        alignment: Alignment.topRight,
        showProgressBar: false,
        autoCloseDuration: const Duration(seconds: 3),
      );
    }


  @override
    Widget build(BuildContext context) {
      // Wrap everything in BlocListener to catch all state changes
      return MultiBlocListener(
        listeners: [
          BlocListener<YieldBloc, YieldState>(
            listenWhen: (previous, current) {
              // Only listen to state changes with messages or errors
              return (current is YieldsLoaded && current.message != null) ||
                    current is YieldsError;
            },
            listener: (context, state) {
              if (state is YieldsLoaded && state.message != null) {
                // Delay to ensure any dialogs are closed
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showToast(context, state.message!);
                });
              } else if (state is YieldsError) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showToast(context, state.message, isError: true);
                });
              }


if (state is YieldsLoaded) {
        // Update the filtered yields with the new state
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              // Keep the filter criteria but apply them to the new yields
              filteredYields = widget.yields;
             
            
              _applyFilters(); // Re-apply filters to the new data
            });
          }
          else{ 

          }
        });
      }
    

            },
          ),
        ],
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            if (isMobile) {
              return _channelMobile(context);
            } else {
              if (widget.modalLayout == ModalLayout.centerDialog) {
                return _channelsWeb(context);
              } else {
                return _channelMobile(context);
              }
            }
          },
        ),
      );
    }




Widget _channelsWeb(BuildContext context) {
  final screenHeight = MediaQuery.of(context).size.height;

  double height;
  if (screenHeight < 400) {
    height = screenHeight * 0.6;
  } else if (screenHeight < 600) {
    height = screenHeight * 0.50;
  } else if (screenHeight < 800) {
    height = screenHeight * 0.56;
  } else if (screenHeight < 1500) {
    height = screenHeight * 0.63;
  } else {
    height = screenHeight * 0.3;
  }

  return ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: height,
    ),
    child: SizedBox(
      height: 500,
      child: Column(
        children: [
          _buildSearchBarDesktop(),
          const SizedBox(height: 16),
          // REMOVE BlocBuilder here - just use filteredYields directly
          Expanded(
            child: filteredYields.isEmpty 
                ? _buildNoResultsWidget()
                : Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DataTableWidget(
                          key: ValueKey('yields_table_${filteredYields.length}'),
                          yields: filteredYields, // Use filteredYields
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    ),
  );
}

// 3. Fix _channelMobile - Update the ValueKey
Widget _channelMobile(BuildContext context) {
  final screenHeight = MediaQuery.of(context).size.height;

  double height;
  if (screenHeight < 400) { 
    height = screenHeight * 0.5;
  } else if (screenHeight < 600) {
    height = screenHeight * 0.60;
  } else if (screenHeight < 800) {
    height = screenHeight * 0.72;
  } else if (screenHeight < 1500) {
    height = screenHeight * 0.80;
  } else {
    height = screenHeight * 0.8;
  }

  return Column(
    children: [
      _buildSearchBarMobile(),
      const SizedBox(height: 16),
      SizedBox(
        height: height,
        child: filteredYields.isEmpty
            ? _buildNoResultsWidget()
            : MobileYieldListWidget(
                key: ValueKey('yields_table_${filteredYields.length}'), // Fixed
                state: YieldsLoaded(filteredYields), 
              ),
      ),
    ],
  );
}




    Widget _buildNoResultsWidget() {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.agriculture_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No records found',
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

    Widget _buildSearchBarMobile() {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      // ignore: unused_local_variable
      final isFarmer = userProvider.isFarmer;

      return MultiBlocListener(
        listeners: [
          BlocListener<ProductBloc, ProductState>(
            listener: (context, state) {
              if (state is ProductsError) {
                toastification.show(
                  context: context,
                  type: ToastificationType.error,
                  style: ToastificationStyle.flat,
                  title: Text(state.message),
                  alignment: Alignment.topRight,
                  autoCloseDuration: const Duration(seconds: 3),
                );
              }
            },
          ),
        ],
        child: Builder(
          builder: (context) {
            // Get all states at once
            final productState = context.watch<ProductBloc>().state;

            // Check if all data is loaded
            final allDataLoaded = productState is ProductsLoaded;

            // Get product names if loaded
            final productOptions = productState is ProductsLoaded
                ? ['All', ...productState.products.map((p) => p.name)]
                : ['All']; // Fallback if not loaded yet

            return SizedBox(
              height: 50,
              child: Container(
                // padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ScrollConfiguration(
                
                
                  behavior: ScrollConfiguration.of(context).copyWith(
                    scrollbars: true,
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.stylus,
                      PointerDeviceKind.trackpad,
                    },
                  ),
              
              
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                  
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: buildComboBox(
                            context: context,
                            hint: 'Product',
                            options: productOptions,
                            selectedValue: selectedProduct,
                            onSelected: (value) {
                              setState(() => selectedProduct = value);
                              _applyFilters(); 
                            },
                            width: 150,
                          ),
                        ),

                        // Status ComboBox
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: buildComboBox(
                            context: context,
                            hint: 'Status',
                            options: const [
                              'All',
                              'Pending',
                              'Accepted',
                              'Rejected'
                            ],
                            selectedValue: selectedStatus,
                            onSelected: (value) {
                              setState(() => selectedStatus = value);
                              _applyFilters(); 
                            },
                            width: 150,
                          ),
                        ),

                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 200,
                          height: 48,
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).cardTheme.color ?? Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  Theme.of(context).cardTheme.surfaceTintColor ??
                                      Colors.grey[300]!,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).cardTheme.shadowColor ??
                                    Colors.transparent,
                                blurRadius: 13,
                                offset: const Offset(0, 8),
                                spreadRadius: -3,
                              ),
                            ],
                          ),
                          child: TextField(
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search yields...',
                              hintStyle: TextStyle(
                                color: Theme.of(context).hintColor,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                size: 20,
                                color: Theme.of(context).iconTheme.color,
                              ),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onChanged: (value) {
                            setState(() => searchQuery = value);
                        _applyFilters();
                            },
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Add Yield Button
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: allDataLoaded
                                  ? GlobalColors.primary
                                  : Colors.grey,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            onPressed: allDataLoaded
                                ? () {
                                    AddYieldModalForFarm.show(
                                      context: context,
                                      products: (productState).products,
                                      farmerId: widget.farmerId!,
                                      farmId: widget.farmId!,
                                      farmArea: widget.farmArea, // Optional: pass farm area
                                      farmerSpecific: true,
                                      onYieldAdded: (
                                        int cropTypeId,
                                        double yieldAmount,
                                        double? areaHa,
                                        DateTime date,
                                        String notes,
                                        List<String> images,
                                      ) {
                                        context.read<YieldBloc>().add(
                                              AddYield(
                                                farmerId: widget.farmerId!,
                                                productId: cropTypeId,
                                                harvestDate: date,
                                                farmId: widget.farmId!,
                                                volume: yieldAmount,
                                                areaHarvested: areaHa,
                                                notes: notes,
                                                images: images,
                                                isFarmSpecific: true,
                                              ),
                                            );
                                      },
                                    );
                                  }
                                : null,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 20, color: Colors.white),
                                SizedBox(width: 4),
                                Text("Add Record",
                                    style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Export Button
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: BlocBuilder<YieldBloc, YieldState>(
                            builder: (context, state) {
                              final yields =
                                  state is YieldsLoaded ? state.yields : [];
                              return 
                            ExportButtonWidget(yields: filteredYields.cast<Yield>());
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    Widget _buildSearchBarDesktop() {
      Provider.of<UserProvider>(context, listen: false);

      return MultiBlocListener(
        listeners: [
          BlocListener<ProductBloc, ProductState>(
            listener: (context, state) {
              if (state is ProductsError) {
                toastification.show(
                  context: context,
                  type: ToastificationType.error,
                  style: ToastificationStyle.flat,
                  title: Text(state.message),
                  alignment: Alignment.topRight,
                  autoCloseDuration: const Duration(seconds: 3),
                );
              }
            },
          ),
          // Add similar listeners for FarmerBloc and FarmBloc if needed
        ],
        child: Builder(
          builder: (context) {
            // Get all states at once
            final productState = context.watch<ProductBloc>().state;

            // Check if all data is loaded
            final allDataLoaded = productState is ProductsLoaded;

            // Get product names if loaded
            final productOptions = productState is ProductsLoaded
                ? ['All', ...productState.products.map((p) => p.name)]
                : ['All']; // Fallback if not loaded yet

            return SizedBox(
              height: 48,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Product ComboBox
                  buildComboBox(
                    context: context,
                    hint: 'Product',
                    options: productOptions,
                    selectedValue: selectedProduct,
                    onSelected: (value) {
                      setState(() => selectedProduct = value);
                        _applyFilters();
                    },
                    width: 150,
                  ),
                  const SizedBox(width: 8),

                  // Status ComboBox
                  buildComboBox(
                    context: context,
                    hint: 'Status',
                    options: const ['All', 'Pending', 'Accepted', 'Rejected'],
                    selectedValue: selectedStatus,
                    onSelected: (value) {
                      setState(() => selectedStatus = value);
                  _applyFilters();
                    },
                    width: 150,
                  ),
                  const SizedBox(width: 8),

                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color ??
                            Colors.white, // Use card color from theme
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).cardTheme.surfaceTintColor ??
                              Colors.grey[300]!, // Use border color from theme
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).cardTheme.shadowColor ??
                                Colors.transparent,
                            blurRadius: 13,
                            offset: const Offset(0, 8),
                            spreadRadius: -3,
                          ),
                        ],
                      ),
                      child: TextField(
                        style: TextStyle(
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color, // Use text color from theme
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search yields...',
                          hintStyle: TextStyle(
                            color: Theme.of(context)
                                .hintColor, // Use hint color from theme
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            size: 20,
                            color: Theme.of(context)
                                .iconTheme
                                .color, // Use icon color from theme
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onChanged: (value) {
                          setState(() => searchQuery = value);
                        _applyFilters();
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),


                  
                  // Add Yield Button
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            allDataLoaded ? GlobalColors.primary : Colors.grey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: allDataLoaded
                          ? () {
                              AddYieldModalForFarm.show(
                                context: context,
                                products: (productState).products,
                                farmerId: widget.farmerId!,
                                farmId: widget.farmId!,
                                farmArea: widget.farmArea, // Optional: pass farm area
                                farmerSpecific: true,
                                onYieldAdded: (
                                  int cropTypeId,
                                  double yieldAmount,
                                  double? areaHa,
                                  DateTime date,
                                  String notes,
                                  List<String> images,
                                ) {
                                  context.read<YieldBloc>().add(
                                        AddYield(
                                          farmerId: widget.farmerId!,
                                          productId: cropTypeId,
                                          harvestDate: date,
                                          farmId: widget.farmId!,
                                          volume: yieldAmount,
                                          areaHarvested: areaHa,
                                          notes: notes,
                                          images: images,
                                          isFarmSpecific: true,
                                        ),
                                      );
                                },
                              );
                            }
                          : null,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 20, color: Colors.white),
                          SizedBox(width: 4),
                          Text("Add Record", style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                    const SizedBox(width: 8),

              
              

                  // ADD EXPORT BUTTON HERE
                  BlocBuilder<YieldBloc, YieldState>(
                    builder: (context, state) {
                      final yields = state is YieldsLoaded ? state.yields : [];
                      return ExportButtonWidget(yields: filteredYields.cast<Yield>());
                    },
                  ),
            
              
                ],
              ),
            );
          },
        ),
      );
    }
  }

  class DataTableWidget extends TableWidget<YieldsViewModel> {
    final List<Yield> yields;

    DataTableWidget({
      required this.yields,
      super.key,
    });

    @override
    YieldsViewModel viewModelBuilder(BuildContext context) {
      return YieldsViewModel(context, yields);
    }

    @override
    Widget headerBuilder(
        BuildContext context, String headerName, YieldsViewModel viewModel) {
      if (headerName == 'Action') {
        return Text(headerName);
      }

      return InkWell(
        onTap: () {
          context.read<YieldBloc>().add(SortYields(headerName));
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
            BlocBuilder<YieldBloc, YieldState>(
              builder: (context, state) {
                if (state is YieldsLoaded) {
                  final bloc = context.read<YieldBloc>();
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
        YieldsViewModel viewModel) {
      final yield = viewModel.yields.firstWhere(
        (p) => p.id.toString() == columnData.id,
      );
      // Navigate to YieldProfile when any cell in the row is tapped
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => YieldProfile2(yieldData: yield),
        ),
      );
    }

    @override
    Widget actionWidgetsBuilder(
      BuildContext context,
      TableDataRowsTableDataRows columnData,
      YieldsViewModel viewModel,
    ) {
      final yield = viewModel.yields.firstWhere(
        (p) => p.id.toString() == columnData.id,
      );

      Provider.of<UserProvider>(context, listen: false);

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
          
          
              ModalDialog.show(
                context: context,
                title: 'Delete Record',
                showTitle: true,
                showTitleDivider: true,
                modalType: ModalType.medium,
                onCancelTap: () => Navigator.of(context).pop(),
                onSaveTap: () {
                  context.read<YieldBloc>().add(DeleteYield(
                      id: yield.id, isFarmSpecific: true, farmId: yield.farmId, farmerId: yield.farmerId
                      
                      
                      ));
                  Navigator.of(context).pop();
                }, 
                child: Center(
                  child:
                      Text('Are you sure you want to delete this record?'),
                ),
                footer: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 10.0),
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
                              context.read<YieldBloc>().add(DeleteYield(
                                  id: yield.id,
                                  isFarmSpecific: true,
                                  farmId: yield.farmId, farmerId: yield.farmerId));

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
            icon: const Icon(Icons.chevron_right_sharp),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => YieldProfile2(yieldData: yield),
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
          width: 1150,
          child: super.build(context),
        ),
      );
    }
  }

  class YieldsViewModel extends BaseTableProvider { 
    final List<Yield> yields;

  



     String _getYieldWithUnit(double? volume, int? sectorId) {
    if (volume == null) return 'N/A';

    switch (sectorId) {
      case 1:
      case 2:
      case 3:
      case 5:
      case 6:
        return '${volume.toStringAsFixed(volume % 1 == 0 ? 0 : 1)} kg';
      case 4:
        return '${volume.toInt()} heads';
      default:
        return volume.toString();
    }
  }

    String _formatDate(dynamic dateInput) {
      if (dateInput == null) return 'N/A';

      try {
        DateTime dateTime;
        if (dateInput is String) {
          dateTime = DateTime.parse(dateInput);
        } else if (dateInput is DateTime) {
          dateTime = dateInput;
        } else {
          return 'Invalid date';
        }
        return DateFormat('MMMM d, y').format(dateTime);
      } catch (e) {
        return 'Invalid date';
      }
    }

    YieldsViewModel(super.context, this.yields);

    @override
    Future loadData(BuildContext context) async {
      
      final headers = [
        "Product",
        "Area",
        "Reported Yield",
        "Date Reported",
        "Status",
        "Action"
      ];

      List<List<TableDataRowsTableDataRows>> rows = [];

      for (var yieldRecord in yields) {
        List<TableDataRowsTableDataRows> row = [];

        // Product name with image
        var productCell = TableDataRowsTableDataRows()
          ..text = yieldRecord.productName
          ..imageUrl = yieldRecord.productImage
          ..dataType = CellDataType.IMAGE_TEXT.type
          ..columnName = 'Product'
          ..id = yieldRecord.id.toString();
        row.add(productCell);

        // Area
        var areaCell = TableDataRowsTableDataRows()
          // ..text = yieldRecord.hectare as String?
          ..text = '${yieldRecord.areaHarvested} ha'
          ..dataType = CellDataType.TEXT.type
          ..columnName = 'Area'
          ..id = yieldRecord.id.toString();
        row.add(areaCell);

        // Reported Yield
        var yieldCell = TableDataRowsTableDataRows()
          ..text = _getYieldWithUnit(yieldRecord.volume, yieldRecord.sectorId)
              as String?
          ..dataType = CellDataType.TEXT.type
          ..columnName = 'Reported Yield'
          ..id = yieldRecord.id.toString();
        row.add(yieldCell);

  // Then in loadData:
        var dateCell = TableDataRowsTableDataRows()
          ..text = _formatDate(yieldRecord.createdAt)
          ..dataType = CellDataType.TEXT.type
          ..columnName = 'Date Reported'
          ..id = yieldRecord.id.toString();
        row.add(dateCell);
        // Status
        var statusCell = TableDataRowsTableDataRows()
          ..text = yieldRecord.status
          ..dataType = CellDataType.TEXT.type
          ..columnName = 'Status'
          ..id = yieldRecord.id.toString();
        row.add(statusCell);

        // Action
        var actionCell = TableDataRowsTableDataRows()
          ..text = ""
          ..dataType = CellDataType.ACTION.type
          ..columnName = 'Action'
          ..id = yieldRecord.id.toString();
        row.add(actionCell);

        rows.add(row);
      }

      TableDataEntity tableData = TableDataEntity()
        ..headers = headers
        ..rows = rows;

      tableDataEntity = tableData;
    }
  }







class MobileYieldListWidget extends StatefulWidget {
  final YieldsLoaded state;
  final int itemsPerPage;

  const MobileYieldListWidget({
    required this.state,
    this.itemsPerPage = 10, // Default items per page
    super.key,
  });

  @override
  State<MobileYieldListWidget> createState() => _MobileYieldListWidgetState();
}

class _MobileYieldListWidgetState extends State<MobileYieldListWidget> {
  int currentPage = 0;

  int get totalPages =>
      (widget.state.yields.length / widget.itemsPerPage).ceil();

  List<dynamic> get currentPageData {
    final startIndex = currentPage * widget.itemsPerPage;
    final endIndex =
        (startIndex + widget.itemsPerPage).clamp(0, widget.state.yields.length);
    return widget.state.yields.sublist(startIndex, endIndex);
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

  // Convert sectorId to sector string for pinStyle (you might need to adjust this mapping)
  String _getSectorString(int? sectorId) {
    switch (sectorId) {
      case 1:
        return 'Rice';
      case 2:
        return 'Corn';
      case 3:
        return 'HVC';
      case 4:
        return 'Livestock';
      case 5:
        return 'Fishery';
      case 6:
        return 'Organic';
      default:
        return 'Other';
    }
  }

  // Yield Preview Widget with image and pinStyle icon fallback
  Widget _buildYieldPreview(dynamic yield) {
    final sectorString = _getSectorString(yield.sectorId);
    final pinStyle = parsePinStyle(sectorString);
    final sectorColor = getPinColor(pinStyle);
    final sectorIcon = getPinIcon(pinStyle);

    // Check if yield has a product image
    final hasImage =
        yield.productImage != null && yield.productImage!.isNotEmpty;

    return Stack(
      children: [
        // Main preview container
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: sectorColor.withOpacity(0.2),
            border: Border.all(
              color: sectorColor,
              width: 2.0,
            ),
          ),
          child: hasImage
              ? ClipOval(
                  child: Image.network(
                    yield.productImage!,
                    fit: BoxFit.cover,
                    width: 36,
                    height: 36,
                    errorBuilder: (context, error, stackTrace) {
                      // If image fails to load, show the sector icon
                      return Center(
                        child: sectorIcon,
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(sectorColor),
                        ),
                      );
                    },
                  ),
                )
              : Center(
                  child: sectorIcon,
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isFarmer = userProvider.isFarmer;
    final theme = Theme.of(context);

    if (widget.state.yields.isEmpty) {
      return CommonCard(
        margin: EdgeInsets.all(0),
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text('No yields available'),
        ),
      );
    }

    return Column(
      children: [
        // List content - Using ListView.separated for item separation
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(0),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: currentPageData.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final yield = currentPageData[index]; 
              final statusColor = _getStatusColor(yield.status ?? 'N/A');

              return CommonCard(
                margin: EdgeInsets.zero,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => YieldProfile2(yieldData: yield),
                    ),
                  ),







    onLongPress:  
                      () {
                         
                         



                            
            ModalDialog.show(
              context: context,
              title: 'Delete Record',
              showTitle: true,
              showTitleDivider: true,
              modalType: ModalType.medium,
              onCancelTap: () => Navigator.of(context).pop(),
              onSaveTap: () {
                context.read<YieldBloc>().add(DeleteYield(
                    id: yield.id, isFarmSpecific: true, farmId: yield.farmId, farmerId: yield.farmerId
                    
                    
                    ));
                Navigator.of(context).pop();
              }, 
              child: Center(
                child:
                    Text('Are you sure you want to delete this record?'),
              ),
              footer: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 10.0),
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
                            context.read<YieldBloc>().add(DeleteYield(
                                id: yield.id,
                                isFarmSpecific: true,
                                farmId: yield.farmId, farmerId: yield.farmerId));

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
                       ,





                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Leading icon/avatar
                        _buildYieldPreview(yield),

                        const SizedBox(width: 16),

                        // Yield info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product name only
                              Text(
                                isFarmer
                                    ? yield.productName ?? 'N/A'
                                    : '${yield.farmerName} • ${yield.productName}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 4),

                              // Volume and date
                              Text(
                                '${_getYieldWithUnit(yield.volume, yield.sectorId)} • ${_formatDate(yield.createdAt)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Status and chevron in same row
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(right: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.3),
                            ),
                          ],
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
              'Page ${currentPage + 1} of $totalPages • ${widget.state.yields.length} total items',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
      ],
    );
  }

  String _getYieldWithUnit(double? volume, int? sectorId) {
    if (volume == null) return 'N/A';

    switch (sectorId) {
      case 1:
      case 2:
      case 3:
      case 5:
      case 6:
        return '${volume.toStringAsFixed(volume % 1 == 0 ? 0 : 1)} kg';
      case 4:
        return '${volume.toInt()} heads';
      default:
        return volume.toString();
    }
  }

  String _formatDate(dynamic dateInput) {
    if (dateInput == null) return 'N/A';
    try {
      DateTime dateTime =
          dateInput is String ? DateTime.parse(dateInput) : dateInput;
      return DateFormat('MMM d').format(dateTime);
    } catch (e) {
      return 'N/A';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Accepted':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}



///////////

