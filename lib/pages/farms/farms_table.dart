import 'package:flareline/core/models/farms_model.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/pages/farms/farm_bloc/farm_bloc.dart';
import 'package:flareline/pages/farms/farm_profile.dart';
import 'package:flareline/pages/test/map_widget/pin_style.dart';
import 'package:flareline/pages/test/map_widget/stored_polygons.dart';
import 'package:flareline/pages/toast/toast_helper.dart';
import 'package:flareline/pages/widget/combo_box.dart';
import 'package:flareline/pages/widget/network_error.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flareline_uikit/components/modal/modal_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline_uikit/components/tables/table_widget.dart';
import 'package:flareline_uikit/entity/table_data_entity.dart';
import 'package:provider/provider.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:toastification/toastification.dart';

class FarmsTableWidget extends StatefulWidget {
  const FarmsTableWidget({super.key});

  @override
  State<FarmsTableWidget> createState() => _FarmsTableWidgetState();
}

class _FarmsTableWidgetState extends State<FarmsTableWidget> {
  String selectedSector = '';
  String selectedStatus = '';
  String selectedBarangay = '';
  late List<String> barangayNames;
  String _barangayFilter = '';

  @override
  void initState() {
    super.initState();

    barangayNames = barangays.map((b) => b['name'] as String).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FarmBloc, FarmState>(
      listenWhen: (previous, current) =>
          current is FarmsLoaded || current is FarmsError,
      listener: (context, state) {
        if (state is FarmsLoaded && state.message != null) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.flat,
            title: Text(state.message!),
            alignment: Alignment.topRight,
            showProgressBar: false,
            autoCloseDuration: const Duration(seconds: 3),
          );
        } else if (state is FarmsError) {
          ToastHelper.showErrorToast(state.message, context, maxLines: 3);
        }
      },
      child: ScreenTypeLayout.builder(
        desktop: (context) => _farmsWeb(context),
        mobile: (context) => _farmsMobile(context),
        tablet: (context) => _farmsMobile(context),
      ),
    );
  }

  Widget _farmsWeb(BuildContext context) {



  final screenHeight = MediaQuery.of(context).size.height;
   
 double height;
 

if (screenHeight < 400) {
  height = screenHeight * 0.6;  
} else if (screenHeight < 600) {
  height = screenHeight * 0.50;  
} else if (screenHeight < 800) {
  height = screenHeight * 0.56;  
} else if (screenHeight < 1000) {
  height = screenHeight * 0.63;  
}  else {
  height = screenHeight * 0.3;  
}


    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: 800,
        // You can also set minHeight if needed
        // minHeight: 200,
      ),
      child: SizedBox(
        // height: MediaQuery.of(context).size.height * 0.70,
        height: height,
        child: Column(
          children: [
            _buildSearchBarDesktop(context),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<FarmBloc, FarmState>(
                builder: (context, state) {
                  if (state is FarmsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is FarmsError) {
                    return NetworkErrorWidget(
                      error: state.message,
                      onRetry: () {
                        context.read<FarmBloc>().add(LoadFarms());
                      },
                    );
                  } else if (state is FarmsLoaded) {
                    if (state.farms.isEmpty) {
                      return _buildNoResultsWidget();
                    }
                    return Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DataTableWidget(
                            key: ValueKey(
                                'farms_table_${state.farms.length}_${context.read<FarmBloc>().sortColumn}_${context.read<FarmBloc>().sortAscending}'),
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

  Widget _farmsMobile(BuildContext context) {
    return Column(
      children: [
        _buildSearchBarMobile(context),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(context).size.height * 0.7, // 70% of screen
            minHeight: 200, // Minimum height
          ),
          child: BlocBuilder<FarmBloc, FarmState>(
            builder: (context, state) {
              if (state is FarmsLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is FarmsError) {
                return NetworkErrorWidget(
                  error: state.message,
                  onRetry: () {
                    context.read<FarmBloc>().add(LoadFarms());
                  },
                );
              } else if (state is FarmsLoaded) {
                if (state.farms.isEmpty) {
                  return _buildNoResultsWidget();
                }
                return MobileFarmListWidget(
                  // key: ValueKey(
                  //     'farms_table_${state.farms.length}_${state.sortColumn}_${state.sortAscending}'),
                  key: ValueKey(
                      'farms_table_${state.farms.length}_${context.read<FarmBloc>().sortColumn}_${context.read<FarmBloc>().sortAscending}'),

                  state: state,
                );
              }
              return _buildNoResultsWidget();
            },
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

  Widget _buildSearchBarMobile(BuildContext context) {
    return SizedBox(
      height: 48,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Wrap(
          direction: Axis.horizontal,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8, // Vertical spacing between lines when wrapping
          children: [
            // Sector ComboBox
            buildComboBox(
              context: context,
              hint: 'Sector',
              options: const [
                'All',
                'Rice',
                'Livestock',
                'Fishery',
                'Corn',
                'HVC',
                'Organic'
              ],
              selectedValue: selectedSector,
              onSelected: (value) {
                setState(() => selectedSector = value);
                context.read<FarmBloc>().add(FilterFarms(
                    name: '',
                    sector: (value == 'All' || value.isEmpty) ? null : value,
                    barangay: selectedBarangay,
                    status: selectedStatus));
              },
              width: 150,
            ),

            // Barangay ComboBox
            buildComboBox(
              context: context,
              hint: 'Barangay',
              options: [
                'All',
                ...barangayNames.where((String option) {
                  return option
                      .toLowerCase()
                      .contains(_barangayFilter.toLowerCase());
                })
              ],
              selectedValue: selectedBarangay,
              onSelected: (value) {
                setState(() => selectedBarangay = value);
                context.read<FarmBloc>().add(FilterFarms(
                    name: '',
                    barangay: value == 'All' ? null : value,
                    sector: selectedSector,
                    status: selectedStatus));
              },
              width: 150,
            ),

            buildComboBox(
              context: context,
              hint: 'Status',
              options: ['All', 'Active', 'Inactive'],
              selectedValue: selectedStatus,
              onSelected: (value) {
                setState(() => selectedStatus = value);
                context.read<FarmBloc>().add(FilterFarms(
                    name: '',
                    barangay: value == 'All' ? null : value,
                    sector: selectedSector,
                    status: selectedStatus));
              },
              width: 150,
            ),

            Container(
              width: 200, // Set a minimum width for the search field
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (value) {
                  context.read<FarmBloc>().add(SearchFarms(value));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBarDesktop(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sector ComboBox
          buildComboBox(
            context: context,
            hint: 'Sector',
            options: const [
              'All',
              'Rice',
              'Livestock',
              'Fishery',
              'Corn',
              'HVC',
              'Organic'
            ],
            selectedValue: selectedSector,
            onSelected: (value) {
              setState(() => selectedSector = value);
              context.read<FarmBloc>().add(FilterFarms(
                  name: '',
                  sector: (value == 'All' || value.isEmpty) ? null : value,
                  barangay: selectedBarangay,
                  status: selectedStatus));
            },
            width: 150,
          ),
          const SizedBox(width: 8),

          // Barangay ComboBox
          buildComboBox(
            context: context,
            hint: 'Barangay',
            options: [
              'All',
              ...barangayNames.where((String option) {
                return option
                    .toLowerCase()
                    .contains(_barangayFilter.toLowerCase());
              })
            ],
            selectedValue: selectedBarangay,
            onSelected: (value) {
              setState(() => selectedBarangay = value);
              context.read<FarmBloc>().add(FilterFarms(
                  name: '',
                  barangay: value == 'All' ? null : value,
                  sector: selectedSector,
                  status: selectedStatus));
            },
            width: 150,
          ),
          const SizedBox(width: 8),

          buildComboBox(
            context: context,
            hint: 'Status',
            options: ['All', 'Active', 'Inactive'],
            selectedValue: selectedStatus,
            onSelected: (value) {
              setState(() => selectedStatus = value);
              context.read<FarmBloc>().add(FilterFarms(
                  name: '',
                  barangay: value == 'All' ? null : value,
                  sector: selectedSector,
                  status: selectedStatus));
            },
            width: 150,
          ),
          const SizedBox(width: 8),

          // Search Field
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
                  hintText: 'Search Farms...',
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (value) {
                  context.read<FarmBloc>().add(SearchFarms(value));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DataTableWidget extends TableWidget<FarmsViewModel> {
  final FarmsLoaded state;

  DataTableWidget({
    required this.state,
    Key? key,
  }) : super(key: key);

  @override
  FarmsViewModel viewModelBuilder(BuildContext context) {
    return FarmsViewModel(context, state);
  }

  @override
  Widget headerBuilder(
      BuildContext context, String headerName, FarmsViewModel viewModel) {
    if (headerName == 'Action') {
      return Text(headerName);
    }

    return InkWell(
      onTap: () {
        context.read<FarmBloc>().add(SortFarms(headerName));
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
          BlocBuilder<FarmBloc, FarmState>(
            builder: (context, state) {
              if (state is FarmsLoaded) {
                final bloc = context.read<FarmBloc>();
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
  void onCellTap(BuildContext context, TableDataRowsTableDataRows columnData, FarmsViewModel viewModel) {
 
    
   final farm = viewModel.state.farms.firstWhere(
      (f) => f.id.toString() == columnData.id,
    );
 
    // Navigate to YieldProfile when any cell in the row is tapped
    Navigator.push(
      context,
      MaterialPageRoute(
                      builder: (context) => FarmProfile(farmId: farm.id),
                    ),
    );
  }

 

  @override
  Widget actionWidgetsBuilder(
    BuildContext context,
    TableDataRowsTableDataRows columnData,
    FarmsViewModel viewModel,
  ) {
    final farm = viewModel.state.farms.firstWhere(
      (f) => f.id.toString() == columnData.id,
    );

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isAdmin = userProvider.user?.role == 'admin';
    final isFarmerOwner = userProvider.farmer?.id == farm.farmerId;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isAdmin || isFarmerOwner)
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              ModalDialog.show(
                context: context,
                title: 'Delete Farm',
                showTitle: true,
                showTitleDivider: true,
                modalType: ModalType.medium,
                onCancelTap: () => Navigator.of(context).pop(),
                onSaveTap: () {
                  context.read<FarmBloc>().add(DeleteFarm(farm.id!));
                  Navigator.of(context).pop();
                },
                child: Center(
                  child: Text(
                    'Are you sure you want to delete ${farm.name}?',
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
                                  .read<FarmBloc>()
                                  .add(DeleteFarm(farm.id!));
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
                builder: (context) => FarmProfile(farmId: farm.id),
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

class FarmsViewModel extends BaseTableProvider {
  final FarmsLoaded state;

  FarmsViewModel(super.context, this.state);

  @override
  Future loadData(BuildContext context) async {
    const headers = [
      "Name",
      "Owner",
      "Barangay",
      "Hectare",
      "Sector",
      "Status",
      "Action"
    ];

    List<List<TableDataRowsTableDataRows>> rows = [];

    for (final farm in state.farms) {
      List<TableDataRowsTableDataRows> row = [];

      var nameCell = TableDataRowsTableDataRows()
        ..text = farm.name
        ..dataType = CellDataType.TEXT.type
        ..columnName = 'Name'
        ..id = farm.id.toString();
      row.add(nameCell);

      var ownerCell = TableDataRowsTableDataRows()
        ..text = farm.owner
        ..dataType = CellDataType.TEXT.type
        ..columnName = 'Owner'
        ..id = farm.id.toString();
      row.add(ownerCell);

      var barangayCell = TableDataRowsTableDataRows()
        ..text = farm.barangay
        ..dataType = CellDataType.TEXT.type
        ..columnName = 'Barangay'
        ..id = farm.id.toString();
      row.add(barangayCell);

      var hectareCell = TableDataRowsTableDataRows()
        ..text = '${farm.hectare} ha'
        ..dataType = CellDataType.TEXT.type
        ..columnName = 'Hectare'
        ..id = farm.id.toString();
      row.add(hectareCell);

      var sectorCell = TableDataRowsTableDataRows()
        ..text = farm.sector
        ..dataType = CellDataType.TEXT.type
        ..columnName = 'Sector'
        ..id = farm.id.toString();
      row.add(sectorCell);

      var statusCell = TableDataRowsTableDataRows()
        ..text = farm.status
        ..dataType = CellDataType.TEXT.type
        ..columnName = 'Status'
        ..id = farm.id.toString();
      row.add(statusCell);

      var actionCell = TableDataRowsTableDataRows()
        ..text = ""
        ..dataType = CellDataType.ACTION.type
        ..columnName = 'Action'
        ..id = farm.id.toString();
      row.add(actionCell);

      rows.add(row);
    }

    TableDataEntity tableData = TableDataEntity()
      ..headers = headers
      ..rows = rows;

    tableDataEntity = tableData;
  }
}

class MobileFarmListWidget extends StatefulWidget {
  final FarmsLoaded state;
  final int itemsPerPage;

  const MobileFarmListWidget({
    required this.state,
    this.itemsPerPage = 10,
    Key? key,
  }) : super(key: key);

  @override
  State<MobileFarmListWidget> createState() => _MobileFarmListWidgetState();
}

class _MobileFarmListWidgetState extends State<MobileFarmListWidget> {
  int currentPage = 0;

  int get totalPages =>
      (widget.state.farms.length / widget.itemsPerPage).ceil();

  List<Farm> get currentPageData {
    final startIndex = currentPage * widget.itemsPerPage;
    final endIndex =
        (startIndex + widget.itemsPerPage).clamp(0, widget.state.farms.length);
    return widget.state.farms.sublist(startIndex, endIndex);
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

  // Polygon Preview Widget (similar to FarmListPanel)
  Widget _buildPolygonPreview(Farm farm) {
    final pinStyle = parsePinStyle(farm.sector!);
    final sectorColor = getPinColor(pinStyle);
    final sectorIcon = getPinIcon(pinStyle);
    final exceedsLimit = _farmExceedsAreaLimit(farm);

    return Stack(
      children: [
        // Main preview container
        Container(
          width: 40, // Slightly larger for mobile touch targets
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: getPolygonColor(pinStyle).withOpacity(0.3),
            border: Border.all(
              color: exceedsLimit ? Colors.red : sectorColor,
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: sectorIcon,
          ),
        ),
        // Warning indicator for exceeding area limits
        if (exceedsLimit)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.0),
              ),
              child: Icon(
                Icons.square_foot,
                color: Colors.white,
                size: 10,
              ),
            ),
          ),
      ],
    );
  }

  // Helper method to check if farm exceeds area limit
  bool _farmExceedsAreaLimit(Farm farm) {
    // Implement your area limit logic here
    // For now, returning false as placeholder
    // You might want to check: farm.hectare > someMaximumValue
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state.farms.isEmpty) {
      return CommonCard(
        margin: EdgeInsets.all(0),
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text('No farms available'),
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
                final farm = currentPageData[index];
                final pinStyle = parsePinStyle(farm.sector!);
                final exceedsLimit = _farmExceedsAreaLimit(farm);

                return ListTile(
                  // Replaced CircleAvatar with polygon preview

                  leading: _buildPolygonPreview(farm),
                  title: Text(
                    farm.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: exceedsLimit ? Colors.red : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${farm.owner} • ${farm.barangay}',
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${farm.hectare} ha • ${farm.sector}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Add warning text if area exceeds limit
                      if (exceedsLimit)
                        Row(
                          children: [
                            Icon(Icons.square_foot,
                                size: 12, color: Colors.red),
                            SizedBox(width: 4),
                            Text(
                              'Area exceeds limit',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  // In the MobileFarmListWidget build method, replace the IconButton in the trailing section:
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(farm.status!).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStatusColor(farm.status!),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          farm.status!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(farm.status!),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      // REPLACE THIS IconButton:

                      IconButton(
                        key: ValueKey('mobile_delete_${farm.id}'),
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          ModalDialog.show(
                            context: context,
                            title: 'Delete Farm',
                            showTitle: true,
                            showTitleDivider: true,
                            modalType: ModalType.medium,
                            onCancelTap: () => Navigator.of(context).pop(),
                            onSaveTap: () {
                              context
                                  .read<FarmBloc>()
                                  .add(DeleteFarm(farm.id!));
                              Navigator.of(context).pop();
                            },
                            child: Center(
                              child: Text(
                                'Are you sure you want to delete ${farm.name}?',
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
                                        textColor:
                                            FlarelineColors.darkBlackText,
                                        onTap: () =>
                                            Navigator.of(context).pop(),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    SizedBox(
                                      width: 120,
                                      child: ButtonWidget(
                                        btnText: 'Delete',
                                        onTap: () {
                                          context
                                              .read<FarmBloc>()
                                              .add(DeleteFarm(farm.id!));
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
                    ],
                  ),

                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FarmProfile(farmId: farm.id),
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
                'Page ${currentPage + 1} of $totalPages • ${widget.state.farms.length} total farms',
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

  // Removed _getSectorIcon and _getSectorColor methods as they're replaced by pin_style.dart

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'inactive':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
