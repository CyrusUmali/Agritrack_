import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/tables/table_widget.dart';
import 'package:flareline_uikit/entity/table_data_entity.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:collection/collection.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class ReportPreview extends StatefulWidget {
  final List<Map<String, dynamic>> reportData;
  final String reportType;
  final String outputFormat;
  final Set<String> selectedColumns;
  final bool isLoading;
  final DateTimeRange dateRange;
  final String? selectedProductType;

  final String? selectedAssoc;
  final String? selectedFarmer;
  final String? selectedView;
  final String selectedBarangay;
  final String selectedSector;
  final Function(List<int>) onDeleteSelected;

  const ReportPreview({
    super.key,
    required this.reportData,
    required this.reportType,
    required this.outputFormat,
    required this.selectedColumns,
    required this.selectedAssoc,
    required this.isLoading,
    required this.dateRange,
    required this.selectedProductType,
    required this.selectedFarmer,
    required this.selectedView,
    required this.selectedBarangay,
    required this.selectedSector,
    required this.onDeleteSelected,
  });

  @override
  State<ReportPreview> createState() => _ReportPreviewState();
}

class _ReportPreviewState extends State<ReportPreview> {
  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      );
    }

    if (widget.reportData.isEmpty) {
      return Center(
        child: Text(
          'No data available. Generate a report first.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(0),
          child: _buildReportContent(context),
        ),
      ],
    );
  }

  Widget _buildReportContent(BuildContext context) {
    return SizedBox(
      height: 800,
      child: ReportDataTable(
        reportData: widget.reportData,
        selectedColumns: widget.selectedColumns.toList(),
        onDeleteSelected: widget.onDeleteSelected,
      ),
    );
  }
}

class ReportDataTable extends StatefulWidget {
  final List<Map<String, dynamic>> reportData;
  final List<String> selectedColumns;
  final Function(List<int>) onDeleteSelected;

  const ReportDataTable({
    required this.reportData,
    required this.selectedColumns,
    required this.onDeleteSelected,
    Key? key,
  }) : super(key: key);

  @override
  State<ReportDataTable> createState() => _ReportDataTableState();
}

class _ReportDataTableState extends State<ReportDataTable> {
  String? _sortColumn;
  bool _sortAscending = true;

  List<Map<String, dynamic>> get _sortedData {
    if (_sortColumn == null) return widget.reportData;

    final sorted = List<Map<String, dynamic>>.from(widget.reportData);
    sorted.sort((a, b) {
      final aValue = a[_sortColumn]?.toString() ?? '';
      final bValue = b[_sortColumn]?.toString() ?? '';

      return _sortAscending
          ? aValue.compareTo(bValue)
          : bValue.compareTo(aValue);
    });
    return sorted;
  }

  void _onSort(String columnName) {
    setState(() {
      if (_sortColumn == columnName) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = columnName;
        _sortAscending = true;
      }
    });
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
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: SizedBox(
              width: constraints.maxWidth > 1200 ? 1200 : constraints.maxWidth,
              child: _ReportTableWidget(
                key: ValueKey(
                    '${widget.selectedColumns.join(',')}-$_sortColumn-$_sortAscending'),
                reportData: _sortedData,
                selectedColumns: widget.selectedColumns,
                sortColumn: _sortColumn,
                sortAscending: _sortAscending,
                onSort: _onSort,
                onDeleteSelected: widget.onDeleteSelected,
              ),
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
        width: 1200,
        child: _ReportTableWidget(
          key: ValueKey(
              '${widget.selectedColumns.join(',')}-$_sortColumn-$_sortAscending'),
          reportData: _sortedData,
          selectedColumns: widget.selectedColumns,
          sortColumn: _sortColumn,
          sortAscending: _sortAscending,
          onSort: _onSort,
          onDeleteSelected: widget.onDeleteSelected,
        ),
      ),
    );
  }
}

class _ReportTableWidget extends TableWidget<ReportTableViewModel> {
  final List<Map<String, dynamic>> reportData;
  final List<String> selectedColumns;
  final String? sortColumn;
  final bool sortAscending;
  final Function(String) onSort;
  final Function(List<int>) onDeleteSelected;

  _ReportTableWidget({
    required this.reportData,
    required this.selectedColumns,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSort,
    required this.onDeleteSelected,
    Key? key,
  }) : super(key: key);

  @override
  bool get showCheckboxColumn => true;

  @override
  Widget toolsWidget(BuildContext context, ReportTableViewModel viewModel) {
    return Row(
      children: [
        ElevatedButton.icon(
          icon: const Icon(
            Icons.delete,
            size: 18,
            color: Colors.white,
          ),
          label: const Text('Delete Selected'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final selectedRows = getSelectedRowData();
            final selectedIndices = selectedRows
                .map((row) => int.tryParse(row.first.id ?? ''))
                .whereType<int>()
                .toList();
            if (selectedIndices.isNotEmpty) {
              onDeleteSelected(selectedIndices);
            }
          },
        ),
      ],
    );
  }

  @override
  ReportTableViewModel viewModelBuilder(BuildContext context) {
    return ReportTableViewModel(
      context,
      reportData,
      selectedColumns,
      sortColumn,
      sortAscending,
    );
  }

  @override
  bool get reloadOnUpdate => true;

  @override
  Widget headerBuilder(
      BuildContext context, String headerName, ReportTableViewModel viewModel) {
    return InkWell(
      onTap: () => onSort(headerName),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              headerName,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            sortColumn == headerName
                ? (sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                : Icons.unfold_more,
            size: 16,
            color: sortColumn == headerName
                ? Theme.of(context).primaryColor
                : Colors.grey,
          ),
        ],
      ),
    );
  }

  @override
  Widget actionWidgetsBuilder(
    BuildContext context,
    TableDataRowsTableDataRows columnData,
    ReportTableViewModel viewModel,
  ) {
    return const SizedBox.shrink();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _ReportTableWidget &&
        const ListEquality().equals(other.reportData, reportData) &&
        const ListEquality().equals(other.selectedColumns, selectedColumns) &&
        other.sortColumn == sortColumn &&
        other.sortAscending == sortAscending;
  }

  @override
  int get hashCode {
    return Object.hash(
      const ListEquality().hash(reportData),
      const ListEquality().hash(selectedColumns),
      sortColumn,
      sortAscending,
    );
  }
}

class ReportTableViewModel extends BaseTableProvider {
  final List<Map<String, dynamic>> reportData;
  final List<String> selectedColumns;
  final String? sortColumn;
  final bool sortAscending;

  ReportTableViewModel(
    super.context,
    this.reportData,
    this.selectedColumns,
    this.sortColumn,
    this.sortAscending,
  );

  @override
  Future loadData(BuildContext context) async {
    final headers = [...selectedColumns];

    List<List<TableDataRowsTableDataRows>> rows = [];

    for (var i = 0; i < reportData.length; i++) {
      final rowData = reportData[i];
      List<TableDataRowsTableDataRows> row = [];

      for (var column in selectedColumns) {
        var cell = TableDataRowsTableDataRows()
          ..text = rowData[column]?.toString() ?? '-'
          ..dataType = CellDataType.TEXT.type
          ..columnName = column
          ..id = i.toString();
        row.add(cell);
      }

      rows.add(row);
    }

    TableDataEntity tableData = TableDataEntity()
      ..headers = headers
      ..rows = rows;

    tableDataEntity = tableData;
  }
}
