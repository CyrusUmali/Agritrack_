import 'package:flareline/core/theme/global_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/core/models/yield_model.dart';
import 'package:flareline/pages/toast/toast_helper.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class ExportButtonWidget extends StatefulWidget {
  final List<Yield> yields; // This should be the filtered list from YieldBloc

  const ExportButtonWidget({
    super.key,
    required this.yields,
  });

  @override
  State<ExportButtonWidget> createState() => _ExportButtonWidgetState();
}

class _ExportButtonWidgetState extends State<ExportButtonWidget> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    // print(widget.yields);
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
        onPressed: widget.yields.isEmpty ? null : _exportData,
        tooltip: 'Export visible data to Excel',
      ),
    );
  }

  Future<void> _exportData() async {
    if (widget.yields.isEmpty) {
      ToastHelper.showErrorToast('No data to export', context);
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      await _generateExcelFile();
      // ToastHelper.showSuccessToast('Data exported successfully!', context);
    } catch (e) {
      ToastHelper.showErrorToast('Export failed: ${e.toString()}', context);
      debugPrint('Export error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _generateExcelFile() async {
    final excel = Excel.createExcel();
    final sheet = excel['Yield Data'];

    // Remove default sheet
    excel.delete('Sheet1');

    // Define styles
    final titleStyle = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Arial),
      fontSize: 16,
      fontColorHex: ExcelColor.fromHexString('#2E86AB'),
    );

    final headerStyle = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Arial),
      fontSize: 12,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.fromHexString('#2E86AB'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    // Create separate styles for different data types
    final textDataStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Arial),
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString('#333333'),
      horizontalAlign: HorizontalAlign.Left,
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

    final rightAlignDataStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Arial),
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString('#333333'),
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );

    // Create header
    int currentRow = 0;

    // Title
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
      ..value = TextCellValue('Yield Data Export')
      ..cellStyle = titleStyle;
    currentRow++;

    // Export info - merged for better visibility
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
      ..value = TextCellValue(
          'Exported: ${DateFormat('MMM d, yyyy HH:mm').format(DateTime.now())}')
      ..cellStyle = textDataStyle;
    sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow));
    currentRow++;

    // Total Records - merged
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
      ..value = TextCellValue('Total Records: ${widget.yields.length}')
      ..cellStyle = textDataStyle;
    sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow));
    currentRow += 2;

    // Column headers - now with combined Volume & Unit column
    final headers = [
      'Product Name',
      'Sector',
      'Barangay',
      'Area Harvested (ha)',
      'Volume', // Combined column
      'Status',
      'Harvest Date',
      'Date Reported',
      'Farmer Name',
      'Farm Name'
    ];

    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRow));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = headerStyle;
    }
    currentRow++;

    // Add data rows with proper alignment for each column
    for (final yieldData in widget.yields) {
      // Product Name - Column 1 (Left aligned)
      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
        ..value = TextCellValue(yieldData.productName ?? 'N/A')
        ..cellStyle = textDataStyle;

      // Sector - Column 2 (Center aligned)
      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow))
        ..value = TextCellValue(yieldData.sector ?? 'Unknown')
        ..cellStyle = centerDataStyle;

      // Barangay - Column 3 (Left aligned)
      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow))
        ..value = TextCellValue(yieldData.barangay ?? 'N/A')
        ..cellStyle = textDataStyle;

      // Area Harvested (ha) - Column 4 (Right aligned - number)
      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow))
        ..value = DoubleCellValue(yieldData.areaHarvested ?? 0)
        ..cellStyle = rightAlignDataStyle;

      // Volume with Unit - Column 5 (Center aligned - combined value)
      final volume = yieldData.volume ?? 0;
      final unit = _getUnit(yieldData.sectorId);
      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow))
        ..value = TextCellValue('$volume $unit')
        ..cellStyle = centerDataStyle;

      // Status - Column 6 (Center aligned)
      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow))
        ..value = TextCellValue(yieldData.status ?? 'N/A')
        ..cellStyle = centerDataStyle;

      // Harvest Date - Column 7 (Center aligned)
      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: currentRow))
        ..value = TextCellValue(_formatDate(yieldData.harvestDate))
        ..cellStyle = centerDataStyle;

      // Date Reported - Column 8 (Center aligned)
      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: currentRow))
        ..value = TextCellValue(_formatDate(yieldData.createdAt))
        ..cellStyle = centerDataStyle;

      // Farmer Name - Column 9 (Left aligned)
      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: currentRow))
        ..value = TextCellValue(yieldData.farmerName ?? 'N/A')
        ..cellStyle = textDataStyle;

      // Farm Name - Column 10 (Left aligned)
      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: currentRow))
        ..value = TextCellValue(yieldData.farmName ?? 'N/A')
        ..cellStyle = textDataStyle;

      currentRow++;
    }

    // Auto-size columns with optimized widths (updated for combined column)
    _autoSizeColumns(sheet, headers.length);

    excel.setDefaultSheet(sheet.sheetName);
    final bytes = excel.save();

    if (bytes == null) {
      throw Exception('Failed to generate Excel file');
    }

    await _saveExcelFile(bytes);
  }

  void _autoSizeColumns(Sheet sheet, int columnCount) {
    // Custom widths for each column based on content type (updated for combined column)
    final columnWidths = [
      8, // ID
      20, // Product Name
      12, // Sector
      15, // Barangay
      22, // Area Harvested (ha)
      18, // Volume with Unit (combined column - wider)
      10, // Status
      12, // Harvest Date
      12, // Date Reported
      18, // Farmer Name
      20, // Farm Name
    ];

    for (int colIndex = 0; colIndex < columnCount; colIndex++) {
      try {
        final width =
            colIndex < columnWidths.length ? columnWidths[colIndex] : 15;
        sheet.setColumnWidth(colIndex, width.toDouble());
      } catch (e) {
        debugPrint('Could not set column width: $e');
      }
    }
  }

  String _getUnit(int? sectorId) {
    print(sectorId);
    switch (sectorId) {
      case 1:
      case 2:
      case 3:
      case 5:
      case 6:
        return 'kg'; // Fisheries

      case 4:
        return 'heads'; // Poultry
      default:
        return 'units';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _saveExcelFile(List<int> bytes) async {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = 'yield_export_$timestamp.xlsx';

    if (kIsWeb) {
      // Web platform
      await FileSaver.instance.saveFile(
        name: filename,
        bytes: Uint8List.fromList(bytes),
        ext: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
    } else {
      // Mobile platforms
      await _saveFileMobile(Uint8List.fromList(bytes), filename, context);
    }
  }

  static Future<void> _saveFileMobile(
      Uint8List bytes, String filename, BuildContext context) async {
    try {
      if (Platform.isAndroid) {
        await _saveFileAndroid(bytes, filename, context);
      } else if (Platform.isIOS) {
        await _saveFileIOS(bytes, filename, context);
      } else {
        await FileSaver.instance.saveFile(
          name: filename,
          bytes: bytes,
          ext: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
        ToastHelper.showSuccessToast('File saved successfully', context);
      }
    } catch (e) {
      debugPrint('Mobile file save error: $e');
      _showSaveInstructions(context, filename);
    }
  }

  static Future<void> _saveFileAndroid(
      Uint8List bytes, String filename, BuildContext context) async {
    try {
      // Method 1: Try to save to actual Downloads folder
      try {
        // Request storage permission first
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          ToastHelper.showErrorToast(
            'Storage permission required to save to Downloads folder',
            context,
          );
          // Fall back to app directory
          await _saveToAppDirectory(bytes, filename, context);
          return;
        }

        // Try to get the actual Downloads directory
        Directory? downloadsDir = await _getActualDownloadsDirectory();

        if (downloadsDir != null) {
          final file = File('${downloadsDir.path}/$filename');
          await file.writeAsBytes(bytes);

          ToastHelper.showSuccessToast(
            'File saved to Downloads folder:\n$filename',
            context,
          );
          debugPrint('File saved to actual Downloads: ${file.path}');
          return;
        }
      } catch (e) {
        debugPrint('Method 1 (Actual Downloads) failed: $e');
      }

      // Method 2: Save to app's Download folder
      try {
        await _saveToAppDirectory(bytes, filename, context);
        return;
      } catch (e) {
        debugPrint('Method 2 failed: $e');
      }

      // Method 3: Use FileSaver as final fallback
      await FileSaver.instance.saveFile(
        name: filename,
        bytes: bytes,
        ext: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
      ToastHelper.showSuccessToast('File saved via system dialog', context);
    } catch (e) {
      debugPrint('All Android methods failed: $e');
      rethrow;
    }
  }

  static Future<Directory?> _getActualDownloadsDirectory() async {
    if (Platform.isAndroid) {
      // Method 1: Try using known paths for Downloads folder
      final knownPaths = [
        '/storage/emulated/0/Download',
        '/sdcard/Download',
        '/storage/sdcard0/Download',
      ];

      for (final path in knownPaths) {
        try {
          final dir = Directory(path);
          if (await dir.exists()) {
            return dir;
          }
        } catch (e) {
          debugPrint('Path $path not accessible: $e');
        }
      }

      // Method 2: Use environment variables
      try {
        final externalStorage = Platform.environment['EXTERNAL_STORAGE'];
        if (externalStorage != null) {
          final downloadsPath = '$externalStorage/Download';
          final dir = Directory(downloadsPath);
          if (await dir.exists()) {
            return dir;
          }
        }
      } catch (e) {
        debugPrint('Environment method failed: $e');
      }
    }

    return null;
  }

  static Future<void> _saveToAppDirectory(
      Uint8List bytes, String filename, BuildContext context) async {
    // This is your original method - saving to app's directory
    Directory? downloadsDir = await getExternalStorageDirectory();
    if (downloadsDir != null) {
      final downloadsPath = '${downloadsDir.path}/Download';
      final dir = Directory(downloadsPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);

      ToastHelper.showSuccessToast(
        'File saved to app storage:\n$filename\n\nUse a file manager to find it in Android/data/top.flareline.app/files/Download/',
        context,
      );
      debugPrint('File saved to app directory: ${file.path}');
    } else {
      throw Exception('Could not access app directory');
    }
  }

  static Future<void> _saveFileIOS(
      Uint8List bytes, String filename, BuildContext context) async {
    try {
      // For iOS, the Documents directory is accessible via Files app
      final appDocDir = await getApplicationDocumentsDirectory();
      final file = File('${appDocDir.path}/$filename');
      await file.writeAsBytes(bytes);

      ToastHelper.showSuccessToast(
        'File saved to Documents folder.\n\nUse the Files app to access it.',
        context,
      );
      debugPrint('File saved to: ${file.path}');
    } catch (e) {
      debugPrint('iOS file save error: $e');
      await FileSaver.instance.saveFile(
        name: filename,
        bytes: bytes,
        ext: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
      ToastHelper.showSuccessToast('File saved successfully', context);
    }
  }

  static void _showSaveInstructions(BuildContext context, String filename) {
    if (Platform.isAndroid) {
      ToastHelper.showInfoToast(
        'File ready: $filename\n\n'
        'Check your Downloads folder or use a file manager app to find the file.',
        context,
      );
    } else {
      ToastHelper.showInfoToast(
        'File ready: $filename\n\n'
        'Check your Documents folder in the Files app.',
        context,
      );
    }
  }
}
