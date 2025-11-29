// ignore_for_file: must_be_immutable, avoid_print, use_super_parameters, non_constant_identifier_names

import 'package:flareline/core/models/farmer_model.dart';
import 'package:flareline/pages/assoc/assoc_bloc/assocs_bloc.dart';
import 'package:flareline/pages/widget/network_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/pages/farmers/add_farmer_modal.dart';
import 'package:flareline/pages/farmers/farmer_profile.dart';
import 'package:flareline/pages/farmers/farmer/farmer_bloc.dart';
import 'package:flareline/pages/widget/combo_box.dart';
import 'package:flareline_uikit/components/modal/modal_dialog.dart';
import 'package:flareline_uikit/components/tables/table_widget.dart';
import 'package:flareline_uikit/entity/table_data_entity.dart';
import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:toastification/toastification.dart';

import 'package:flareline/pages/test/map_widget/stored_polygons.dart';

class FarmersPerSectorWidget extends StatefulWidget {
  const FarmersPerSectorWidget({super.key});

  @override
  State<FarmersPerSectorWidget> createState() => _FarmersPerSectorWidgetState();
}

class _FarmersPerSectorWidgetState extends State<FarmersPerSectorWidget> {
  String selectedSector = '';
  String selectedAssociation = '';
  String selectedBarangay = '';
  late List<String> barangayNames;
  String _barangayFilter = ''; // Add this as a class variable

  @override
  void initState() {
    super.initState();
    barangayNames = barangays.map((b) => b['name'] as String).toList();

    context.read<AssocsBloc>().add(LoadAssocs());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FarmerBloc, FarmerState>(
      listener: (context, state) {
        if (state is FarmersLoaded && state.message != null) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.flat,
            title: Text(state.message!),
            alignment: Alignment.topRight,
            autoCloseDuration: const Duration(seconds: 3),
          );
        } else if (state is FarmersError) {
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
      child: _channels(),
    );
  }

  _channels() {
    return ScreenTypeLayout.builder(
      desktop: _channelsWeb,
      mobile: _channelMobile,
      tablet: _channelMobile,
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
}  else {
  height = screenHeight * 0.3;  
}




    return SizedBox(
      // height: 500,
      height : height,
      // height: MediaQuery.of(context).size.height * 0.7, // 70% of screen height
      child: Column(
        children: [
          _buildSearchBarDesktop(),
          const SizedBox(height: 16),
          Expanded(
            child: BlocBuilder<FarmerBloc, FarmerState>(
              builder: (context, state) {
                if (state is FarmersLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is FarmersError) {
                  return NetworkErrorWidget(
                    error: state.message,
                    onRetry: () =>
                        context.read<FarmerBloc>().add(LoadFarmers()),
                  );
                } else if (state is FarmersLoaded) {
                  if (state.farmers.isEmpty) {
                    return _buildNoResultsWidget();
                  }
                  return Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DataTableWidget(
                          key: ValueKey(
                              'farmers_table_${state.farmers.length}_${context.read<FarmerBloc>().sortColumn}_${context.read<FarmerBloc>().sortAscending}'),
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
    );
  }

  Widget _channelMobile(BuildContext context) {
    return Column(
      children: [
        _buildSearchBarMobile(),
        const SizedBox(height: 16),
        SizedBox(
          height:
              MediaQuery.of(context).size.height * 0.5, // 70% of screen height
          child: BlocBuilder<FarmerBloc, FarmerState>(
            builder: (context, state) {
              if (state is FarmersLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is FarmersError) {
                return NetworkErrorWidget(
                  error: state.message,
                  onRetry: () => context.read<FarmerBloc>().add(LoadFarmers()),
                );
              } else if (state is FarmersLoaded) {
                if (state.farmers.isEmpty) {
                  return _buildNoResultsWidget();
                }
                return DataTableWidget(
                  key: ValueKey(
                      'farmers_table_${state.farmers.length}_${context.read<FarmerBloc>().sortColumn}_${context.read<FarmerBloc>().sortAscending}'),
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
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No farmers found',
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
            // Association ComboBox
            BlocBuilder<AssocsBloc, AssocsState>(
              builder: (context, state) {
                List<String> associationOptions = ['All'];
                if (state is AssocsLoaded) {
                  associationOptions
                      .addAll(state.associations.map((a) => a.name));
                }

                return buildComboBox(
                  context: context,
                  hint: 'Association',
                  options: associationOptions,
                  selectedValue: selectedAssociation,
                  onSelected: (value) {
                    setState(() => selectedAssociation = value);
                    context.read<FarmerBloc>().add(FilterFarmers(
                          name: '',
                          association:
                              (value == 'All' || value.isEmpty) ? null : value,
                          sector: selectedSector,
                          barangay: selectedBarangay,
                        ));
                  },
                  width: 150,
                );
              },
            ),

            // Rest of your existing ComboBoxes...
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
                context.read<FarmerBloc>().add(FilterFarmers(
                      name: '',
                      sector: (value == 'All' || value.isEmpty) ? null : value,
                      barangay: selectedBarangay,
                      association: selectedAssociation,
                    ));
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
                context.read<FarmerBloc>().add(FilterFarmers(
                      name: '',
                      barangay: value == 'All' ? null : value,
                      sector: selectedSector,
                      association: selectedAssociation,
                    ));
              },
              width: 150,
            ),

            // Search Field
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
                  hintText: 'Search farmers...',
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
                  context.read<FarmerBloc>().add(SearchFarmers(value));
                },
              ),
            ),

            // Add Farmer Button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlobalColors.primary, // mediumaquamarine
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: () {
                  AddFarmerModal.show(
                    context: context,
                    onFarmerAdded: (farmerData) {
                      context.read<FarmerBloc>().add(AddFarmer(
                            name: farmerData.name,
                            email: farmerData.email,
                            sector: farmerData.sector,
                            phone: farmerData.phone,
                            barangay: farmerData.barangay,
                            imageUrl: farmerData.imageUrl,
                          ));
                    },
                  );
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 20, color: Colors.white),
                    SizedBox(width: 4),
                    Text("Add Farmer", style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBarDesktop() {
    return SizedBox(
      height: 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Association ComboBox
          BlocBuilder<AssocsBloc, AssocsState>(
            builder: (context, state) {
              List<String> associationOptions = ['All'];
              if (state is AssocsLoaded) {
                associationOptions
                    .addAll(state.associations.map((a) => a.name));
              }

              return buildComboBox(
                context: context,
                hint: 'Association',
                options: associationOptions,
                selectedValue: selectedAssociation,
                onSelected: (value) {
                  setState(() => selectedAssociation = value);
                  context.read<FarmerBloc>().add(FilterFarmers(
                        name: '',
                        association:
                            (value == 'All' || value.isEmpty) ? null : value,
                        sector: selectedSector,
                        barangay: selectedBarangay,
                      ));
                },
                width: 150,
              );
            },
          ),
          const SizedBox(width: 8),

          // Rest of your existing ComboBoxes...
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
              context.read<FarmerBloc>().add(FilterFarmers(
                    name: '',
                    sector: (value == 'All' || value.isEmpty) ? null : value,
                    barangay: selectedBarangay,
                    association: selectedAssociation,
                  ));
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
              context.read<FarmerBloc>().add(FilterFarmers(
                    name: '',

                    barangay: value == 'All'
                        ? null
                        : value, // This will trigger "All" in bloc
                    sector: selectedSector,
                    association: selectedAssociation,
                  ));
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
                  hintText: 'Search farmers...',
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
                  context.read<FarmerBloc>().add(SearchFarmers(value));
                },
              ),
            ),
          ),

          // Add Farmer Button
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            // width: 24,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GlobalColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: () {
                AddFarmerModal.show(
                  context: context,
                  onFarmerAdded: (farmerData) {
                    // Handle the farmer data here
                    context.read<FarmerBloc>().add(AddFarmer(
                          name: farmerData.name,
                          email: farmerData.email,
                          sector: farmerData.sector,
                          phone: farmerData.phone,
                          barangay: farmerData.barangay,
                          imageUrl: farmerData.imageUrl,
                        ));
                  },
                );
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add,
                    size: 20,
                    color: Colors.white,
                  ),
                  SizedBox(width: 4),
                  Text("Add Farmer", style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DataTableWidget extends TableWidget<FarmersViewModel> {
  final FarmersLoaded state;

  DataTableWidget({
    required this.state,
    Key? key,
  }) : super(key: key);

  @override
  FarmersViewModel viewModelBuilder(BuildContext context) {
    return FarmersViewModel(context, state);
  }


    @override
  void onCellTap(BuildContext context, TableDataRowsTableDataRows columnData, FarmersViewModel viewModel) {
    // Find the yield record that was clicked
    final farmer = viewModel.farmers.firstWhere(
      (p) => p.id.toString() == columnData.id,
    );
     
    Navigator.push(
      context,
 MaterialPageRoute(
                builder: (context) =>
                    FarmersProfile(farmerID: int.parse(farmer.id.toString())),
              ),
    );
  }

  @override
  Widget headerBuilder(
      BuildContext context, String headerName, FarmersViewModel viewModel) {
    if (headerName == 'Action') {
      return Text(headerName);
    }

    return InkWell(
      onTap: () {
        context.read<FarmerBloc>().add(SortFarmers(headerName));
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
          BlocBuilder<FarmerBloc, FarmerState>(
            builder: (context, state) {
              final bloc = context.read<FarmerBloc>();
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
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget actionWidgetsBuilder(
    BuildContext context,
    TableDataRowsTableDataRows columnData,
    FarmersViewModel viewModel,
  ) {
    final farmer = viewModel.farmers.firstWhere(
      (p) => p.id.toString() == columnData.id,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _showDeleteConfirmation(context, farmer),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_sharp),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    FarmersProfile(farmerID: int.parse(farmer.id.toString())),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, Farmer farmer) {
    ModalDialog.show(
      context: context,
      title: 'Delete Farmer',
      showTitle: true,
      showTitleDivider: true,
      modalType: ModalType.medium,
      child: Center(
        child: Text('Are you sure you want to delete ${farmer.name}?'),
      ),
      footer: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
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
                        .read<FarmerBloc>()
                        .add(DeleteFarmer(farmer.id as int));
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
        width: 1000,
        child: super.build(context),
      ),
    );
  }
}

class FarmersViewModel extends BaseTableProvider {
  final FarmersLoaded state;

  FarmersViewModel(super.context, this.state);

  List<Farmer> get farmers => state.farmers;

  @override
  Future loadData(BuildContext context) async {
    const headers = [
      "Name",
      "Sector",
      "Barangay",
      "Association",
      "Contact",
      "Action"
    ];

    List<List<TableDataRowsTableDataRows>> rows = [];

    for (var farmer in farmers) {
      List<TableDataRowsTableDataRows> row = [];

      var farmerNameCell = TableDataRowsTableDataRows()
        ..text = farmer.name
        ..dataType = CellDataType.IMAGE_TEXT.type
        ..columnName = 'Name'
        ..imageUrl = farmer.imageUrl
        ..id = farmer.id.toString();
      row.add(farmerNameCell);

      var sectorCell = TableDataRowsTableDataRows()
        ..text = farmer.sector ?? 'Not specified'
        ..dataType = CellDataType.TEXT.type
        ..columnName = 'Sector'
        ..id = farmer.id.toString();
      row.add(sectorCell);

      var barangayCell = TableDataRowsTableDataRows()
        ..text = farmer.barangay
        ..dataType = CellDataType.TEXT.type
        ..columnName = 'Barangay'
        ..id = farmer.id.toString();
      row.add(barangayCell);

      var associationCell = TableDataRowsTableDataRows()
        ..text = farmer.association
        ..dataType = CellDataType.TEXT.type
        ..columnName = 'Association'
        ..id = farmer.id.toString();
      row.add(associationCell);

      var contactCell = TableDataRowsTableDataRows()
        ..text = farmer.contact
        ..dataType = CellDataType.TEXT.type
        ..columnName = 'Contact'
        ..id = farmer.id.toString();
      row.add(contactCell);

      var actionCell = TableDataRowsTableDataRows()
        ..text = ""
        ..dataType = CellDataType.ACTION.type
        ..columnName = 'Action'
        ..id = farmer.id.toString();
      row.add(actionCell);

      rows.add(row);
    }

    tableDataEntity = TableDataEntity()
      ..headers = headers
      ..rows = rows;
  }
}
