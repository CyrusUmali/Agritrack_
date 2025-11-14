// ignore_for_file: must_be_immutable, constant_identifier_names, non_constant_identifier_names, unnecessary_overrides

library flareline_uikit;

import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flareline_uikit/components/forms/switch_widget.dart';
import 'package:flareline_uikit/components/loading/loading.dart';
import 'package:flareline_uikit/components/tags/tag_widget.dart';
import 'package:flareline_uikit/core/event/global_event.dart';
import 'package:flareline_uikit/core/mvvm/base_viewmodel.dart';
import 'package:flareline_uikit/core/mvvm/base_widget.dart';
import 'package:flareline_uikit/entity/table_data_entity.dart';
import 'package:flutter/material.dart';

// ignore: unnecessary_import
import 'package:flutter/services.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:syncfusion_flutter_core/theme.dart';

enum CellDataType {
  TEXT('text'),
  TOGGLE('toggle'),
  TAG('tag'),
  IMAGE('image'),
  CUSTOM('custom'),
  ACTION('action'),
  IMAGE_TEXT('imageText'),
  ICON('icon'), // New type for icons
  ;

  const CellDataType(this.type);

  final String type;
}

abstract class TableWidget<S extends BaseTableProvider> extends BaseWidget<S> {
  TableWidget({super.params, super.key});
  final DataGridController dataGridController = DataGridController();

  List<DataGridRow> getSelectedRows() {
    return dataGridController.selectedRows;
  }

// If you want to get the underlying data (TableDataRowsTableDataRows) of the selected rows:
  List<List<TableDataRowsTableDataRows>> getSelectedRowData() {
    return dataGridController.selectedRows.map((dataGridRow) {
      return dataGridRow
          .getCells()
          .map((cell) => cell.value as TableDataRowsTableDataRows)
          .toList();
    }).toList();
  }

// Add this to your TableWidget class
  void onSelectionChanged() {
    // This will be called whenever selection changes
    final selectedRows = getSelectedRows();
    // Do something with the selected rows
  }

  // Remove the @override annotation
  Widget buildCell(BuildContext context, TableDataRowsTableDataRows cell) {
    if (cell.dataType == CellDataType.IMAGE_TEXT.type) {
      return _buildImageTextCell(cell);
    }
    // Default cell implementation
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Text(cell.text ?? ''),
    );
  }

  Widget _buildImageTextCell(TableDataRowsTableDataRows columnData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Row(
        children: [
          if (columnData.imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: CircleAvatar(
                radius: 20, // Matches your 40x40 dimensions
                backgroundImage: NetworkImage(columnData.imageUrl!),
                onBackgroundImageError: (exception, stackTrace) {
                  // Error handling
                },
                child: const Icon(Icons.image, size: 20),
              ),
            ),
          Expanded(
            child: Text(
              columnData.text ?? '',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Add this method to customize header widgets
  Widget headerBuilder(BuildContext context, String headerName, S viewModel) {
    return Text(headerName); // Default implementation
  }

  // Add new callback for handling cell taps
  void onCellTap(BuildContext context, TableDataRowsTableDataRows columnData,
      S viewModel) {}

  // Add new method for building CRUD action widgets
  Widget buildCrudActions(BuildContext context,
      TableDataRowsTableDataRows columnData, S viewModel) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.visibility, size: 20),
          onPressed: () => onViewAction(context, columnData, viewModel),
          tooltip: 'View',
        ),
        IconButton(
          icon: const Icon(Icons.edit, size: 20),
          onPressed: () => onEditAction(context, columnData, viewModel),
          tooltip: 'Edit',
        ),
        IconButton(
          icon: const Icon(Icons.delete, size: 20),
          onPressed: () => onDeleteAction(context, columnData, viewModel),
          tooltip: 'Delete',
        ),
      ],
    );
  }

  // Add callback methods for CRUD operations
  void onViewAction(BuildContext context, TableDataRowsTableDataRows columnData,
      S viewModel) {}
  void onEditAction(BuildContext context, TableDataRowsTableDataRows columnData,
      S viewModel) {}
  void onDeleteAction(BuildContext context,
      TableDataRowsTableDataRows columnData, S viewModel) {}

  /// title
  String? title(BuildContext context) {
    return null;
  }

  ///tools widget
  Widget? toolsWidget(BuildContext context, S viewModel) {
    return null;
  }

  ///action column width
  double get actionColumnWidth => 200;

  //paging
  bool get showPaging => true;

  ///actions widget
  Widget? actionWidgetsBuilder(BuildContext context,
      TableDataRowsTableDataRows columnData, S viewModel) {
    return null;
  }

  ///custom widget
  Widget? customWidgetsBuilder(BuildContext context,
      TableDataRowsTableDataRows columnData, S viewModel) {
    return null;
  }

  ///toggle changed event
  onToggleChanged(BuildContext context, bool checked,
      TableDataRowsTableDataRows columnData) {}

  _buildWidget(BuildContext context, S viewModel) {
    bool isLoading = viewModel.isLoading;
    TableDataEntity? tableDataEntity = viewModel.tableDataEntity;
    List<dynamic> headers = tableDataEntity?.headers ?? [];
    if (isLoading || tableDataEntity == null || headers.isEmpty) {
      return const LoadingWidget();
    }

    List<List<TableDataRowsTableDataRows>> rows = tableDataEntity.rows ?? [];
    return ConstrainedBox(
        constraints: const BoxConstraints(minWidth: double.infinity),
        child: _sfDataGrid(context, headers, rows, viewModel));
  }

  // Update baseDataGridSource to include the onCellTap parameter
  BaseDataGridSource baseDataGridSource(
      BuildContext context,
      List<List<TableDataRowsTableDataRows>> rows,
      viewModel,
      Widget? Function(
              BuildContext context, TableDataRowsTableDataRows columnData)
          actionWidgetsBuilder,
      customWidgetsBuilder,
      Function(BuildContext context, bool checked,
              TableDataRowsTableDataRows columnData)
          onToggleChanged) {
    return BaseDataGridSource(
      context,
      rows,
      viewModel,
      actionWidgetsBuilder,
      customWidgetsBuilder,
      onToggleChanged,
      viewModel.pageSize,
      onCellTap: (columnData) => onCellTap(context, columnData, viewModel),
    );
  }

  bool get isLastColumnFixed => false;

  bool get showCheckboxColumn => false;

  bool get highlightRowOnHover => false;

  double get rowHeight => double.nan;

  ColumnWidthMode get columnWidthMode => ColumnWidthMode.fill;

  Widget _sfDataGrid(BuildContext context, List<dynamic> headers,
      List<List<TableDataRowsTableDataRows>> rows, viewModel) {
    BaseDataGridSource dataGridSource = baseDataGridSource(
      context,
      rows,
      viewModel,
      (BuildContext context, TableDataRowsTableDataRows columnData) {
        return actionWidgetsBuilder(context, columnData, viewModel) ??
            const SizedBox.shrink();
      },
      (BuildContext context, TableDataRowsTableDataRows columnData) {
        return customWidgetsBuilder(context, columnData, viewModel) ??
            const SizedBox.shrink();
      },
      (BuildContext context, bool checked,
          TableDataRowsTableDataRows columnData) {
        onToggleChanged(context, checked, columnData);
      },
    );
    int pageCount = rows.length % viewModel.pageSize == 0
        ? rows.length ~/ viewModel.pageSize
        : rows.length ~/ viewModel.pageSize + 1;

    return Column(
      children: [
        Expanded(
            child: ScreenTypeLayout.builder(
          desktop: (context) => responsiveWidget(
              dataGridSource, headers, false, context, viewModel),
          mobile: (context) => responsiveWidget(
              dataGridSource, headers, true, context, viewModel),
          tablet: (context) => responsiveWidget(
              dataGridSource, headers, true, context, viewModel),
        )),
        if (showPaging && rows.isNotEmpty)
          SizedBox(
            height: 60,
            child: SfDataPagerTheme(
              data: SfDataPagerThemeData(
                // selectedItemColor:
                //     Colors.blue, // Background color of active page
                selectedItemTextStyle: TextStyle(
                  color: Colors.black, // Text color of active page number
                  // fontWeight: FontWeight.bold,
                ),
                // itemTextStyle: TextStyle(
                //   color: Colors.black, // Text color of inactive page numbers
                // ),
              ),
              child: SfDataPager(
                delegate: dataGridSource,
                pageCount: pageCount.toDouble(),
                direction: Axis.horizontal,
              ),
            ),
          )
      ],
    );
  }

  Widget responsiveWidget(
    BaseDataGridSource dataGridSource,
    List<dynamic> headers,
    bool isMobile,
    BuildContext context,
    S viewModel,
  ) {
    return SfDataGrid(
      controller: dataGridController,
      source: dataGridSource,
      rowHeight: rowHeight,
      highlightRowOnHover: highlightRowOnHover,
      showCheckboxColumn: showCheckboxColumn,
      gridLinesVisibility: GridLinesVisibility.horizontal,
      selectionMode: SelectionMode.multiple,
      checkboxColumnSettings: const DataGridCheckboxColumnSettings(width: 80),
      footerFrozenColumnsCount: isLastColumnFixed ? 1 : 0,
      isScrollbarAlwaysShown: true,
      columnWidthMode: columnWidthMode,
      onSelectionChanged:
          (List<DataGridRow> addedRows, List<DataGridRow> removedRows) {
        onSelectionChanged();
      },
      columns: headers
          .map((e) => gridColumnWidget(
                e,
                isMobile,
                context,
                viewModel,
              ))
          .toList(),
    );
  }

  double gridColumnWidgetWidth(String e) {
    if (e == 'Action') {
      return actionColumnWidth;
    }
    return double.nan;
  }

  bool isColumnVisible(String columnName, bool isMobile) {
    return true;
  }

  /// Update the method signature to include context and viewModel
  GridColumn gridColumnWidget(
    dynamic e,
    bool isMobile,
    BuildContext context, // Add context parameter
    S viewModel, // Add viewModel parameter
  ) {
    String columnName;
    String? align;
    if (e is String) {
      columnName = e;
    } else {
      columnName = e['columnName'] ?? '';
      align = e['align'];
    }

    return GridColumn(
      width: gridColumnWidgetWidth(columnName),
      columnName: columnName,
      visible: isColumnVisible(columnName, isMobile),
      label: Container(
        alignment: 'center' == align
            ? Alignment.center
            : ('right' == align ? Alignment.centerRight : Alignment.centerLeft),
        child: headerBuilder(context, columnName, viewModel),
      ),
    );
  }

  @override
  Widget bodyWidget(BuildContext context, S viewModel, Widget? child) {
    String? titleText = title(context);
    Widget? tools = toolsWidget(context, viewModel);
    return CommonCard(
        child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (titleText != null)
            Text(
              titleText,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          if (titleText != null)
            const SizedBox(
              height: 16,
            ),
          if (tools != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: tools,
            ),
          Expanded(child: _buildWidget(context, viewModel)),
        ],
      ),
    ));
  }

  refresh(BuildContext context) {}
}

class BaseDataGridSource<F extends BaseTableProvider> extends DataGridSource {
  late BuildContext context;
  // Add onCellTap callback
  final Function(TableDataRowsTableDataRows columnData)? onCellTap;

  final Widget? Function(
          BuildContext context, TableDataRowsTableDataRows columnData)
      actionWidgetsBuilder;

  final Widget? Function(
          BuildContext context, TableDataRowsTableDataRows columnData)
      customWidgetsBuilder;

  final Function(BuildContext context, bool checked,
      TableDataRowsTableDataRows columnData) onToggleChanged;

  late int pageSize;

  late List<List<TableDataRowsTableDataRows>> list;

  BaseDataGridSource(
      this.context,
      this.list,
      F viewModel,
      this.actionWidgetsBuilder,
      this.customWidgetsBuilder,
      this.onToggleChanged,
      this.pageSize,
      {this.onCellTap}) {
    _loadPageData(0, pageSize);
  }

  void _loadPageData(int startIndex, int endIndex) {
    if (endIndex >= list.length) {
      endIndex = list.length;
    }
    if (list.isNotEmpty) {
      _data = list
          .getRange(startIndex, endIndex)
          .toList(growable: false)
          .map<DataGridRow>((e) => DataGridRow(
              cells: e
                  .map<DataGridCell>((item) =>
                      DataGridCell<TableDataRowsTableDataRows>(
                          columnName: item.columnName ?? '', value: item))
                  .toList()))
          .toList();
    } else {
      _data = [];
    }
  }

  List<DataGridRow> _data = [];

  @override
  List<DataGridRow> get rows => _data;

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    return DataGridRowAdapter(
        cells: row.getCells().map<Widget>((dataGridCell) {
      if (dataGridCell.value is TableDataRowsTableDataRows) {
        String? align = dataGridCell.value.align;
        return Container(
          alignment: 'center' == align
              ? Alignment.center
              : ('right' == align
                  ? Alignment.centerRight
                  : Alignment.centerLeft),
          child: cellWidget(dataGridCell.value),
        );
      }
      return const SizedBox.shrink();
    }).toList());
  }



  @override
  Future<bool> handlePageChange(int oldPageIndex, int newPageIndex) async {
    int startIndex = newPageIndex * pageSize;
    int endIndex = startIndex + pageSize;

    if (startIndex < list.length) {
      _loadPageData(startIndex, endIndex);
      notifyListeners();
    } else {
      _data = [];
    }
    return true;
  }

Widget cellWidget(TableDataRowsTableDataRows columnData) {
  // Wrap with GestureDetector to handle taps if onCellTap is provided
  Widget contentWidget;

  if (columnData.dataType == CellDataType.IMAGE_TEXT.type) {
    contentWidget = _imageTextCellWidget(columnData); // Don't return early
  } else if (CellDataType.TOGGLE.type == columnData.dataType) {
    return SwitchWidget(
        checked: '1' == columnData.text,
        onChanged: (checked) async {
          onToggleChanged(context, checked, columnData);
        });
  } else if (CellDataType.TAG.type == columnData.dataType) {
    return TagWidget(
      text: columnData.text ?? '',
      tagType: TagType.getTagType(columnData.tagType),
    );
  } else if (CellDataType.ACTION.type == columnData.dataType) {
    return actionWidgetsBuilder(context, columnData)!;
  } else if (CellDataType.IMAGE.type == columnData.dataType) {
    contentWidget = _imageCellWidget(columnData); // Don't return early
  } else if (CellDataType.CUSTOM.type == columnData.dataType) {
    return customWidgetsBuilder(context, columnData)!;
  } else if (CellDataType.ICON.type == columnData.dataType) {
    contentWidget = _iconCellWidget(columnData); // Don't return early
  } else {
    String text = columnData.text ?? '';
    if (text.length > 50) {
      text = '${text.substring(0, 50)}...';
    }
    contentWidget = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Text(text),
    );
  }

  // Apply GestureDetector to ALL content widgets (including IMAGE_TEXT, IMAGE, ICON, and TEXT)
  return onCellTap != null
      ? GestureDetector(
          onTap: () => onCellTap!(columnData),
          child: contentWidget,
        )
      : contentWidget;
}

  Widget _imageTextCellWidget(TableDataRowsTableDataRows columnData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Row(
        children: [
          if (columnData.imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(columnData.imageUrl!),
                onBackgroundImageError: (exception, stackTrace) {
                  // Error handling
                },
                // child: const Icon(Icons.image, size: 20),
              ),
            ),
          Expanded(
            child: Text(
              columnData.text ?? '',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Add a new method to handle icon cells
  Widget _iconCellWidget(TableDataRowsTableDataRows columnData) {
    // Extract the icon data from columnData
    IconData? iconData = columnData.iconData;
    Color? iconColor = columnData.iconColor;

    return Icon(
      iconData ?? Icons.help_outline, // Default icon if none specified
      color: iconColor,
      size: 20,
    );
  }

  Widget _imageCellWidget(TableDataRowsTableDataRows columnData) {
    return SizedBox(
      width: 40,
      height: 40,
      child: (columnData.text != null && columnData.text != ''
          ? CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(columnData.text!),
              onBackgroundImageError: (exception, stackTrace) {
                // Error handling
              },
              // child: const Icon(Icons.image, size: 20),
            )
          : const SizedBox.shrink()),
    );
  }
}

abstract class BaseTableProvider extends BaseViewModel {
  BaseTableProvider(super.context);

  TableDataEntity? _tableDataEntity;

  TableDataEntity? get tableDataEntity => _tableDataEntity;

  bool isLoading = false;

  int _pageSize = 10;

  //per pageSize
  int get pageSize => _pageSize;

  set pageSize(int size) {
    _pageSize = size;
    notifyListeners();
  }

  String get TAG => runtimeType.toString();

  set tableDataEntity(TableDataEntity? tableDataEntity) {
    _tableDataEntity = tableDataEntity;
    notifyListeners();
  }

  @override
  bool get isRegisterEventBus => true;

  @override
  void init(BuildContext context) {
    super.init(context);
  }

  @override
  void onViewCreated(BuildContext context) {
    loadData(context);
    super.onViewCreated(context);
  }

  @override
  void handleEventBus(BuildContext context, EventInfo eventInfo) {
    super.handleEventBus(context, eventInfo);
    if ('refresh_$TAG' == eventInfo.eventType) {
      loadData(context);
    }
  }

  Future loadData(BuildContext context);

  Map<String, dynamic> getItemValue(String key, Map item, {String? dataType}) {
    dynamic value = item[key];
    String text = value != null ? (value.toString()) : '';

    Map<String, dynamic> column = {
      'text': text,
      'key': key,
      'dataType': dataType,
      'columnName': key,
      'id': item['id'],
    };
    return column;
  }
}
