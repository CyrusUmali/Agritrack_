import 'package:flareline/core/models/assocs_model.dart';
import 'package:flareline/pages/assoc/assoc_bloc/assocs_bloc.dart';
import 'package:flareline/pages/assoc/assoc_filter_widget.dart';
import 'package:flareline/pages/assoc/assoc_profile.dart';
import 'package:flareline/pages/toast/toast_helper.dart';
import 'package:flareline/pages/widget/network_error.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flareline_uikit/components/modal/modal_dialog.dart';
import 'package:flareline_uikit/components/tables/table_widget.dart';
import 'package:flareline_uikit/entity/table_data_entity.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:toastification/toastification.dart';

class AssocsWidget extends StatelessWidget {
  final int selectedYear; // Add selectedYear parameter
  const AssocsWidget({super.key, required this.selectedYear});

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout.builder(
      desktop: (context) => _assocsWeb(context),
      mobile: (context) => _assocsMobile(context),
      tablet: (context) => _assocsMobile(context),
    );
  }

  Widget _assocsWeb(BuildContext context) {
    return BlocListener<AssocsBloc, AssocsState>(
      listenWhen: (previous, current) {
        return current is AssocsLoaded || current is AssocsError;
      },
      listener: (context, state) {
        if (state is AssocsLoaded && state.message != null) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.flat,
            title: Text(state.message!),
            alignment: Alignment.topRight,
            showProgressBar: false,
            autoCloseDuration: const Duration(seconds: 3),
          );
        } else if (state is AssocsError) {
          ToastHelper.showErrorToast(state.message, context, maxLines: 3);
        }
      },
      child: SizedBox(
        height: 550,
        child: Column(
          children: [
            AssociationFilterWidget(),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<AssocsBloc, AssocsState>(
                builder: (context, state) {
                  if (state is AssocsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is AssocsError) {
                    return NetworkErrorWidget(
                      error: state.message,
                      onRetry: () {
                        context
                            .read<AssocsBloc>()
                            .add(LoadAssocs(year: selectedYear));
                      },
                    );
                  } else if (state is AssocsLoaded) {
                    if (state.associations.isEmpty) {
                      return _buildNoResultsWidget();
                    }
                    return Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DataTableWidget(
                            key: ValueKey(
                                'assocs_table_${state.associations.length}_$selectedYear'), // Include year in key
                            associations: state.associations,
                            selectedYear: selectedYear,
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

  Widget _assocsMobile(BuildContext context) {
    return BlocListener<AssocsBloc, AssocsState>(
      listener: (context, state) {
        if (state is AssocsLoaded && state.message != null) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.flat,
            title: Text(state.message!),
            alignment: Alignment.topRight,
            showProgressBar: false,
            autoCloseDuration: const Duration(seconds: 3),
          );
        } else if (state is AssocsError) {
          ToastHelper.showErrorToast(state.message, context, maxLines: 3);
        }
      },
      child: Column(
        children: [
          AssociationFilterWidget(),
          const SizedBox(height: 16),
          SizedBox(
            height: 700,
            child: BlocBuilder<AssocsBloc, AssocsState>(
              builder: (context, state) {
                if (state is AssocsLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is AssocsError) {
                  return NetworkErrorWidget(
                    error: state.message,
                    onRetry: () {
                      context
                          .read<AssocsBloc>()
                          .add(LoadAssocs(year: selectedYear));
                    },
                  );
                } else if (state is AssocsLoaded) {
                  if (state.associations.isEmpty) {
                    return _buildNoResultsWidget();
                  }
                  return DataTableWidget(
                    key: ValueKey(
                        'assocs_table_${state.associations.length}_$selectedYear'), // Include year in key
                    associations: state.associations,
                    selectedYear: selectedYear, // Pass year to table
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
            Icons.group_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Associations found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class DataTableWidget extends TableWidget<AssocsViewModel> {
  final List<Association> associations;
  final int selectedYear; // Add selectedYear

  DataTableWidget({
    required this.associations,
    required this.selectedYear, // Make it required
    super.key,
  });

  @override
  AssocsViewModel viewModelBuilder(BuildContext context) {
    return AssocsViewModel(
        context, associations, selectedYear // Pass to ViewModel
        );
  }

  @override
  Widget headerBuilder(
      BuildContext context, String headerName, AssocsViewModel viewModel) {
    if (headerName == 'Action') {
      return Text(headerName);
    }

    return InkWell(
      onTap: () {
        // Sorting can be implemented later if needed
        // context.read<AssocsBloc>().add(SortAssocs(headerName));
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
        ],
      ),
    );
  }


   @override
  void onCellTap(BuildContext context, TableDataRowsTableDataRows columnData, AssocsViewModel viewModel) {
 
    
    final association = viewModel.associations.firstWhere(
      (a) => a.id.toString() == columnData.id,
    );
    // Navigate to YieldProfile when any cell in the row is tapped
    Navigator.push(
      context,
     MaterialPageRoute(
                builder: (context) => AssocProfile(association: association),
              ),
    );
  } 

 


  @override
  Widget actionWidgetsBuilder(
    BuildContext context,
    TableDataRowsTableDataRows columnData,
    AssocsViewModel viewModel,
  ) {
    final association = viewModel.associations.firstWhere(
      (a) => a.id.toString() == columnData.id,
    );

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isAdmin = userProvider.user?.role == 'admin';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isAdmin)
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              ModalDialog.show(
                context: context,
                title: 'Delete Association',
                showTitle: true,
                showTitleDivider: true,
                modalType: ModalType.medium,
                onCancelTap: () => Navigator.of(context).pop(),
                onSaveTap: () {
                  context.read<AssocsBloc>().add(DeleteAssoc(association.id));
                  Navigator.of(context).pop();
                },
                child: Center(
                  child: Text(
                    'Are you sure you want to delete ${association.name}?',
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
                                  .read<AssocsBloc>()
                                  .add(DeleteAssoc(association.id));
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
                builder: (context) => AssocProfile(association: association),
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
        width: 1000,
        child: super.build(context),
      ),
    );
  }
}

class AssocsViewModel extends BaseTableProvider {
  final List<Association> associations;
  final int selectedYear;

  AssocsViewModel(
    super.context,
    this.associations,
    this.selectedYear, // Receive year
  );

  @override
  Future loadData(BuildContext context) async {
    const headers = [
      "Name",
      "Land Area",
      "Area Harvested",
      "Members",
      "Farms",
      "Yield Volume",
      "Production",
      "Description",
      "Action"
    ];

    List<List<TableDataRowsTableDataRows>> rows = [];

    for (final association in associations) {
      List<TableDataRowsTableDataRows> row = [];

      // Name
      var nameCell = TableDataRowsTableDataRows()
        ..text = association.name
        ..dataType = CellDataType.TEXT.type
        ..columnName = 'Name'
        ..id = association.id.toString();
      row.add(nameCell);

      var areaCell = TableDataRowsTableDataRows()
        // ..text = yieldRecord.hectare as String?
        ..text = '${association.hectare} ha'
        ..dataType = CellDataType.TEXT.type
        ..columnName = 'Area'
        ..id = association.id.toString();
      row.add(areaCell);

      var areaHavestedCell = TableDataRowsTableDataRows()
        // ..text = yieldRecord.hectare as String?
        ..text = '${association.areaHarvested} ha'
        ..dataType = CellDataType.TEXT.type
        ..columnName = 'Area Harvested'
        ..id = association.id.toString();
      row.add(areaHavestedCell);

      var totalMembersCell = TableDataRowsTableDataRows()
        ..text = association.totalMembers ?? '0'
        ..dataType = CellDataType.TEXT.type
        ..columnName = 'Members'
        ..id = association.id.toString();
      row.add(totalMembersCell);

      var totalFarmsCell = TableDataRowsTableDataRows()
        ..text = association.totalFarms.toString()
        ..dataType = CellDataType.TEXT.type
        ..columnName = 'Farms'
        ..id = association.id.toString();
      row.add(totalFarmsCell);

      var totalVolumeCell = TableDataRowsTableDataRows()
        ..text = association.volume.toString()
        ..dataType = CellDataType.TEXT.type
        ..columnName = ' Yield Volume'
        ..id = association.id.toString();
      row.add(totalVolumeCell);

      var productionCell = TableDataRowsTableDataRows()
        ..text = '${association.production} mt'
        ..dataType = CellDataType.TEXT.type
        ..columnName = 'Production'
        ..id = association.id.toString();
      row.add(productionCell);

      // Description
      var descCell = TableDataRowsTableDataRows()
        ..text = association.description ?? ''
        ..dataType = CellDataType.TEXT.type
        ..columnName = 'Description'
        ..id = association.id.toString();
      row.add(descCell);

      // Action
      var actionCell = TableDataRowsTableDataRows()
        ..text = ""
        ..dataType = CellDataType.ACTION.type
        ..columnName = 'Action'
        ..id = association.id.toString();
      row.add(actionCell);

      rows.add(row);
    }

    TableDataEntity tableData = TableDataEntity()
      ..headers = headers
      ..rows = rows;

    tableDataEntity = tableData;
  }
}
