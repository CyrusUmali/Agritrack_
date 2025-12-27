import 'package:file_saver/file_saver.dart';
import 'package:flareline/pages/toast/toast_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:isolate';

class ReportExportOptions extends StatelessWidget {
  final String reportType;
  static Uint8List? _cachedImage;
  final List<Map<String, dynamic>> reportData;
  final Set<String> selectedColumns;
  final DateTimeRange dateRange;
  final BuildContext context;

    ReportExportOptions({
    super.key,
    required this.reportType,
    required this.reportData,
    required this.selectedColumns,
    required this.dateRange,
    required this.context,
  });
bool _isCancelled = false;
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => _exportToPDF(),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Export PDF'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: () => _exportToExcel(),
                icon: const Icon(Icons.grid_on),
                label: const Text('Export Excel'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: () => _printReport(),
                icon: const Icon(Icons.print),
                label: const Text('Print'),
              ),
            ],
          ),
        ),
      ),
    );
  }



    static Future<Uint8List> _getImage() async {
    if (_cachedImage == null) {
      final imageBytes = await rootBundle.load('assets/DA_image.jpg');
      _cachedImage = imageBytes.buffer.asUint8List();
    }
    return _cachedImage!;
  }





 Future<void> _exportToPDF() async {
    if (reportData.isEmpty) {
      ToastHelper.showErrorToast('No data to export', context);
      return;
    }

    _isCancelled = false;

    try {
      _showLoadingDialog('Generating PDF...', onCancel: () {
        _isCancelled = true;
      });

      // Let the dialog render
      await Future.delayed(const Duration(milliseconds: 500));

      if (_isCancelled) {
        _closeLoadingDialog();
        return;
      }

      // Get cached image (fast if already loaded)
      final uint8Image = await _getImage();

      if (_isCancelled) {
        _closeLoadingDialog();
        return;
      }

      final pdfData = PDFGenerationData(
        reportType: reportType,
        reportData: reportData,
        selectedColumns: selectedColumns.toList(),
        dateRange: dateRange,
        imageBytes: uint8Image,
      );

      final bytes = await compute(_generatePDFInIsolate, pdfData);

      if (_isCancelled) {
        _closeLoadingDialog();
        return;
      }

      _closeLoadingDialog();

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = '${reportType}_report_$timestamp.pdf';

      if (kIsWeb) {
        await FileSaver.instance.saveFile(
          name: filename,
          bytes: bytes,
          ext: 'pdf',
          mimeType: MimeType.pdf,
        );
        ToastHelper.showSuccessToast('PDF downloaded successfully', context);
      } else {
        await _saveFileMobile(bytes, filename, 'pdf', context);
      }
    } catch (e) {
      if (!_isCancelled) {
        _closeLoadingDialog();
        ToastHelper.showErrorToast('Error: ${e.toString()}', context);
      }
    }
  }





  // Static method to run in isolate
  static Future<Uint8List> _generatePDFInIsolate(PDFGenerationData data) async {
    final pdf = pw.Document(
      title: '${data.reportType.capitalize()} Report',
      author: 'Agritrack',
      creator: 'Flutter PDF Export',
      subject:
          '${data.reportType.capitalize()} Report - ${DateFormat('MMM d, yyyy').format(data.dateRange.start)} to ${DateFormat('MMM d, yyyy').format(data.dateRange.end)}',
    );

    final headers = data.selectedColumns;
    final tableData = data.reportData.map((row) {
      return headers.map((column) {
        final value = row[column];
        if (value == null) return '';
        if (value is List) return value.join(', ');
        if (value is DateTime) return DateFormat('MMM d, yyyy').format(value);
        if (value is double) return value.toStringAsFixed(2);
        return value.toString();
      }).toList();
    }).toList();

    final pageFormat = _determineOptimalPageFormatStatic(headers.length);
    final maxRowsPerPage = _calculateMaxRowsPerPageStatic(pageFormat);

    for (int pageIndex = 0;
        pageIndex < (tableData.length / maxRowsPerPage).ceil();
        pageIndex++) {
      final startIndex = pageIndex * maxRowsPerPage;
      final endIndex = (startIndex + maxRowsPerPage).clamp(0, tableData.length);
      final pageData = tableData.sublist(startIndex, endIndex);

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) => _buildPDFPageContentStatic(
            headers,
            pageData,
            pageIndex + 1,
            (tableData.length / maxRowsPerPage).ceil(),
            startIndex,
            data.imageBytes,
            data.reportType,
            data.dateRange,
            data.reportData.length,
          ),
        ),
      );
    }

    return Uint8List.fromList(await pdf.save());
  }




  static PdfPageFormat _determineOptimalPageFormatStatic(int columnCount) {
    if (columnCount > 8) {
      return PdfPageFormat.a3.landscape;
    } else if (columnCount > 5) {
      return PdfPageFormat.a4.landscape;
    } else {
      return PdfPageFormat.a4;
    }
  }

  static int _calculateMaxRowsPerPageStatic(PdfPageFormat format) {
    const double headerHeight = 120;
    const double footerHeight = 30;
    const double rowHeight = 22;

    final availableHeight = format.height -
        format.marginTop -
        format.marginBottom -
        headerHeight -
        footerHeight;
    return (availableHeight / rowHeight).floor();
  }


static pw.Widget _buildPDFPageContentStatic(
  List<String> headers,
  List<List<String>> data,
  int currentPage,
  int totalPages,
  int startRowIndex,
  Uint8List imageBytes,
  String reportType,
  DateTimeRange dateRange,
  int totalRecords,
) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      // Show header only on the first page
      if (currentPage == 1) ...[
        _buildPDFHeaderStatic(
          imageBytes, 
          reportType, 
          dateRange, 
          totalRecords,
        ),
        pw.SizedBox(height: 20),
        _buildDataSummaryStatic(startRowIndex, data.length, totalRecords),
        pw.SizedBox(height: 15),
      ] , 
      
      pw.Expanded(child: _buildEnhancedTableStatic(headers, data)),
      pw.SizedBox(height: 10),
      _buildPDFFooterStatic(currentPage, totalPages),
    ],
  );
}

static pw.Widget _buildMinimalPageHeaderStatic(
  String reportType,
  DateTimeRange dateRange,
  int currentPage,
  int totalPages,
) {
  return pw.Container(
    
 
  );
}

static pw.Widget _buildPDFHeaderStatic(
  Uint8List imageBytes,
  String reportType,
  DateTimeRange dateRange,
  int totalRecords,
) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border(
        // bottom: pw.BorderSide(color: PdfColor.fromHex('#3f51b5'), width: 2),
      ),
    ),
    padding: const pw.EdgeInsets.only(bottom: 10),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.SizedBox(
          width: 80,
          height: 80,
          child: pw.Image(
            pw.MemoryImage(imageBytes),
            fit: pw.BoxFit.contain,
          ),
        ),
        pw.SizedBox(width: 15),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '${reportType.capitalize()} Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold, 
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                dateRange.start == DateTime(1970) &&
                        dateRange.end == DateTime(1970)
                    ? 'Date Range: All'
                    : 'Date Range: ${DateFormat('MMM d, yyyy').format(dateRange.start)} - ${DateFormat('MMM d, yyyy').format(dateRange.end)}',
                style: pw.TextStyle(
                    fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Generated: ${DateFormat('MMM d, yyyy HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              'Total Records: $totalRecords',
              style:
                  pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ],
    ),
  );
}

static pw.Widget _buildDataSummaryStatic(
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
















 
 
  static pw.Widget _buildEnhancedTableStatic(
      List<String> headers, List<List<String>> data) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: _calculateOptimalColumnWidthsStatic(headers, data),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(
            // gradient: pw.LinearGradient(
            //   colors: [
            //     PdfColor.fromHex('#3f51b5'),
            //     PdfColor.fromHex('#303f9f')
            //   ],
            // ),
          ),
          children: headers.map((header) {
            return pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              alignment: pw.Alignment.center,
              child: pw.Text(
                header.toUpperCase(),
                style: pw.TextStyle(
        
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                ),
                textAlign: pw.TextAlign.center,
              ),
            );
          }).toList(),
        ),
        ...data.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color:
                  index.isEven ? PdfColors.white : PdfColor.fromHex('#fafafa'),
            ),
            children: row.map((cell) {
              return pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  cell,
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              );
            }).toList(),
          );
        }).toList(),
      ],
    );
  }

  static Map<int, pw.TableColumnWidth> _calculateOptimalColumnWidthsStatic(
      List<String> headers, List<List<String>> data) {
    final Map<int, pw.TableColumnWidth> widths = {};

    if (headers.length <= 3) {
      for (int i = 0; i < headers.length; i++) {
        widths[i] = const pw.FlexColumnWidth();
      }
    } else if (headers.length <= 6) {
      for (int i = 0; i < headers.length; i++) {
        widths[i] = const pw.FlexColumnWidth(1.0);
      }
    } else {
      for (int i = 0; i < headers.length; i++) {
        widths[i] = const pw.FixedColumnWidth(60);
      }
    }

    return widths;
  }

  static pw.Widget _buildPDFFooterStatic(int currentPage, int totalPages) {
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
            '--',
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

  // Legacy methods (keep for compatibility)
  PdfPageFormat _determineOptimalPageFormat(int columnCount) {
    return _determineOptimalPageFormatStatic(columnCount);
  }

  int _calculateMaxRowsPerPage(PdfPageFormat format) {
    return _calculateMaxRowsPerPageStatic(format);
  }

  pw.Widget _buildPDFPageContent(
    List<String> headers,
    List<List<String>> data,
    int currentPage,
    int totalPages,
    int startRowIndex,
    Uint8List imageBytes,
  ) {
    return _buildPDFPageContentStatic(
      headers,
      data,
      currentPage,
      totalPages,
      startRowIndex,
      imageBytes,
      reportType,
      dateRange,
      reportData.length,
    );
  }

  Future<void> _exportToExcel() async {
    if (reportData.isEmpty) {
      ToastHelper.showErrorToast('No data to export', context);
      return;
    }

    _isCancelled = false;

    try {
      _showLoadingDialog('Generating Excel file...', onCancel: () {
        _isCancelled = true;
      });

      // Wait for the dialog to render before starting heavy work
      await Future.delayed(const Duration(milliseconds: 100));

      if (_isCancelled) {
        _closeLoadingDialog();
        ToastHelper.showErrorToast('Excel export cancelled', context);
        return;
      }

      // Prepare data for isolate
      final excelData = ExcelGenerationData(
        reportType: reportType,
        reportData: reportData,
        selectedColumns: selectedColumns.toList(),
        dateRange: dateRange,
      );

      // Generate Excel in isolate (non-blocking)
      final bytes = await compute(_generateExcelInIsolate, excelData);

      if (_isCancelled) {
        _closeLoadingDialog();
        ToastHelper.showErrorToast('Excel export cancelled', context);
        return;
      }

      _closeLoadingDialog();

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = '${reportType}_report_$timestamp.xlsx';

      if (kIsWeb) {
        await FileSaver.instance.saveFile(
          name: filename,
          bytes: bytes,
          ext: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
        ToastHelper.showSuccessToast(
            'Excel file downloaded successfully', context);
      } else {
        await _saveFileMobile(bytes, filename, 'excel', context);
      }
    } catch (e) {
      if (!_isCancelled) {
        _closeLoadingDialog();
        ToastHelper.showErrorToast(
            'Error exporting Excel: ${e.toString()}', context);
        debugPrint('Excel Export Error: $e');
      }
    }
  }



static Future<Uint8List> _generateExcelInIsolate(
    ExcelGenerationData data) async {
  final excel = Excel.createExcel();
  final sheet = excel['${data.reportType.capitalize()} Report'];
  excel.delete('Sheet1');

  // Define styles
  final titleStyle = CellStyle(
    bold: true,
    fontFamily: getFontFamily(FontFamily.Arial),
    fontSize: 16,
    // fontColorHex: ExcelColor.fromHexString('#3f51b5'),
  );

  final subtitleStyle = CellStyle(
    bold: true,
    fontFamily: getFontFamily(FontFamily.Arial),
    fontSize: 11,
  );

  final metadataStyle = CellStyle(
    fontFamily: getFontFamily(FontFamily.Arial),
    fontSize: 10,
    fontColorHex: ExcelColor.fromHexString('#666666'),
  );

  final headerStyle = CellStyle(
    bold: true,
    fontFamily: getFontFamily(FontFamily.Arial),
    fontSize: 10, 
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  final dataStyle = CellStyle(
    fontFamily: getFontFamily(FontFamily.Arial),
    fontSize: 9,
    fontColorHex: ExcelColor.fromHexString('#333333'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  // Remove this alternating row style since we don't want alternating colors
  // final alternateRowStyle = CellStyle(
  //   fontFamily: getFontFamily(FontFamily.Arial),
  //   fontSize: 9,
  //   fontColorHex: ExcelColor.fromHexString('#333333'),
  //   backgroundColorHex: ExcelColor.fromHexString('#fafafa'),
  //   horizontalAlign: HorizontalAlign.Center,
  //   verticalAlign: VerticalAlign.Center,
  // );

  final summaryStyle = CellStyle(
    fontFamily: getFontFamily(FontFamily.Arial),
    fontSize: 9,
    fontColorHex: ExcelColor.fromHexString('#333333'),
    backgroundColorHex: ExcelColor.fromHexString('#f5f5f5'),
    bold: true,
  );

  int currentRow = 0;

  // Title
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
    ..value = TextCellValue('${data.reportType.capitalize()} Report')
    ..cellStyle = titleStyle;
  currentRow++;

  // Date range
  String dateRangeText = data.dateRange.start == DateTime(1970) &&
          data.dateRange.end == DateTime(1970)
      ? 'Date Range: All'
      : 'Date Range: ${DateFormat('MMM d, yyyy').format(data.dateRange.start)} - ${DateFormat('MMM d, yyyy').format(data.dateRange.end)}';

  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
    ..value = TextCellValue(dateRangeText)
    ..cellStyle = subtitleStyle;
  currentRow++;

  // Metadata
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
    ..value = TextCellValue(
        'Generated: ${DateFormat('MMM d, yyyy HH:mm').format(DateTime.now())}')
    ..cellStyle = metadataStyle;

  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow))
    ..value = TextCellValue('Total Records: ${data.reportData.length}')
    ..cellStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Arial),
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString('#333333'),
      bold: true,
    );
  currentRow += 2;

 
  // Headers
  final headers = data.selectedColumns;
  for (int col = 0; col < headers.length; col++) {
    final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRow));
    cell.value = TextCellValue(headers[col].toUpperCase());
    cell.cellStyle = headerStyle;
  }
  currentRow++;

  // Data rows - all use the same dataStyle (no alternating colors)
  for (int rowIndex = 0; rowIndex < data.reportData.length; rowIndex++) {
    final row = data.reportData[rowIndex];
    // No need to check for alternate rows anymore

    for (int colIndex = 0; colIndex < headers.length; colIndex++) {
      final column = headers[colIndex];
      final value = row[column];
      final cell = sheet.cell(CellIndex.indexByColumnRow(
          columnIndex: colIndex, rowIndex: currentRow));

      if (value == null) {
        cell.value = TextCellValue('');
      } else if (value is DateTime) {
        cell.value = TextCellValue(DateFormat('MMM d, yyyy').format(value));
      } else if (value is double) {
        cell.value = DoubleCellValue(value);
      } else if (value is int) {
        cell.value = IntCellValue(value);
      } else if (value is List) {
        cell.value = TextCellValue(value.join(', '));
      } else {
        cell.value = TextCellValue(value.toString());
      }

      cell.cellStyle = dataStyle; // Always use dataStyle, no alternating
    }
    currentRow++;
  }

  // Auto-size columns
  for (int colIndex = 0; colIndex < headers.length; colIndex++) {
    double maxWidth = headers[colIndex].length * 1.8;

    for (final row in data.reportData) {
      final value = row[headers[colIndex]];
      String displayValue = '';

      if (value is DateTime) {
        displayValue = DateFormat('MMM d, yyyy').format(value);
      } else if (value is List) {
        displayValue = value.join(', ');
      } else if (value != null) {
        displayValue = value.toString();
      }

      if (displayValue.length > maxWidth) {
        maxWidth = displayValue.length * 1.4;
      }
    }

    maxWidth = maxWidth.clamp(12, 40);
    sheet.setColumnWidth(colIndex, maxWidth);
  }

  excel.setDefaultSheet(sheet.sheetName);
  final bytes = excel.save();

  if (bytes == null) {
    throw Exception('Failed to generate Excel file');
  }

  return Uint8List.fromList(bytes);
}



  Future<void> _printReport() async {
    if (reportData.isEmpty) {
      ToastHelper.showErrorToast('No data to print', context);
      return;
    }

    _isCancelled = false;

    try {
      _showLoadingDialog('Preparing print...', onCancel: () {
        _isCancelled = true;
      });

      // Wait for the dialog to render before starting heavy work
      await Future.delayed(const Duration(milliseconds: 100));

      if (_isCancelled) {
        _closeLoadingDialog();
        ToastHelper.showErrorToast('Print cancelled', context);
        return;
      }

      final imageBytes = await rootBundle.load('assets/DA_image.jpg');
      final uint8Image = imageBytes.buffer.asUint8List();

      if (_isCancelled) {
        _closeLoadingDialog();
        ToastHelper.showErrorToast('Print cancelled', context);
        return;
      }

      final pdfData = PDFGenerationData(
        reportType: reportType,
        reportData: reportData,
        selectedColumns: selectedColumns.toList(),
        dateRange: dateRange,
        imageBytes: uint8Image,
      );

      final bytes = await compute(_generatePDFInIsolate, pdfData);

      if (_isCancelled) {
        _closeLoadingDialog();
        ToastHelper.showErrorToast('Print cancelled', context);
        return;
      }

      _closeLoadingDialog();

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
      );

      ToastHelper.showSuccessToast('Print dialog opened', context);
    } catch (e) {
      if (!_isCancelled) {
        _closeLoadingDialog();
        ToastHelper.showErrorToast(
          'Error printing report: ${e.toString()}',
          context,
        );
        debugPrint('Print Error: $e');
      }
    }
  }

  Future<void> _saveFileMobile(Uint8List bytes, String filename,
      String fileType, BuildContext context) async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await _saveToAppDirectory(bytes, filename, fileType, context);
      } else {
        await FileSaver.instance.saveFile(
          name: filename,
          bytes: bytes,
          ext: fileType,
          mimeType: fileType == 'pdf' ? MimeType.pdf : MimeType.microsoftExcel,
        );
        ToastHelper.showSuccessToast('File saved successfully', context);
      }
    } catch (e) {
      debugPrint('Mobile file save error: $e');
      await FileSaver.instance.saveFile(
        name: filename,
        bytes: bytes,
        ext: fileType,
        mimeType: fileType == 'pdf' ? MimeType.pdf : MimeType.microsoftExcel,
      );
      ToastHelper.showSuccessToast('File saved via system dialog', context);
    }
  }

  Future<void> _saveToAppDirectory(Uint8List bytes, String filename,
      String fileType, BuildContext context) async {
    try {
      Directory directory;

      if (Platform.isAndroid) {
        directory = await _getActualDownloadsDirectory() ??
            await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(bytes);

      String message;
      if (Platform.isAndroid) {
        if (directory.path.contains('Download')) {
          message = 'File saved to Downloads folder:\n$filename';
        } else {
          message =
              'File saved to: ${directory.path}\n\nUse a file manager to access it.';
        }
      } else {
        message = 'File saved to Documents folder. Use Files app to access it.';
      }

      ToastHelper.showSuccessToast(
          '${fileType.toUpperCase()} file saved successfully!\n$message',
          context);
      debugPrint('File saved to: ${file.path}');
    } catch (e) {
      debugPrint('Error saving to app directory: $e');
      rethrow;
    }
  }

  static Future<Directory?> _getActualDownloadsDirectory() async {
    if (Platform.isAndroid) {
      try {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          return null;
        }
      } catch (e) {
        debugPrint('Permission request failed: $e');
      }

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

  void _showLoadingDialog(String message, {VoidCallback? onCancel}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Prevent back button dismiss
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(strokeWidth: 3),
              const SizedBox(height: 20),
              Text(
                message,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'This may take a moment...',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              if (onCancel != null) ...[
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    onCancel();
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _closeLoadingDialog() {
    Navigator.of(context).pop();
  }
}

// Data classes for isolate communication
class PDFGenerationData {
  final String reportType;
  final List<Map<String, dynamic>> reportData;
  final List<String> selectedColumns;
  final DateTimeRange dateRange;
  final Uint8List imageBytes;

  PDFGenerationData({
    required this.reportType,
    required this.reportData,
    required this.selectedColumns,
    required this.dateRange,
    required this.imageBytes,
  });
}

class ExcelGenerationData {
  final String reportType;
  final List<Map<String, dynamic>> reportData;
  final List<String> selectedColumns;
  final DateTimeRange dateRange;

  ExcelGenerationData({
    required this.reportType,
    required this.reportData,
    required this.selectedColumns,
    required this.dateRange,
  });
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
