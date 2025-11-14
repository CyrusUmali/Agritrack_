import 'package:file_saver/file_saver.dart';
import 'package:flareline/core/models/yield_model.dart';
import 'package:flareline/pages/toast/toast_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class YieldExportUtils {
  static Future<void> exportYieldDataToExcel({
    required BuildContext context,
    required List<Yield> yields,
    required String polygonName,
    required String selectedProduct,
    required bool isMonthlyView,
    required int selectedYear,
    required Function(String) showLoadingDialog,
    required Function() closeLoadingDialog,
  }) async {
    if (yields.isEmpty) {
      ToastHelper.showErrorToast('No data to export', context);
      return;
    }

    try {
      showLoadingDialog('...');

      final excel = Excel.createExcel();
      final sheet = excel['Yield Report - $polygonName'];

      // Remove default sheet
      excel.delete('Sheet1');

      // Define styles
      final titleStyle = CellStyle(
        bold: true,
        fontFamily: getFontFamily(FontFamily.Arial),
        fontSize: 16,
        fontColorHex: ExcelColor.fromHexString('#3f51b5'),
      );

      final subtitleStyle = CellStyle(
        bold: true,
        fontFamily: getFontFamily(FontFamily.Arial),
        fontSize: 11,
        fontColorHex: ExcelColor.fromHexString('#333333'),
      );

      final headerStyle = CellStyle(
        bold: true,
        fontFamily: getFontFamily(FontFamily.Arial),
        fontSize: 10,
        fontColorHex: ExcelColor.white,
        backgroundColorHex: ExcelColor.fromHexString('#3f51b5'),
        horizontalAlign: HorizontalAlign.Center,
      );

      final dataStyle = CellStyle(
        fontFamily: getFontFamily(FontFamily.Arial),
        fontSize: 9,
        fontColorHex: ExcelColor.fromHexString('#333333'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      // Create report header
      int currentRow = 0;

      // Main title
      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
        ..value = TextCellValue('Yield Report - $polygonName')
        ..cellStyle = titleStyle;
      currentRow++;

      // Product and time period
      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
        ..value = TextCellValue('Product: $selectedProduct')
        ..cellStyle = subtitleStyle;
      currentRow++;

      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
        ..value = TextCellValue(
            'Period: ${isMonthlyView ? 'Monthly' : 'Yearly'} ${isMonthlyView ? selectedYear.toString() : ''}')
        ..cellStyle = subtitleStyle;
      currentRow++;

      // Generation date
      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
        ..value = TextCellValue(
            'Generated: ${DateFormat('MMM d, yyyy HH:mm').format(DateTime.now())}')
        ..cellStyle = subtitleStyle;
      currentRow += 2;

      // Prepare data based on view type
      final Map<String, Map<String, double>> data;
      final List<String> headers;

      if (isMonthlyView) {
        data = _prepareMonthlyData(yields, selectedProduct, selectedYear);
        headers = ['Month', 'Volume (kg)', 'Area Harvested (ha)'];
      } else {
        data = _prepareYearlyData(yields, selectedProduct);
        headers = ['Year', 'Volume (kg)', 'Area Harvested (ha)'];
      }

      // Add column headers
      for (int col = 0; col < headers.length; col++) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRow));
        cell.value = TextCellValue(headers[col]);
        cell.cellStyle = headerStyle;
      }
      currentRow++;

      // Add data rows
      data.forEach((period, values) {
        sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
          ..value = TextCellValue(period)
          ..cellStyle = dataStyle;

        sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
          ..value = DoubleCellValue(values['volume'] ?? 0)
          ..cellStyle = CellStyle(
            fontFamily: getFontFamily(FontFamily.Arial),
            fontSize: 9,
            fontColorHex: ExcelColor.fromHexString('#333333'),
            horizontalAlign: HorizontalAlign.Center,
          );

        sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow))
          ..value = DoubleCellValue(values['areaHarvested'] ?? 0)
          ..cellStyle = CellStyle(
            fontFamily: getFontFamily(FontFamily.Arial),
            fontSize: 9,
            fontColorHex: ExcelColor.fromHexString('#333333'),
            horizontalAlign: HorizontalAlign.Center,
          );

        currentRow++;
      });

      // Auto-size columns
      _autoSizeColumns(sheet, headers);

      excel.setDefaultSheet(sheet.sheetName);
      final bytes = excel.save();
      closeLoadingDialog();

      if (bytes == null) {
        throw Exception('Failed to generate Excel file');
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'yield_report_${polygonName}_$timestamp.xlsx'
          .replaceAll(' ', '_')
          .toLowerCase();

      // Handle file saving based on platform
      if (kIsWeb) {
        // Web platform
        await FileSaver.instance.saveFile(
          name: filename,
          bytes: Uint8List.fromList(bytes),
          ext: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
        ToastHelper.showSuccessToast(
            'Excel file downloaded successfully', context);
      } else {
        // Mobile platform - use a unified approach
        // await _saveFileMobile(bytes, filename, context);
        await _saveFileMobile(
            Uint8List.fromList(bytes), filename, 'excel', context);
        //  await _saveFileMobile(bytes, filename, 'pdf', context);
      }
    } catch (e) {
      closeLoadingDialog();
      ToastHelper.showErrorToast(
          'Error exporting Excel: ${e.toString()}', context);
      debugPrint('Excel Export Error: $e');
    }
  }

  static Future<void> exportYieldDataToPDF({
    required BuildContext context,
    required List<Yield> yields,
    required String polygonName,
    required String selectedProduct,
    required bool isMonthlyView,
    required int selectedYear,
    required Function(String) showLoadingDialog,
    required Function() closeLoadingDialog,
  }) async {
    if (yields.isEmpty) {
      ToastHelper.showErrorToast('No data to export', context);
      return;
    }

    try {
      showLoadingDialog('...');

      // Load the image as Uint8List before creating PDF
      final ByteData imageData = await rootBundle.load('assets/DA_image.jpg');
      final Uint8List uint8Image = imageData.buffer.asUint8List();

      // Create PDF document with metadata
      final pdf = pw.Document(
        title: 'Yield Report - $polygonName',
        author: 'Agritrack',
        creator: 'Flutter PDF Export',
        subject:
            'Yield Report for $selectedProduct - ${DateFormat('MMM yyyy').format(DateTime.now())}',
      );

      // Prepare data based on view type
      final Map<String, Map<String, double>> data;
      final List<String> headers;

      if (isMonthlyView) {
        data = _prepareMonthlyData(yields, selectedProduct, selectedYear);
        headers = ['Month', 'Volume (kg)', 'Area Harvested (ha)'];
      } else {
        data = _prepareYearlyData(yields, selectedProduct);
        headers = ['Year', 'Volume (kg)', 'Area Harvested (ha)'];
      }

      // Convert data to table format
      final tableData = _convertToTableData(data, isMonthlyView);

      // Calculate optimal page layout
      final pageFormat = _determineOptimalPageFormat(headers.length);
      final maxRowsPerPage = _calculateMaxRowsPerPage(pageFormat);

      // Split data into pages if necessary
      for (int pageIndex = 0;
          pageIndex < (tableData.length / maxRowsPerPage).ceil();
          pageIndex++) {
        final startIndex = pageIndex * maxRowsPerPage;
        final endIndex =
            (startIndex + maxRowsPerPage).clamp(0, tableData.length);
        final pageData = tableData.sublist(startIndex, endIndex);

        pdf.addPage(
          pw.Page(
            pageFormat: pageFormat,
            margin: const pw.EdgeInsets.all(20),
            build: (pw.Context context) => _buildYieldPDFPageContent(
              headers,
              pageData,
              pageIndex + 1,
              (tableData.length / maxRowsPerPage).ceil(),
              startIndex,
              uint8Image,
              polygonName,
              selectedProduct,
              isMonthlyView,
              selectedYear,
              tableData.length,
            ),
          ),
        );
      }

      final bytes = await pdf.save();
      closeLoadingDialog();

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'yield_report_${polygonName}_$timestamp.pdf'
          .replaceAll(' ', '_')
          .toLowerCase();

      // Handle file saving based on platform
      if (kIsWeb) {
        await FileSaver.instance.saveFile(
          name: filename,
          bytes: bytes,
          ext: 'pdf',
          mimeType: MimeType.pdf,
        );
        ToastHelper.showSuccessToast(
            'PDF file downloaded successfully', context);
      } else {
        await _saveFileMobile(bytes, filename, 'pdf', context);
      }
    } catch (e) {
      closeLoadingDialog();
      ToastHelper.showErrorToast(
          'Error exporting PDF: ${e.toString()}', context);
      debugPrint('PDF Export Error: $e');
    }
  }

  // Convert yield data to table format for PDF
  static List<List<String>> _convertToTableData(
      Map<String, Map<String, double>> data, bool isMonthlyView) {
    final List<List<String>> tableData = [];

    data.forEach((period, values) {
      tableData.add([
        period,
        _formatNumber(values['volume'] ?? 0),
        _formatNumber(values['areaHarvested'] ?? 0),
      ]);
    });

    // Sort data chronologically
    if (isMonthlyView) {
      tableData.sort((a, b) {
        final monthNames = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December'
        ];
        return monthNames.indexOf(a[0]).compareTo(monthNames.indexOf(b[0]));
      });
    } else {
      tableData.sort((a, b) => int.parse(a[0]).compareTo(int.parse(b[0])));
    }

    return tableData;
  }

  // Format numbers with proper decimal places
  static String _formatNumber(double value) {
    if (value == 0) return '0';
    if (value < 1) return value.toStringAsFixed(3);
    if (value < 10) return value.toStringAsFixed(2);
    if (value < 100) return value.toStringAsFixed(1);
    return value.toStringAsFixed(0);
  }

  // Determine optimal page format based on number of columns
  static PdfPageFormat _determineOptimalPageFormat(int columnCount) {
    if (columnCount > 6) {
      return PdfPageFormat.a3.landscape;
    } else if (columnCount > 4) {
      return PdfPageFormat.a4.landscape;
    } else {
      return PdfPageFormat.a4;
    }
  }

  // Calculate maximum rows per page based on format
  static int _calculateMaxRowsPerPage(PdfPageFormat format) {
    const double headerHeight = 150;
    const double footerHeight = 30;
    const double rowHeight = 20;

    final availableHeight = format.height -
        format.marginTop -
        format.marginBottom -
        headerHeight -
        footerHeight;
    return (availableHeight / rowHeight).floor();
  }

  // Build PDF page content for yield data
  static pw.Widget _buildYieldPDFPageContent(
    List<String> headers,
    List<List<String>> data,
    int currentPage,
    int totalPages,
    int startRowIndex,
    Uint8List imageBytes,
    String polygonName,
    String selectedProduct,
    bool isMonthlyView,
    int selectedYear,
    int totalRecords,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header section with image
        _buildYieldPDFHeader(imageBytes, polygonName, selectedProduct,
            isMonthlyView, selectedYear),
        pw.SizedBox(height: 20),

        // Data summary section
        _buildYieldDataSummary(startRowIndex, data.length, totalRecords),
        pw.SizedBox(height: 15),

        // Main data table
        pw.Expanded(child: _buildYieldEnhancedTable(headers, data)),

        // Footer with page numbers
        pw.SizedBox(height: 10),
        _buildPDFFooter(currentPage, totalPages),
      ],
    );
  }

  // Build PDF header for yield report
  static pw.Widget _buildYieldPDFHeader(
    Uint8List imageBytes,
    String polygonName,
    String selectedProduct,
    bool isMonthlyView,
    int selectedYear,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColor.fromHex('#3f51b5'), width: 2),
        ),
      ),
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // Left side: Logo image
          pw.SizedBox(
            width: 80,
            height: 80,
            child: pw.Image(
              pw.MemoryImage(imageBytes),
              fit: pw.BoxFit.contain,
            ),
          ),
          pw.SizedBox(width: 15),

          // Middle: Report title and details
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Yield Report - $polygonName',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    // color: PdfColor.fromHex('#3f51b5'),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Product: $selectedProduct',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Period: ${isMonthlyView ? 'Monthly' : 'Yearly'} ${isMonthlyView ? selectedYear.toString() : ''}',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),

          // Right side: Generated date
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Generated: ${DateFormat('MMM d, yyyy HH:mm').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Data summary section for yield report
  static pw.Widget _buildYieldDataSummary(
      int startIndex, int pageRows, int totalRecords) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#f5f5f5'),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        'Showing records ${startIndex + 1} - ${startIndex + pageRows} of $totalRecords total records',
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  // Enhanced table with better styling for yield data
  static pw.Widget _buildYieldEnhancedTable(
      List<String> headers, List<List<String>> data) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: _calculateYieldColumnWidths(headers),
      children: [
        // Enhanced header row
        pw.TableRow(
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [
                PdfColor.fromHex('#3f51b5'),
                PdfColor.fromHex('#303f9f')
              ],
            ),
          ),
          children: headers.map((header) {
            return pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              alignment: pw.Alignment.center,
              child: pw.Text(
                header.toUpperCase(),
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                ),
                textAlign: pw.TextAlign.center,
              ),
            );
          }).toList(),
        ),

        // Data rows with alternating colors
        ...data.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color:
                  index.isEven ? PdfColors.white : PdfColor.fromHex('#fafafa'),
            ),
            children: row.asMap().entries.map((cellEntry) {
              final cellIndex = cellEntry.key;
              final cell = cellEntry.value;

              return pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  cell,
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: cellIndex == 0
                        ? pw.FontWeight.bold
                        : pw.FontWeight.normal,
                  ),
                  textAlign: _getYieldCellAlignment(cellIndex, cell),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ],
    );
  }

  // Smart cell alignment for yield data
  static pw.TextAlign _getYieldCellAlignment(int cellIndex, String cell) {
    if (cellIndex == 0) {
      return pw.TextAlign.left; // Period (Month/Year) aligned left
    } else {
      return pw.TextAlign.right; // Numerical data aligned right
    }
  }

  // Calculate optimal column widths for yield data
  static Map<int, pw.TableColumnWidth> _calculateYieldColumnWidths(
      List<String> headers) {
    final Map<int, pw.TableColumnWidth> widths = {};

    for (int i = 0; i < headers.length; i++) {
      if (i == 0) {
        widths[i] = const pw.FlexColumnWidth(1.5); // Wider for period column
      } else {
        widths[i] = const pw.FlexColumnWidth(1.0); // Equal for data columns
      }
    }

    return widths;
  }

  // PDF footer with page information
  static pw.Widget _buildPDFFooter(int currentPage, int totalPages) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Agritrack Yield Report',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          ),
          pw.Text(
            'Page $currentPage of $totalPages',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ... keep the existing _prepareMonthlyData, _prepareYearlyData, and _autoSizeColumns methods
  static Map<String, Map<String, double>> _prepareMonthlyData(
      List<Yield> yields, String product, int year) {
    final monthlyData = <String, Map<String, double>>{};
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    // Initialize all months
    for (final month in monthNames) {
      monthlyData[month] = {'volume': 0.0, 'areaHarvested': 0.0};
    }

    final relevantYields = yields.where((yield) {
      final yieldYear = yield.harvestDate?.year ?? DateTime.now().year;
      return yield.productName == product && yieldYear == year;
    });

    for (final yield in relevantYields) {
      final month = yield.harvestDate?.month ?? 1;
      final monthName = monthNames[month - 1];

      monthlyData[monthName]!['volume'] =
          (monthlyData[monthName]!['volume'] ?? 0) + (yield.volume ?? 0);

      if (yield.sectorId != 4) {
        // Exclude livestock
        monthlyData[monthName]!['areaHarvested'] =
            (monthlyData[monthName]!['areaHarvested'] ?? 0) +
                (yield.areaHarvested ?? 0);
      }
    }

    return monthlyData;
  }

  static Map<String, Map<String, double>> _prepareYearlyData(
      List<Yield> yields, String product) {
    final yearlyData = <String, Map<String, double>>{};
    final yearGroups = <int, List<Yield>>{};

    for (final yield in yields.where((y) => y.productName == product)) {
      final year = yield.harvestDate?.year ?? DateTime.now().year;
      yearGroups.putIfAbsent(year, () => []).add(yield);
    }

    for (final entry in yearGroups.entries) {
      final totalVolume = entry.value
          .fold<double>(0, (sum, yield) => sum + (yield.volume ?? 0));
      final totalAreaHarvested = entry.value
          .where((yield) => yield.sectorId != 4)
          .fold<double>(0, (sum, yield) => sum + (yield.areaHarvested ?? 0));

      yearlyData[entry.key.toString()] = {
        'volume': totalVolume,
        'areaHarvested': totalAreaHarvested,
      };
    }

    return yearlyData;
  }

  static void _autoSizeColumns(Sheet sheet, List<String> headers) {
    for (int colIndex = 0; colIndex < headers.length; colIndex++) {
      double maxWidth = headers[colIndex].length * 4.0;
      maxWidth = maxWidth.clamp(8, 35);

      try {
        sheet.setColumnWidth(colIndex, maxWidth);
      } catch (e) {
        debugPrint('Could not set column width: $e');
      }
    }
  }

  // Updated save file method to handle both Excel and PDF
  static Future<void> _saveFileMobile(Uint8List bytes, String filename,
      String fileType, BuildContext context) async {
    try {
      if (Platform.isAndroid) {
        await _saveFileAndroid(bytes, filename, fileType, context);
      } else if (Platform.isIOS) {
        await _saveFileIOS(bytes, filename, fileType, context);
      } else {
        final mimeType =
            fileType == 'pdf' ? MimeType.pdf : MimeType.microsoftExcel;
        await FileSaver.instance.saveFile(
          name: filename,
          bytes: bytes,
          ext: fileType,
          mimeType: mimeType,
        );
        ToastHelper.showSuccessToast('File saved successfully', context);
      }
    } catch (e) {
      debugPrint('Mobile file save error: $e');
      _showSaveInstructions(context, filename, fileType);
    }
  }

  // Update Android save method to handle file type
  static Future<void> _saveFileAndroid(Uint8List bytes, String filename,
      String fileType, BuildContext context) async {
    try {
      // Request storage permission first
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        ToastHelper.showErrorToast(
          'Storage permission required to save to Downloads folder',
          context,
        );
        await _saveToAppDirectory(bytes, filename, fileType, context);
        return;
      }

      // Try to get the actual Downloads directory
      Directory? downloadsDir = await _getActualDownloadsDirectory();

      if (downloadsDir != null) {
        final file = File('${downloadsDir.path}/$filename');
        await file.writeAsBytes(bytes);

        ToastHelper.showSuccessToast(
          '${fileType.toUpperCase()} file saved to Downloads folder:\n$filename',
          context,
        );
        debugPrint('File saved to actual Downloads: ${file.path}');
        return;
      }

      // Fallback to app directory
      await _saveToAppDirectory(bytes, filename, fileType, context);
    } catch (e) {
      debugPrint('Android file save error: $e');
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

// Update app directory save to handle file type
  static Future<void> _saveToAppDirectory(Uint8List bytes, String filename,
      String fileType, BuildContext context) async {
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
        '${fileType.toUpperCase()} file saved to app storage:\n$filename\n\nUse a file manager to find it in Android/data/top.flareline.app/files/Download/',
        context,
      );
      debugPrint('File saved to app directory: ${file.path}');
    } else {
      throw Exception('Could not access app directory');
    }
  }

// Update iOS save method to handle file type
  static Future<void> _saveFileIOS(Uint8List bytes, String filename,
      String fileType, BuildContext context) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final file = File('${appDocDir.path}/$filename');
      await file.writeAsBytes(bytes);

      ToastHelper.showSuccessToast(
        '${fileType.toUpperCase()} file saved to Documents folder.\n\nUse the Files app to access it.',
        context,
      );
      debugPrint('File saved to: ${file.path}');
    } catch (e) {
      debugPrint('iOS file save error: $e');
      final mimeType =
          fileType == 'pdf' ? MimeType.pdf : MimeType.microsoftExcel;
      await FileSaver.instance.saveFile(
        name: filename,
        bytes: bytes,
        ext: fileType,
        mimeType: mimeType,
      );
      ToastHelper.showSuccessToast('File saved successfully', context);
    }
  }

  // Update save instructions to handle file type
  static void _showSaveInstructions(
      BuildContext context, String filename, String fileType) {
    if (Platform.isAndroid) {
      ToastHelper.showInfoToast(
        '${fileType.toUpperCase()} file ready: $filename\n\n'
        'Check your Downloads folder or use a file manager app to find the file.',
        context,
      );
    } else {
      ToastHelper.showInfoToast(
        '${fileType.toUpperCase()} file ready: $filename\n\n'
        'Check your Documents folder in the Files app.',
        context,
      );
    }
  }
}
