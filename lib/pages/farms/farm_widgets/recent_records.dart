import 'package:flareline/core/models/yield_model.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/pages/farmers/farmer/farmer_bloc.dart';
import 'package:flareline/pages/farms/farm_bloc/farm_bloc.dart';
import 'package:flareline/pages/farms/farm_widgets/export_farm_records.dart';
import 'package:flareline/pages/products/product/product_bloc.dart';
import 'package:flareline/pages/test/map_widget/stored_polygons.dart';
import 'package:flareline/pages/yields/yield_bloc/yield_bloc.dart';
import 'package:flareline/pages/yields/yield_profile.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
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
  final List<Yield> yields; // Add this parameter

  const RecentRecord({super.key, required this.yields}); // Update constructor

  @override
  State<RecentRecord> createState() => _RecentRecordWidgetState();
}

class _RecentRecordWidgetState extends State<RecentRecord> {
  String selectedSector = '';
  String selectedBarangay = '';
  String selectedProduct = '';
  String selectedStatus = '';
  String selectedYear = DateTime.now().year.toString();

  late List<String> barangayNames;
  String _barangayFilter = '';

  @override
  void initState() {
    super.initState();
 
    barangayNames = barangays.map((b) => b['name'] as String).toList();
  }

  @override
  Widget build(BuildContext context) {
    return _channels();
  }

  _channels() {
    return ScreenTypeLayout.builder(
      desktop: _channelsWeb,
      mobile: _channelMobile,
      tablet: _channelMobile,
    );
  }

  Widget _channelsWeb(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: 550,
        // You can also set minHeight if needed
        // minHeight: 200,
      ),
      child: SizedBox(
        // height: MediaQuery.of(context).size.height * 0.5,
        height: 500,
        child: Column(
          children: [
            _buildSearchBarDesktop(),
            const SizedBox(height: 16),
            Expanded(
              child: widget.yields.isEmpty
                  ? _buildNoResultsWidget()
                  : Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DataTableWidget(
                            key: ValueKey(
                                'yields_table_${widget.yields.length}'),
                            yields: widget.yields,
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

  Widget _channelMobile(BuildContext context) {
    return Column(
      children: [
        _buildSearchBarMobile(),
        const SizedBox(height: 16),
        SizedBox(
          height: 380,
          child: widget.yields.isEmpty
              ? _buildNoResultsWidget()
              : MobileYieldListWidget(
                  key: ValueKey('yields_table_${widget.yields.length}'),
                  state: YieldsLoaded(
                      widget.yields), // Wrap yields in YieldsLoaded
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
        // Add similar listeners for FarmerBloc and FarmBloc if needed
      ],
      child: Builder(
        builder: (context) {
          // Get all states at once
          final productState = context.watch<ProductBloc>().state;

          // Get product names if loaded
          final productOptions = productState is ProductsLoaded
              ? ['All', ...productState.products.map((p) => p.name)]
              : ['All']; // Fallback if not loaded yet

          return SizedBox(
            height: 50,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                direction: Axis.horizontal,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Product ComboBox
                  buildComboBox(
                    context: context,
                    hint: 'Product',
                    options: productOptions,
                    selectedValue: selectedProduct,
                    onSelected: (value) {
                      setState(() => selectedProduct = value);
                      context.read<YieldBloc>().add(FilterYields(
                            productName: value == 'All' ? null : value,
                            sector:
                                selectedSector == 'All' ? null : selectedSector,
                            barangay: selectedBarangay == 'All'
                                ? null
                                : selectedBarangay,
                            status:
                                selectedStatus == 'All' ? null : selectedStatus,
                            year: selectedYear,
                          ));
                    },
                    width: 150,
                  ),

                  // Status ComboBox
                  buildComboBox(
                    context: context,
                    hint: 'Status',
                    options: const ['All', 'Pending', 'Accepted', 'Rejected'],
                    selectedValue: selectedStatus,
                    onSelected: (value) {
                      setState(() => selectedStatus = value);
                      context.read<YieldBloc>().add(FilterYields(
                            status: value == 'All' ? null : value,
                            sector:
                                selectedSector == 'All' ? null : selectedSector,
                            barangay: selectedBarangay == 'All'
                                ? null
                                : selectedBarangay,
                            productName: selectedProduct == 'All'
                                ? null
                                : selectedProduct,
                            year: selectedYear,
                          ));
                    },
                    width: 150,
                  ),

                  Container(
                    width: 200,
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
                        context.read<YieldBloc>().add(SearchYields(value));
                      },
                    ),
                  ),

                  const SizedBox(width: 8),

                  // ADD EXPORT BUTTON HERE
                  BlocBuilder<YieldBloc, YieldState>(
                    builder: (context, state) {
                      final yields = state is YieldsLoaded ? state.yields : [];
                      return ExportButtonWidget(yields: yields.cast<Yield>());
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBarDesktop() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
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
        // Add similar listeners for FarmerBloc and FarmBloc if needed
      ],
      child: Builder(
        builder: (context) {
          // Get all states at once
          final productState = context.watch<ProductBloc>().state;
          final farmerState = context.watch<FarmerBloc>().state;
          final farmState = context.watch<FarmBloc>().state;

          // Check if all data is loaded
          final allDataLoaded = productState is ProductsLoaded &&
              farmerState is FarmersLoaded &&
              farmState is FarmsLoaded;

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
                    context.read<YieldBloc>().add(FilterYields(
                          productName: value == 'All' ? null : value,
                          sector:
                              selectedSector == 'All' ? null : selectedSector,
                          barangay: selectedBarangay == 'All'
                              ? null
                              : selectedBarangay,
                          status:
                              selectedStatus == 'All' ? null : selectedStatus,
                          year: selectedYear,
                        ));
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
                    context.read<YieldBloc>().add(FilterYields(
                          status: value == 'All' ? null : value,
                          sector:
                              selectedSector == 'All' ? null : selectedSector,
                          barangay: selectedBarangay == 'All'
                              ? null
                              : selectedBarangay,
                          productName:
                              selectedProduct == 'All' ? null : selectedProduct,
                          year: selectedYear,
                        ));
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
                        context.read<YieldBloc>().add(SearchYields(value));
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // ADD EXPORT BUTTON HERE
                BlocBuilder<YieldBloc, YieldState>(
                  builder: (context, state) {
                    final yields = state is YieldsLoaded ? state.yields : [];
                    return ExportButtonWidget(yields: yields.cast<Yield>());
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
    Key? key,
  }) : super(key: key);

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
  void onCellTap(BuildContext context, TableDataRowsTableDataRows columnData, YieldsViewModel viewModel) {
 
    
    final yield = viewModel.yields.firstWhere(
      (p) => p.id.toString() == columnData.id,
    );
    // Navigate to YieldProfile when any cell in the row is tapped
    Navigator.push(
      context,
     MaterialPageRoute(
                      builder: (context) => YieldProfile(yieldData: yield),
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

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isFarmer = userProvider.isFarmer;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            ModalDialog.show(
              context: context,
              title: 'Delete Yield',
              showTitle: true,
              showTitleDivider: true,
              modalType: ModalType.medium,
              onCancelTap: () => Navigator.of(context).pop(),
              onSaveTap: () {
                context.read<YieldBloc>().add(DeleteYield(yield.id));
                Navigator.of(context).pop();
              },
              child: Center(
                child:
                    Text('Are you sure you want to delete this yield record?'),
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
                            context
                                .read<YieldBloc>()
                                .add(DeleteYield(yield.id));
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

        // Farmer Name
        if (!isFarmer)
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () {
              // context.read<YieldBloc>().add(ApproveYield(yield.id));
            },
          ),

        IconButton(
          icon: const Icon(Icons.chevron_right_sharp),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => YieldProfile(yieldData: yield),
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

// Add this helper method to your YieldsViewModel class
  String _getYieldWithUnit(double? volume, int? sectorId) {
    if (volume == null) return 'N/A';

    // Assuming sectorId 1 is for crops measured in kg, and others might be heads, etc.
    switch (sectorId) {
      case 1: // Crop sector (kg)
        return '${volume.toStringAsFixed(volume % 1 == 0 ? 0 : 1)} kg';
      case 2: // Livestock sector (heads)
        return '${volume.toInt()} heads';
      // Add more cases for other sectors as needed
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
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isFarmer = userProvider.isFarmer;

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

      // Product
      var productCell = TableDataRowsTableDataRows()
        ..text = yieldRecord.productName
        ..dataType = CellDataType.TEXT.type
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
    Key? key,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isFarmer = userProvider.isFarmer;

    if (widget.state.yields.isEmpty) {
      return CommonCard(
        margin: EdgeInsets.all(0),
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text('No yields available'),
        ),
      );
    }

    return CommonCard(
      margin: EdgeInsets.all(0),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // List content
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: currentPageData.length,
              itemBuilder: (context, index) {
                final yield = currentPageData[index];
                final sectorIcon = _getSectorIcon(yield.sectorId);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getSectorColor(yield.sectorId),
                    child: yield.productImage != null
                        ? ClipOval(
                            child: Image.network(
                              yield.productImage!,
                              fit: BoxFit.cover,
                              width: 40,
                              height: 40,
                            ),
                          )
                        : Icon(sectorIcon, color: Colors.white),
                  ),
                  title: Text(
                    isFarmer
                        ? yield.productName ?? 'N/A'
                        : '${yield.farmerName}  • ${yield.productName}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${_getYieldWithUnit(yield.volume, yield.sectorId)} • ${_formatDate(yield.createdAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: _getStatusColor(yield.status ?? 'N/A'),
                          shape: BoxShape.circle,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                YieldProfile(yieldData: yield),
                          ),
                        ),
                      ),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => YieldProfile(yieldData: yield),
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
                      color:
                          currentPage > 0 ? GlobalColors.primary : Colors.grey,
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
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
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
      ),
    );
  }

  IconData _getSectorIcon(int? sectorId) {
    switch (sectorId) {
      case 1:
        return Icons.grass; // Crops
      case 2:
        return Icons.agriculture; // Livestock
      case 3:
        return Icons.water_drop; // Fisheries
      default:
        return Icons.category;
    }
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

  Color _getSectorColor(int? sectorId) {
    switch (sectorId) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return GlobalColors.primary;
      default:
        return Colors.grey;
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

