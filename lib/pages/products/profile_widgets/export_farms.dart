import 'package:flareline/core/theme/global_colors.dart';
import 'package:flutter/material.dart';
import 'package:flareline/core/models/farms_model.dart';
import 'package:flareline/pages/toast/toast_helper.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class FarmsExportButtonWidget extends StatefulWidget {
  final List<Farm> farms;

  const FarmsExportButtonWidget({
    super.key,
    required this.farms,
  });

  @override
  State<FarmsExportButtonWidget> createState() =>
      _FarmsExportButtonWidgetState();
}

class _FarmsExportButtonWidgetState extends State<FarmsExportButtonWidget> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return _isExporting ? _buildLoadingIndicator() : _buildExportButton();
  }

  Widget _buildLoadingIndicator() {
    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        // border: Border.all(color: Colors.grey[300]!),
      ),
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildExportButton() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: GlobalColors.primary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.download, color: Colors.white, size: 20),
        onPressed: widget.farms.isEmpty ? null : _exportFarmsData,
        tooltip: 'Export farms data to Excel',
      ),
    );
  }

  Future<void> _exportFarmsData() async {
    if (widget.farms.isEmpty) {
      ToastHelper.showErrorToast('No farms data to export', context);
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      await _generateFarmsExcelFile();
      // ToastHelper.showSuccessToast(
      //     'Farms data exported successfully!', context);
    } catch (e) {
      ToastHelper.showErrorToast('Export failed: ${e.toString()}', context);
      debugPrint('Farms export error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _generateFarmsExcelFile() async {
    final excel = Excel.createExcel();
    final sheet = excel['Farms Data'];

    // Remove default sheet
    excel.delete('Sheet1');

    // Define styles
    final titleStyle = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Arial),
      fontSize: 16,
      fontColorHex: ExcelColor.fromHexString('#2E7D32'),
    );

    final headerStyle = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Arial),
      fontSize: 12,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.fromHexString('#2E7D32'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    // Create separate styles for different data types
    final textDataStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Arial),
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString('#333333'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final centerDataStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Arial),
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString('#333333'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final numberDataStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Arial),
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString('#333333'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    // Create header
    int currentRow = 0;

    // Title
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
      ..value = TextCellValue('Farms Data Export')
      ..cellStyle = titleStyle;
    currentRow++;

    // Export info
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
      ..value = TextCellValue(
          'Exported: ${DateFormat('MMM d, yyyy HH:mm').format(DateTime.now())}')
      ..cellStyle = textDataStyle;
    currentRow++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
      ..value = TextCellValue('Total Farms: ${widget.farms.length}')
      ..cellStyle = textDataStyle;
    currentRow += 2;

    // Column headers
    final headers = [
      'Farm ID',
      'Farm Name',
      'Owner Name',
      'Barangay',
      'Farm Size (ha)',
      'Total Volume (kg)',
      'Yield per Hectare (t/ha)',
      'Status',
    ];

    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRow));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = headerStyle;
    }
    currentRow++;

    // Add data rows with proper alignment for each column
    for (final farm in widget.farms) {
      final yieldPerHectare = _calculateYieldPerHectare(farm);

      // Farm ID - Column 0 (Center aligned)
      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
        ..value = IntCellValue(farm.id ?? 0)
        ..cellStyle = centerDataStyle;

      // Farm Name - Column 1 (Left aligned)
      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
        ..value = TextCellValue(farm.name ?? '-')
        ..cellStyle = textDataStyle;

      // Owner Name - Column 2 (Left aligned)
      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow))
        ..value = TextCellValue(farm.owner ?? '-')
        ..cellStyle = textDataStyle;

      // Barangay - Column 3 (Left aligned)
      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow))
        ..value = TextCellValue(farm.barangay ?? '-')
        ..cellStyle = textDataStyle;

      // Farm Size (ha) - Column 4 (Center aligned - number)
      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow))
        ..value = DoubleCellValue(farm.hectare ?? 0)
        ..cellStyle = numberDataStyle;

      // Total Volume (kg) - Column 5 (Center aligned - number)
      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow))
        ..value = IntCellValue(farm.volume ?? 0)
        ..cellStyle = numberDataStyle;

      // Yield per Hectare (t/ha) - Column 6 (Center aligned - number)
      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow))
        ..value = DoubleCellValue(yieldPerHectare)
        ..cellStyle = numberDataStyle;

      // Status - Column 7 (Center aligned)
      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: currentRow))
        ..value = TextCellValue('Active')
        ..cellStyle = centerDataStyle;

      currentRow++;
    }

    // Auto-size columns with better widths based on content type
    _autoSizeColumns(sheet, headers.length);

    excel.setDefaultSheet(sheet.sheetName);
    final bytes = excel.save();

    if (bytes == null) {
      throw Exception('Failed to generate Excel file');
    }

    await _saveExcelFile(bytes);
  }

  void _autoSizeColumns(Sheet sheet, int columnCount) {
    // Increased widths for all columns
    final columnWidths = [
      12, // Farm ID (increased from 8)
      25, // Farm Name (increased from 20)
      20, // Owner Name (increased from 15)
      20, // Barangay (increased from 15)
      15, // Farm Size (increased from 12)
      18, // Total Volume (increased from 15)
      22, // Yield per Hectare (increased from 18)
      15, // Status (increased from 10)
    ];

    for (int colIndex = 0; colIndex < columnCount; colIndex++) {
      try {
        final width =
            colIndex < columnWidths.length ? columnWidths[colIndex] : 20;
        sheet.setColumnWidth(colIndex, width.toDouble());
      } catch (e) {
        debugPrint('Could not set column width: $e');
      }
    }
  }

  double _calculateYieldPerHectare(Farm farm) {
    final volume = farm.volume ?? 0;
    final area = farm.hectare ?? 0;
    if (area == 0) return 0.0;
    return (volume / 1000) / area;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _saveExcelFile(List<int> bytes) async {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = 'farms_export_$timestamp.xlsx';

    if (kIsWeb) {
      await FileSaver.instance.saveFile(
        name: filename,
        bytes: Uint8List.fromList(bytes),
        ext: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
    } else {
      await _saveFileMobile(Uint8List.fromList(bytes), filename);
    }
  }

  Future<void> _saveFileMobile(Uint8List bytes, String filename) async {
    try {
      if (Platform.isAndroid) {
        await _saveToAndroidDownloads(bytes, filename);
      } else if (Platform.isIOS) {
        await _saveToIOSDocuments(bytes, filename);
      } else {
        await FileSaver.instance.saveFile(
          name: filename,
          bytes: bytes,
          ext: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
      }
    } catch (e) {
      debugPrint('Mobile save error: $e');
      await FileSaver.instance.saveFile(
        name: filename,
        bytes: bytes,
        ext: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
    }
  }

  Future<void> _saveToAndroidDownloads(Uint8List bytes, String filename) async {
    try {
      // Try direct Downloads folder path
      final possiblePaths = [
        '/storage/emulated/0/Download',
        '/sdcard/Download',
        '/storage/sdcard0/Download',
      ];

      for (final path in possiblePaths) {
        final dir = Directory(path);
        if (await dir.exists()) {
          final file = File('$path/$filename');
          await file.writeAsBytes(bytes);
          debugPrint('File saved to: ${file.path}');
          _showAndroidSaveSuccess(context, filename, file.path);
          return;
        }
      }

      // Fallback to app directory
      final appDir = await getApplicationDocumentsDirectory();
      final file = File('${appDir.path}/$filename');
      await file.writeAsBytes(bytes);
      _showAndroidSaveInstructions(context, filename, file.path);
    } catch (e) {
      debugPrint('Android save error: $e');
      rethrow;
    }
  }

  Future<void> _saveToIOSDocuments(Uint8List bytes, String filename) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final file = File('${appDocDir.path}/$filename');
      await file.writeAsBytes(bytes);
      ToastHelper.showSuccessToast(
        'File saved to Documents folder.\n\nUse the Files app to access it.',
        context,
      );
    } catch (e) {
      debugPrint('iOS file save error: $e');
      rethrow;
    }
  }

  void _showAndroidSaveSuccess(
      BuildContext context, String filename, String path) {
    final shortPath = path.split('/Download/').last;
    ToastHelper.showSuccessToast(
      'File saved to Downloads!\n$filename',
      context,
    );
  }

  void _showAndroidSaveInstructions(
      BuildContext context, String filename, String path) {
    ToastHelper.showInfoToast(
      'File saved to app folder.\n\n'
      'To access it:\n'
      '1. Open Files app\n'
      '2. Navigate to Internal storage\n'
      '3. Find "Android/data/top.flareline.app/files/"\n'
      '4. File: $filename',
      context,
    );
  }
}
