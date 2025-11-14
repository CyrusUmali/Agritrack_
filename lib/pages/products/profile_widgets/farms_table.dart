import 'package:flareline/core/models/farms_model.dart';
import 'package:flareline/pages/farms/farm_profile.dart';
import 'package:flareline/pages/products/profile_widgets/export_farms.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:flareline_uikit/components/tables/table_widget.dart';
import 'package:flareline_uikit/entity/table_data_entity.dart';

enum FarmSortType {
  name,
  location,
  area,
  volume,
  yieldPerHectare,
}

class FarmsTable extends StatefulWidget {
  final List<Farm> farms;

  const FarmsTable({super.key, required this.farms});

  @override
  State<FarmsTable> createState() => _FarmsTableState();
}

class _FarmsTableState extends State<FarmsTable> {
  FarmSortType _sortType = FarmSortType.name;
  bool _sortAscending = true;
  List<Farm> _sortedFarms = [];

  @override
  void initState() {
    super.initState();
    _sortedFarms = List.from(widget.farms);
    _sortFarms(null);
  }

  @override
  void didUpdateWidget(FarmsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.farms != widget.farms) {
      _sortedFarms = List.from(widget.farms);
      _sortFarms(null);
    }
  }

  void _sortFarms(bool? isFarmer) {
    _sortedFarms.sort((a, b) {
      int comparison = 0;

      switch (_sortType) {
        case FarmSortType.name:
          comparison = (a.name ?? '').compareTo(b.name ?? '');
          break;
        case FarmSortType.location:
          comparison = (a.barangay ?? '').compareTo(b.barangay ?? '');
          break;
        case FarmSortType.area:
          final aArea = a.hectare ?? 0;
          final bArea = b.hectare ?? 0;
          comparison = aArea.compareTo(bArea);
          break;
        case FarmSortType.volume:
          if (isFarmer == true) {
            comparison = 0;
          } else {
            final aVolume = a.volume ?? 0;
            final bVolume = b.volume ?? 0;
            comparison = aVolume.compareTo(bVolume);
          }
          break;
        case FarmSortType.yieldPerHectare:
          if (isFarmer == true) {
            comparison = 0;
          } else {
            final aYield = _calculateYieldPerHectare(a);
            final bYield = _calculateYieldPerHectare(b);
            comparison = aYield.compareTo(bYield);
          }
          break;
      }

      return _sortAscending ? comparison : -comparison;
    });
  }

  double _calculateYieldPerHectare(Farm farm) {
    final volume = farm.volume ?? 0;
    final area = farm.hectare ?? 0;
    if (area == 0) return 0.0;
    return (volume / 1000) / area;
  }

  void _onSort(FarmSortType sortType, bool isFarmer) {
    if (isFarmer &&
        (sortType == FarmSortType.volume ||
            sortType == FarmSortType.yieldPerHectare)) {
      return;
    }

    setState(() {
      if (_sortType == sortType) {
        _sortAscending = !_sortAscending;
      } else {
        _sortType = sortType;
        _sortAscending = true;
      }
      _sortFarms(isFarmer);
    });
  }

  String _formatVolume(int? volume) {
    if (volume == null || volume == 0) return 'N/A';
    if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)} t';
    }
    return '$volume kg';
  }

  String _formatYieldPerHectare(Farm farm) {
    final yieldValue = _calculateYieldPerHectare(farm);
    if (yieldValue == 0) return 'N/A';
    return '${yieldValue.toStringAsFixed(2)} t/ha';
  }



@override
Widget build(BuildContext context) {
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  final isFarmer = userProvider.isFarmer;

  // COMPLETELY bypass CommonCard and use a simple Container
  return Container(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Farms Growing This Product (${widget.farms.length})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            if (widget.farms.isNotEmpty) ...[
              FarmsExportButtonWidget(farms: widget.farms),
              const SizedBox(width: 12),
            ],
          ],
        ),
        const SizedBox(height: 16),
        if (widget.farms.isEmpty)
          _buildNoResultsWidget()
        else
          ScreenTypeLayout.builder(
            desktop: (context) => _farmsWeb(context, isFarmer),
            mobile: (context) => _farmsMobile(context, isFarmer),
            tablet: (context) => _farmsMobile(context, isFarmer),
          ),
      ],
    ),
  );
}


  // COPY THE EXACT STRUCTURE FROM FarmsTableWidget
  Widget _farmsWeb(BuildContext context, bool isFarmer) {
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
    } else {
      height = screenHeight * 0.3;  
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: 800,
      ),
      child: SizedBox(
        height: height,
        child: Column(
          children: [ 
            Expanded(
              child: FarmsDataTableWidget(
                 key: ValueKey('farms_table_${_sortType}_${_sortAscending}_${_sortedFarms.length}'), // This forces rebuild
                farms: _sortedFarms,
                isFarmer: isFarmer,
                sortType: _sortType,
                sortAscending: _sortAscending,
                onSort: (sortType) => _onSort(sortType, isFarmer),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _farmsMobile(BuildContext context, bool isFarmer) {
    return Column(
      children: [ 
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            minHeight: 200,
          ),
          child: MobileFarmsListWidget(
            farms: _sortedFarms,
            isFarmer: isFarmer,
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
            'No farms found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No farms are currently growing this product',
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

// Keep the rest of your FarmsDataTableWidget, FarmsTableViewModel, and MobileFarmsListWidget classes exactly as they were...
class FarmsDataTableWidget extends TableWidget<FarmsTableViewModel> {
  final List<Farm> farms;
  final bool isFarmer;
  final FarmSortType sortType;
  final bool sortAscending;
  final Function(FarmSortType) onSort;

  FarmsDataTableWidget({
    required this.farms,
    required this.isFarmer,
    required this.sortType,
    required this.sortAscending,
    required this.onSort,
    Key? key,
  }) : super(key: key);


 
  @override
  FarmsTableViewModel viewModelBuilder(BuildContext context) {
    return FarmsTableViewModel(context, farms, isFarmer);
  }

 
 


@override
Widget headerBuilder(
    BuildContext context, String headerName, FarmsTableViewModel viewModel) {
  if (headerName == 'Action') {
    return Text(headerName);
  }

  // Map header names to FarmSortType
  FarmSortType? getSortTypeForHeader(String header) {
    switch (header) {
      case 'Name':
        return FarmSortType.name;
      case 'Location':
        return FarmSortType.location;
      case 'Area (ha)':
        return FarmSortType.area;
      case 'Volume':
        return FarmSortType.volume;
      case 'Yield/Ha':
        return FarmSortType.yieldPerHectare;
      default:
        return null;
    }
  }

  final headerSortType = getSortTypeForHeader(headerName);
  final isSortable = headerSortType != null;
  final isSelected = sortType == headerSortType;

  // Don't make volume and yield headers interactive for farmers
  final isDisabledForFarmer = isFarmer &&
      (headerSortType == FarmSortType.volume ||
          headerSortType == FarmSortType.yieldPerHectare);

  // Create the header content widget
  Widget headerContent = Row(
    mainAxisAlignment: MainAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(
        child: Text(
          headerName,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isDisabledForFarmer
                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
                : null,
          ),
        ),
      ),
      if (isSortable && !isDisabledForFarmer) ...[
        const SizedBox(width: 4),
        Icon(
          isSelected
              ? (sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
              : Icons.unfold_more,
          size: 16,
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey,
        ),
      ],
    ],
  );

  // If not sortable or disabled for farmer, return just the content
  if (!isSortable || isDisabledForFarmer) {
    return headerContent;
  }

  // For sortable headers, wrap with InkWell
  return InkWell(
  onTap: () {
  print('Tapped on $headerName header, sortType: $headerSortType');
  onSort(headerSortType!);
},
    child: headerContent,
  );
}


  @override
  void onCellTap(BuildContext context, TableDataRowsTableDataRows columnData, 
      FarmsTableViewModel viewModel) {
    final farm = viewModel.farms.firstWhere(
      (f) => f.id.toString() == columnData.id,
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FarmProfile(farmId: farm.id ?? 0),
      ),
    );
  }






  @override
  Widget actionWidgetsBuilder(
    BuildContext context,
    TableDataRowsTableDataRows columnData,
    FarmsTableViewModel viewModel,
  ) {
    final farm = viewModel.farms.firstWhere(
      (f) => f.id.toString() == columnData.id,
    );

    return IconButton(
      icon: Icon(Icons.chevron_right_sharp),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FarmProfile(farmId: farm.id ?? 0),
          ),
        );
      },
    );
  }






  @override
  Widget build(BuildContext context) {
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








}




class FarmsTableViewModel extends BaseTableProvider {
  final List<Farm> farms;
  final bool isFarmer;

  FarmsTableViewModel(super.context, this.farms, this.isFarmer);

  double _calculateYieldPerHectare(Farm farm) {
    final volume = farm.volume ?? 0;
    final area = farm.hectare ?? 0;
    if (area == 0) return 0.0;
    return (volume / 1000) / area;
  }

  String _formatVolume(int? volume) {
    if (volume == null || volume == 0) return 'N/A';
    if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)} t';
    }
    return '$volume kg';
  }

  String _formatYieldPerHectare(Farm farm) {
    final yieldValue = _calculateYieldPerHectare(farm);
    if (yieldValue == 0) return 'N/A';
    return '${yieldValue.toStringAsFixed(2)} t/ha';
  }

  @override
  Future loadData(BuildContext context) async {
    final headers = isFarmer
        ? ["Name", "Location", "Area (ha)", "Status", "Action"]
        : ["Name", "Location", "Area (ha)", "Volume", "Yield/Ha", "Status", "Action"];

    List<List<TableDataRowsTableDataRows>> rows = [];

    for (final farm in farms) {
      List<TableDataRowsTableDataRows> row = [];

      // Name
      var nameCell = TableDataRowsTableDataRows()
        ..text = farm.name ?? 'Unknown'
        ..dataType = CellDataType.TEXT.type
        ..columnName = 'Name'
        ..id = farm.id?.toString() ?? '';
      row.add(nameCell);

      // Location
      var locationCell = TableDataRowsTableDataRows()
        ..text = farm.barangay ?? 'Unknown location'
        ..dataType = CellDataType.TEXT.type
        ..columnName = 'Location'
        ..id = farm.id?.toString() ?? '';
      row.add(locationCell);

      // Area
      var areaCell = TableDataRowsTableDataRows()
        ..text = farm.hectare?.toStringAsFixed(1) ?? 'N/A'
        ..dataType = CellDataType.TEXT.type
        ..columnName = 'Area (ha)'
        ..id = farm.id?.toString() ?? '';
      row.add(areaCell);

      // Volume (only for non-farmers)
      if (!isFarmer) {
        var volumeCell = TableDataRowsTableDataRows()
          ..text = _formatVolume(farm.volume)
          ..dataType = CellDataType.TEXT.type
          ..columnName = 'Volume'
          ..id = farm.id?.toString() ?? '';
        row.add(volumeCell);

        // Yield/Ha (only for non-farmers)
        var yieldCell = TableDataRowsTableDataRows()
          ..text = _formatYieldPerHectare(farm)
          ..dataType = CellDataType.TEXT.type
          ..columnName = 'Yield/Ha'
          ..id = farm.id?.toString() ?? '';
        row.add(yieldCell);
      }

      // Status
      var statusCell = TableDataRowsTableDataRows()
        ..text = 'Active' // You might want to get this from farm data
        ..dataType = CellDataType.TEXT.type
        ..columnName = 'Status'
        ..id = farm.id?.toString() ?? '';
      row.add(statusCell);

      // Action
      var actionCell = TableDataRowsTableDataRows()
        ..text = ""
        ..dataType = CellDataType.ACTION.type
        ..columnName = 'Action'
        ..id = farm.id?.toString() ?? '';
      row.add(actionCell);

      rows.add(row);
    }

    TableDataEntity tableData = TableDataEntity()
      ..headers = headers
      ..rows = rows;

    tableDataEntity = tableData;
  }
}

class MobileFarmsListWidget extends StatefulWidget {
  final List<Farm> farms;
  final bool isFarmer;
  final int itemsPerPage;

  const MobileFarmsListWidget({
    required this.farms,
    required this.isFarmer,
    this.itemsPerPage = 10,
    Key? key,
  }) : super(key: key);

  @override
  State<MobileFarmsListWidget> createState() => _MobileFarmsListWidgetState();
}

class _MobileFarmsListWidgetState extends State<MobileFarmsListWidget> {
  int currentPage = 0;

  int get totalPages => (widget.farms.length / widget.itemsPerPage).ceil();

  List<Farm> get currentPageData {
    final startIndex = currentPage * widget.itemsPerPage;
    final endIndex =
        (startIndex + widget.itemsPerPage).clamp(0, widget.farms.length);
    return widget.farms.sublist(startIndex, endIndex);
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

  double _calculateYieldPerHectare(Farm farm) {
    final volume = farm.volume ?? 0;
    final area = farm.hectare ?? 0;
    if (area == 0) return 0.0;
    return (volume / 1000) / area;
  }

  String _formatVolume(int? volume) {
    if (volume == null || volume == 0) return 'N/A';
    if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)} t';
    }
    return '$volume kg';
  }

  String _formatYieldPerHectare(Farm farm) {
    final yieldValue = _calculateYieldPerHectare(farm);
    if (yieldValue == 0) return 'N/A';
    return '${yieldValue.toStringAsFixed(2)} t/ha';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.farms.isEmpty) {
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

                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      color: Colors.green.withOpacity(0.3),
                      border: Border.all(color: Colors.green, width: 2.0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.agriculture, color: Colors.green),
                  ),
                  title: Text(
                    farm.name ?? 'Unknown',
                    style: TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${farm.barangay ?? 'Unknown location'} • ${farm.hectare?.toStringAsFixed(1) ?? 'N/A'} ha',
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!widget.isFarmer) ...[
                        Text(
                          '${_formatVolume(farm.volume)} • ${_formatYieldPerHectare(farm)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green, width: 1),
                        ),
                        child: Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FarmProfile(farmId: farm.id ?? 0),
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
                  top: BorderSide(color: Colors.grey.shade300, width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: currentPage > 0 ? _previousPage : null,
                    icon: Icon(
                      Icons.chevron_left,
                      color: currentPage > 0 ? Colors.blue : Colors.grey,
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...List.generate(
                          totalPages.clamp(0, 5),
                          (index) {
                            int pageIndex;
                            if (totalPages <= 5) {
                              pageIndex = index;
                            } else {
                              int start = (currentPage - 2).clamp(0, totalPages - 5);
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
                                      ? Colors.blue
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: currentPage == pageIndex
                                        ? Colors.blue
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
                        if (totalPages > 5)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text('...', style: TextStyle(color: Colors.grey)),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: currentPage < totalPages - 1 ? _nextPage : null,
                    icon: Icon(
                      Icons.chevron_right,
                      color: currentPage < totalPages - 1 ? Colors.blue : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

          if (totalPages > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Page ${currentPage + 1} of $totalPages • ${widget.farms.length} total farms',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
        ],
      ),
    );
  }
}