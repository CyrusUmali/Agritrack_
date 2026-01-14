import 'package:flareline/pages/toast/toast_helper.dart'; 
import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/tables/table_widget.dart';
import 'package:flareline_uikit/entity/table_data_entity.dart'; 
import 'package:responsive_builder/responsive_builder.dart';
import 'package:flareline/pages/sectors/sector_profile.dart'; 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/pages/sectors/sector_service.dart';

class SectorTableWidget extends StatefulWidget {

    final int selectedYear; 
  const SectorTableWidget({super.key, required this.selectedYear});

  @override
  State<SectorTableWidget> createState() => _SectorTableWidgetState();
}

class _SectorTableWidgetState extends State<SectorTableWidget> {
  Map<String, dynamic>? selectedSector;


@override
void didUpdateWidget(covariant SectorTableWidget oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (oldWidget.selectedYear != widget.selectedYear) {
    // Trigger any necessary rebuilds or data reloads
    setState(() {});
  }
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
    return SizedBox(
      height: 450,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SectorDataTableWidget(
                    selectedYear: widget.selectedYear, // Pass it here
                    onSectorSelected: (sector) {
                      setState(() {
                        selectedSector = sector;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _channelMobile(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 380,
          child: SectorDataTableWidget(
             selectedYear: widget.selectedYear, // Pass it here
            onSectorSelected: (sector) {
              setState(() {
                selectedSector = sector;
              });
            },
          ),
        ),
      ],
    );
  }
}

class SectorDataTableWidget extends TableWidget<SectorsViewModel> {
  final Function(Map<String, dynamic>)? onSectorSelected;
    final int selectedYear; // Add this field
  late SectorsViewModel _viewModel; // Add this line to store the view model

 SectorDataTableWidget({
    this.onSectorSelected, 
    required this.selectedYear, // Make it required
     super.key,
  });


  @override
  SectorsViewModel viewModelBuilder(BuildContext context) {
    return SectorsViewModel(
      context,
      onSectorSelected,
      (id) async {
        // Implement delete functionality if needed
        RepositoryProvider.of<SectorService>(context);
        try {
         
          _viewModel.loadData(context);
        } catch (e) {
          ToastHelper.showErrorToast(
            'Failed to delete sector: ${e.toString()}',
            context, maxLines: 3
          );
        }
      },
      selectedYear, // Pass the selectedYear argument here
    );
  }



   @override
  void onCellTap(BuildContext context, TableDataRowsTableDataRows columnData, SectorsViewModel viewModel) {
 
    
 final sector = viewModel.sectors.firstWhere(
              (s) => s['id'].toString() == columnData.id,
              orElse: () => {},
            );
    // Navigate to YieldProfile when any cell in the row is tapped
    Navigator.push(
      context,
     MaterialPageRoute(
                builder: (context) => SectorProfile(sector: sector),
              ),
    );
  } 








  @override
  Widget actionWidgetsBuilder(BuildContext context,
      TableDataRowsTableDataRows columnData, SectorsViewModel viewModel) {
    viewModel.sectors.firstWhere(
      (s) => s['id'].toString() == columnData.id,
      orElse: () => {},
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_right_sharp),
          onPressed: () {
            final sector = viewModel.sectors.firstWhere(
              (s) => s['id'].toString() == columnData.id,
              orElse: () => {},
            );

            if (sector.isNotEmpty && viewModel.onSectorSelected != null) {
              viewModel.onSectorSelected!(sector);
            }
 

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SectorProfile(sector: sector),
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

class SectorsViewModel extends BaseTableProvider {
  final Function(Map<String, dynamic>)? onSectorSelected;
  final Function(int)? onSectorDeleted;
  final int selectedYear;
  List<Map<String, dynamic>> sectors = [];


  @override
  String get TAG => 'SectorsViewModel';
 SectorsViewModel(
    super.context, 
    this.onSectorSelected, 
    this.onSectorDeleted,
    this.selectedYear, 
  );



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




 







  @override
  Future loadData(BuildContext context) async {
    const headers = [
      "Sector Name",
      "Land Area",
      
      "Area Harvested",
      "Farmers",
      "Farms",
      "Yield Volume",
      "Production",
      "Action",

    ];

    try {
      final sectorService = RepositoryProvider.of<SectorService>(context);

 

      // final apiData = await sectorService.fetchSectors();
           final apiData = await sectorService.fetchSectors(year: selectedYear);
      sectors = apiData;

      List<List<TableDataRowsTableDataRows>> rows = [];

      for (var sector in apiData) {
        List<TableDataRowsTableDataRows> row = [];

        var sectorNameCell = TableDataRowsTableDataRows()
          ..text = sector['name'] ?? ''
          ..dataType = CellDataType.TEXT.type
          ..columnName = 'Sector Name'
          ..id = sector['id'].toString();
        row.add(sectorNameCell);

        var landAreaCell = TableDataRowsTableDataRows()
          ..text = '${sector['stats']?['totalLandArea']?.toString() ?? '0'} hectare'
          ..dataType = CellDataType.TEXT.type
          ..columnName = 'Land Area'
          ..id = sector['id'].toString();
        row.add(landAreaCell);

         var areaHarvestedCell = TableDataRowsTableDataRows()
          ..text = '${sector['stats']?['totalAreaHarvested']?.toString() ?? '0'} hectare'
          ..dataType = CellDataType.TEXT.type
          ..columnName = 'Area Harvested'
          ..id = sector['id'].toString();
        row.add(areaHarvestedCell);

        var farmersCell = TableDataRowsTableDataRows()
          ..text = (sector['stats']?['totalFarmers']?.toString() ?? '0')
          ..dataType = CellDataType.TEXT.type
          ..columnName = 'Farmers'
          ..id = sector['id'].toString();
        row.add(farmersCell);

        var farmsCell = TableDataRowsTableDataRows()
          ..text = (sector['stats']?['totalFarms']?.toString() ?? '0')
          ..dataType = CellDataType.TEXT.type
          ..columnName = 'Farms'
          ..id = sector['id'].toString();
        row.add(farmsCell);

        var yieldVolumeCell = TableDataRowsTableDataRows()
           ..text = _getYieldWithUnit(
          sector['stats']?['totalYieldVolume']?.toDouble(),
          sector['id']?.toInt(),
        )
          ..dataType = CellDataType.TEXT.type
          ..columnName = 'Yield Volume'
          ..id = sector['id'].toString();
        row.add(yieldVolumeCell);

       

        var productionCell = TableDataRowsTableDataRows()
          ..text = '${sector['stats']?['metricTons']?.toString() ?? '0'} mt'
          ..dataType = CellDataType.TEXT.type
          ..columnName = 'Production'
          ..id = sector['id'].toString();
        row.add(productionCell);

        var actionCell = TableDataRowsTableDataRows()
          ..text = ""
          ..dataType = CellDataType.ACTION.type
          ..columnName = 'Action'
          ..id = sector['id'].toString();
        row.add(actionCell);

        rows.add(row);
      }

      TableDataEntity tableData = TableDataEntity()
        ..headers = headers
        ..rows = rows;

      tableDataEntity = tableData;
    } catch (e) {
      // Handle error
      // You might want to show an error message to the user
    }
  }
}
