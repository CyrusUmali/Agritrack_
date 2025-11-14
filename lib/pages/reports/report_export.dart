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

class ReportExportOptions extends StatelessWidget {
  final String reportType;
  final List<Map<String, dynamic>> reportData;
  final Set<String> selectedColumns;
  final DateTimeRange dateRange;
  final BuildContext context;

  const ReportExportOptions({
    super.key,
    required this.reportType,
    required this.reportData,
    required this.selectedColumns,
    required this.dateRange,
    required this.context,
  });

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

  Future<void> _exportToPDF() async {
    if (reportData.isEmpty) {
      ToastHelper.showErrorToast('No data to export', context);
      return;
    }

    try {
      _showLoadingDialog('Generating PDF...');

      // Load the image as Uint8List before creating PDF
      final imageBytes = await rootBundle.load('assets/DA_image.jpg');
      final uint8Image = imageBytes.buffer.asUint8List();

      // Create PDF document with metadata
      final pdf = pw.Document(
        title: '${reportType.capitalize()} Report',
        author: 'Agritrack',
        creator: 'Flutter PDF Export',
        subject:
            '${reportType.capitalize()} Report - ${DateFormat('MMM d, yyyy').format(dateRange.start)} to ${DateFormat('MMM d, yyyy').format(dateRange.end)}',
      );

      final headers = selectedColumns.toList();
      final data = reportData.map((row) {
        return headers.map((column) {
          final value = row[column];
          if (value == null) return '';
          if (value is List) return value.join(', ');
          if (value is DateTime) return DateFormat('MMM d, yyyy').format(value);
          if (value is double) return value.toStringAsFixed(2);
          return value.toString();
        }).toList();
      }).toList();

      // Calculate optimal page layout
      final pageFormat = _determineOptimalPageFormat(headers.length);
      final maxRowsPerPage = _calculateMaxRowsPerPage(pageFormat);

      // Split data into pages if necessary
      for (int pageIndex = 0;
          pageIndex < (data.length / maxRowsPerPage).ceil();
          pageIndex++) {
        final startIndex = pageIndex * maxRowsPerPage;
        final endIndex = (startIndex + maxRowsPerPage).clamp(0, data.length);
        final pageData = data.sublist(startIndex, endIndex);

        pdf.addPage(
          pw.Page(
            pageFormat: pageFormat,
            margin: const pw.EdgeInsets.all(20),
            build: (pw.Context context) => _buildPDFPageContent(
              headers,
              pageData,
              pageIndex + 1,
              (data.length / maxRowsPerPage).ceil(),
              startIndex,
              uint8Image, // Pass the image bytes
            ),
          ),
        );
      }

      final bytes = await pdf.save();
      _closeLoadingDialog();

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = '${reportType}_report_$timestamp.pdf';

      // Handle file saving based on platform
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
      _closeLoadingDialog();
      ToastHelper.showErrorToast(
          'Error exporting PDF: ${e.toString()}', context);
      debugPrint('PDF Export Error: $e');
    }
  }

  // Determine optimal page format based on number of columns
  PdfPageFormat _determineOptimalPageFormat(int columnCount) {
    if (columnCount > 8) {
      return PdfPageFormat.a3.landscape; // A3 landscape for many columns
    } else if (columnCount > 5) {
      return PdfPageFormat.a4.landscape; // A4 landscape for medium columns
    } else {
      return PdfPageFormat.a4; // A4 portrait for few columns
    }
  }

  // Calculate maximum rows per page based on format
  int _calculateMaxRowsPerPage(PdfPageFormat format) {
    // Estimate based on page height and row height
    const double headerHeight = 120; // Header section height
    const double footerHeight = 30; // Footer height
    const double rowHeight = 22; // Estimated row height

    final availableHeight = format.height -
        format.marginTop -
        format.marginBottom -
        headerHeight -
        footerHeight;
    return (availableHeight / rowHeight).floor();
  }

// Update the _buildPDFPageContent signature to accept the image
  pw.Widget _buildPDFPageContent(
    List<String> headers,
    List<List<String>> data,
    int currentPage,
    int totalPages,
    int startRowIndex,
    Uint8List imageBytes, // Add image parameter
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Enhanced header section with image
        _buildPDFHeader(imageBytes),
        pw.SizedBox(height: 20),
        // Data summary section
        _buildDataSummary(startRowIndex, data.length),
        pw.SizedBox(height: 15),
        // Main data table
        pw.Expanded(child: _buildEnhancedTable(headers, data)),
        // Footer with page numbers
        pw.SizedBox(height: 10),
        _buildPDFFooter(currentPage, totalPages),
      ],
    );
  }

// Updated _buildPDFHeader to accept and use the image
  pw.Widget _buildPDFHeader(Uint8List imageBytes) {
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

          // Middle: Report title and date range
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${reportType.capitalize()} Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#3f51b5'),
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

          // Right side: Generated date and total records
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Generated: ${DateFormat('MMM d, yyyy HH:mm').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Total Records: ${reportData.length}',
                style:
                    pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Data summary section
  pw.Widget _buildDataSummary(int startIndex, int pageRows) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#f5f5f5'),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        'Showing records ${startIndex + 1} - ${startIndex + pageRows} of ${reportData.length} total records',
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

// Enhanced table with better styling
  pw.Widget _buildEnhancedTable(List<String> headers, List<List<String>> data) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: _calculateOptimalColumnWidths(headers, data),
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
              alignment:
                  pw.Alignment.center, // Center horizontally and vertically
              child: pw.Text(
                header.toUpperCase(), // Capitalize header text
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
                    const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                alignment:
                    pw.Alignment.center, // Center horizontally and vertically
                child: pw.Text(
                  cell,
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: _getCellAlignment(cell),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ],
    );
  }

// Smart cell alignment based on content
  pw.TextAlign _getCellAlignment(String cell) {
    if (RegExp(r'^\d+\.?\d*$').hasMatch(cell)) {
      return pw.TextAlign.right; // Numbers aligned right
    } else if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(cell)) {
      return pw.TextAlign.center; // Dates centered
    }
    return pw.TextAlign.center; // Default to center for all other text
  }

  // Calculate optimal column widths
  Map<int, pw.TableColumnWidth> _calculateOptimalColumnWidths(
      List<String> headers, List<List<String>> data) {
    final Map<int, pw.TableColumnWidth> widths = {};

    if (headers.length <= 3) {
      // For few columns, use equal width
      for (int i = 0; i < headers.length; i++) {
        widths[i] = const pw.FlexColumnWidth();
      }
    } else if (headers.length <= 6) {
      // For medium columns, use proportional width
      for (int i = 0; i < headers.length; i++) {
        widths[i] = const pw.FlexColumnWidth(1.0);
      }
    } else {
      // For many columns, use fixed smaller widths
      for (int i = 0; i < headers.length; i++) {
        widths[i] = const pw.FixedColumnWidth(60);
      }
    }

    return widths;
  }

  // PDF footer with page information
  pw.Widget _buildPDFFooter(int currentPage, int totalPages) {
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

  Future<void> _exportToExcel() async {
    if (reportData.isEmpty) {
      ToastHelper.showErrorToast('No data to export', context);
      return;
    }

    try {
      _showLoadingDialog('Generating Excel file...');

      final excel = Excel.createExcel();
      final sheet = excel['${reportType.capitalize()} Report'];

      // Remove default sheet
      excel.delete('Sheet1');

      // Define styles that match PDF styling
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
        // horizontalAlign: HorizontalAlign.Center, // Add this
        // verticalAlign: VerticalAlign.Center, // Add vertical center
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
        fontColorHex: ExcelColor.white,
        backgroundColorHex: ExcelColor.fromHexString('#3f51b5'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      final dataStyle = CellStyle(
        fontFamily: getFontFamily(FontFamily.Arial),
        fontSize: 9,
        fontColorHex: ExcelColor.fromHexString('#333333'),
        horizontalAlign: HorizontalAlign.Center, // Add this
        verticalAlign: VerticalAlign.Center, // Add vertical center
      );

      final alternateRowStyle = CellStyle(
        fontFamily: getFontFamily(FontFamily.Arial),
        fontSize: 9,
        fontColorHex: ExcelColor.fromHexString('#333333'),
        backgroundColorHex: ExcelColor.fromHexString('#fafafa'),
        horizontalAlign: HorizontalAlign.Center, // Add this
        verticalAlign: VerticalAlign.Center, // Add vertical center
      );

      final numberStyle = CellStyle(
        fontFamily: getFontFamily(FontFamily.Arial),
        fontSize: 9,
        fontColorHex: ExcelColor.fromHexString('#333333'),

        horizontalAlign: HorizontalAlign.Center, // Add this
        verticalAlign: VerticalAlign.Center, // Add vertical center
      );

      final alternateNumberStyle = CellStyle(
        fontFamily: getFontFamily(FontFamily.Arial),
        fontSize: 9,
        fontColorHex: ExcelColor.fromHexString('#333333'),
        backgroundColorHex: ExcelColor.fromHexString('#fafafa'),
        horizontalAlign: HorizontalAlign.Center, // Add this
        verticalAlign: VerticalAlign.Center, // Add vertical center
      );

      final summaryStyle = CellStyle(
        fontFamily: getFontFamily(FontFamily.Arial),
        fontSize: 9,
        fontColorHex: ExcelColor.fromHexString('#333333'),
        backgroundColorHex: ExcelColor.fromHexString('#f5f5f5'),
        bold: true,
        // horizontalAlign: HorizontalAlign.Center, // Add this
        // verticalAlign: VerticalAlign.Center, // Add vertical center
      );

      // Create report header section (similar to PDF)
      int currentRow = 0;

      // Main title (matches PDF header)
      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
        ..value = TextCellValue('${reportType.capitalize()} Report')
        ..cellStyle = titleStyle;
      currentRow++;

      String dateRangeText;
      if (dateRange.start == DateTime(1970) &&
          dateRange.end == DateTime(1970)) {
        dateRangeText = 'Date Range: All';
      } else {
        dateRangeText =
            'Date Range: ${DateFormat('MMM d, yyyy').format(dateRange.start)} - ${DateFormat('MMM d, yyyy').format(dateRange.end)}';
      }

      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
        ..value = TextCellValue(dateRangeText)
        ..cellStyle = subtitleStyle;
      currentRow++;

      // Metadata row (similar to PDF header right side)
      final metadataRow = currentRow;
      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: metadataRow))
        ..value = TextCellValue(
            'Generated: ${DateFormat('MMM d, yyyy HH:mm').format(DateTime.now())}')
        ..cellStyle = metadataStyle;

      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: metadataRow))
        ..value = TextCellValue('Total Records: ${reportData.length}')
        ..cellStyle = CellStyle(
          fontFamily: getFontFamily(FontFamily.Arial),
          fontSize: 10,
          fontColorHex: ExcelColor.fromHexString('#333333'),
          bold: true,
        );
      currentRow += 2;

      // Data summary section (matches PDF)
      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
        ..value = TextCellValue('Showing all ${reportData.length} records')
        ..cellStyle = summaryStyle;
      currentRow += 2;

      // Add column headers (matches PDF table header)
      final headers = selectedColumns.toList();
      for (int col = 0; col < headers.length; col++) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRow));
        cell.value =
            TextCellValue(headers[col].toUpperCase()); // ← ADD .toUpperCase()
        cell.cellStyle = headerStyle;
      }
      currentRow++;

      // Add data rows with alternating colors (matches PDF table)
      for (int rowIndex = 0; rowIndex < reportData.length; rowIndex++) {
        final row = reportData[rowIndex];
        final isAlternateRow = rowIndex % 2 == 1;

        for (int colIndex = 0; colIndex < headers.length; colIndex++) {
          final column = headers[colIndex];
          final value = row[column];
          final cell = sheet.cell(CellIndex.indexByColumnRow(
              columnIndex: colIndex, rowIndex: currentRow));

          // Set cell value with proper type handling
          if (value == null) {
            cell.value = TextCellValue('');
          } else if (value is DateTime) {
            cell.value = TextCellValue(DateFormat('MMM d, yyyy').format(value));
          } else if (value is double) {
            cell.value = DoubleCellValue(value);
            cell.cellStyle =
                isAlternateRow ? alternateNumberStyle : numberStyle;
            continue;
          } else if (value is int) {
            cell.value = IntCellValue(value);
            cell.cellStyle =
                isAlternateRow ? alternateNumberStyle : numberStyle;
            continue;
          } else if (value is List) {
            cell.value = TextCellValue(value.join(', '));
          } else {
            cell.value = TextCellValue(value.toString());
          }

          // Apply appropriate style with text alignment based on content type
          final baseStyle = isAlternateRow ? alternateRowStyle : dataStyle;
          final alignedStyle = _getAlignedStyle(baseStyle, value);
          cell.cellStyle = alignedStyle;
        }
        currentRow++;
      }

      // Auto-size columns to fit content
      _autoSizeColumns(sheet, headers, reportData);

      // Add borders to the data table to match PDF appearance
      _addTableBorders(
          sheet, headers.length, reportData.length, 5); // Starting from row 5

      // Set sheet as default
      excel.setDefaultSheet(sheet.sheetName);

      final bytes = excel.save();
      _closeLoadingDialog();

      if (bytes == null) {
        throw Exception('Failed to generate Excel file');
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = '${reportType}_report_$timestamp.xlsx';

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
        // Mobile platform
        await _saveFileMobile(
            Uint8List.fromList(bytes), filename, 'excel', context);
      }
    } catch (e) {
      _closeLoadingDialog();
      ToastHelper.showErrorToast(
          'Error exporting Excel: ${e.toString()}', context);
      debugPrint('Excel Export Error: $e');
    }
  }

  // Helper function to get aligned style based on content type
  CellStyle _getAlignedStyle(CellStyle baseStyle, dynamic value) {
    if (value == null) return baseStyle;

    HorizontalAlign align = HorizontalAlign.Center;

    if (value is num) {
      align = HorizontalAlign.Right;
    } else if (value is DateTime) {
      align = HorizontalAlign.Center;
    }

    return CellStyle(
      bold: baseStyle.isBold,
      fontFamily: baseStyle.fontFamily,
      fontSize: baseStyle.fontSize,
      fontColorHex: baseStyle.fontColor,
      backgroundColorHex: baseStyle.backgroundColor,
      horizontalAlign: align,
    );
  }

  // Improved auto-size columns function
  void _autoSizeColumns(
      Sheet sheet, List<String> headers, List<Map<String, dynamic>> data) {
    for (int colIndex = 0; colIndex < headers.length; colIndex++) {
      double maxWidth =
          headers[colIndex].length * 1.8; // Header width with padding

      // Check data for max width
      for (final row in data) {
        final value = row[headers[colIndex]];
        String displayValue = '';

        if (value is DateTime) {
          displayValue = DateFormat('MMM d, yyyy').format(value);
        } else if (value is List) {
          displayValue = value.join(', ');
        } else if (value is double) {
          displayValue = value.toStringAsFixed(2);
        } else if (value is int) {
          displayValue = value.toString();
        } else if (value != null) {
          displayValue = value.toString();
        }

        if (displayValue.length > maxWidth) {
          maxWidth = displayValue.length * 1.4; // Add padding
        }
      }

      // Set reasonable limits
      maxWidth = maxWidth.clamp(12, 40);

      // Set column width
      try {
        sheet.setColumnWidth(colIndex, maxWidth);
      } catch (e) {
        debugPrint('Could not set column width: $e');
      }
    }
  }

  // Add borders to make Excel look more like PDF table
  void _addTableBorders(
      Sheet sheet, int columnCount, int rowCount, int startRow) {
    // Implementation depends on your Excel package's border capabilities
    // This is a placeholder - adjust based on your package's API
    try {
      // Add basic borders to header row
      for (int col = 0; col < columnCount; col++) {
        final headerCell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: startRow));
        // Add border styling if supported by your package
      }
    } catch (e) {
      debugPrint('Border styling not supported: $e');
    }
  }

  Future<void> _printReport() async {
    if (reportData.isEmpty) {
      ToastHelper.showErrorToast('No data to print', context);
      return;
    }

    try {
      _showLoadingDialog('Preparing print...');

      // Load the image as Uint8List before creating PDF
      final imageBytes = await rootBundle.load('assets/DA_image.jpg');
      final uint8Image = imageBytes.buffer.asUint8List();

      // Create PDF document for printing with same metadata as export
      final pdf = pw.Document(
        title: '${reportType.capitalize()} Report',
        author: 'Agritrack',
        creator: 'Flutter PDF Export',
        subject:
            '${reportType.capitalize()} Report - ${DateFormat('MMM d, yyyy').format(dateRange.start)} to ${DateFormat('MMM d, yyyy').format(dateRange.end)}',
      );

      final headers = selectedColumns.toList();
      final data = reportData.map((row) {
        return headers.map((column) {
          final value = row[column];
          if (value == null) return '';
          if (value is List) return value.join(', ');
          if (value is DateTime) return DateFormat('MMM d, yyyy').format(value);
          if (value is double) return value.toStringAsFixed(2);
          return value.toString();
        }).toList();
      }).toList();

      // Use the same page format calculation as PDF export
      final pageFormat = _determineOptimalPageFormat(headers.length);
      final maxRowsPerPage = _calculateMaxRowsPerPage(pageFormat);

      // Split data into pages using the same logic as PDF export
      for (int pageIndex = 0;
          pageIndex < (data.length / maxRowsPerPage).ceil();
          pageIndex++) {
        final startIndex = pageIndex * maxRowsPerPage;
        final endIndex = (startIndex + maxRowsPerPage).clamp(0, data.length);
        final pageData = data.sublist(startIndex, endIndex);

        pdf.addPage(
          pw.Page(
            pageFormat: pageFormat,
            margin: const pw.EdgeInsets.all(20),
            build: (pw.Context context) => _buildPDFPageContent(
              headers,
              pageData,
              pageIndex + 1,
              (data.length / maxRowsPerPage).ceil(),
              startIndex,
              uint8Image, // Pass the image bytes
            ),
          ),
        );
      }

      _closeLoadingDialog();

      // Print the PDF using the same layout as export
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      ToastHelper.showSuccessToast('Print dialog opened', context);
    } catch (e) {
      _closeLoadingDialog();
      ToastHelper.showErrorToast(
        'Error printing report: ${e.toString()}',
        context,
      );
      debugPrint('Print Error: $e');
    }
  }

  // Mobile file saving method
  Future<void> _saveFileMobile(Uint8List bytes, String filename,
      String fileType, BuildContext context) async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await _saveToAppDirectory(bytes, filename, fileType, context);
      } else {
        // Fallback for other platforms
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
      // Final fallback
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
        // Try to save to actual Downloads folder first
        directory = await _getActualDownloadsDirectory() ??
            await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();
      } else {
        // iOS uses application documents directory
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

// Add this new method to get actual Downloads directory
  static Future<Directory?> _getActualDownloadsDirectory() async {
    if (Platform.isAndroid) {
      // Request storage permission first
      try {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          return null;
        }
      } catch (e) {
        debugPrint('Permission request failed: $e');
      }

      // Try known paths for Downloads folder
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

      // Try using environment variables
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

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(strokeWidth: 3),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'This may take a moment...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _closeLoadingDialog() {
    Navigator.of(context).pop();
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
