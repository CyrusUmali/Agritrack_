import 'package:flareline/pages/toast/toast_helper.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flareline/pages/layout.dart';
import 'package:provider/provider.dart';
import 'report_filter_panel.dart';
import 'report_preview.dart';
import 'report_export.dart';
import 'report_generator.dart';
import 'package:flareline/services/lanugage_extension.dart';

class ReportsPage extends LayoutWidget {
  const ReportsPage({super.key});

  @override
  String breakTabTitle(BuildContext context) {
    return context.translate('Reports');
  }

  @override
  Widget contentDesktopWidget(BuildContext context) {
    return const ReportContent();
  }
}

class ReportContent extends StatefulWidget {
  const ReportContent({super.key});

  @override
  State<ReportContent> createState() => _ReportContentState();
}

class _ReportContentState extends State<ReportContent> {
  // Filter state
  DateTimeRange dateRange = DateTimeRange(
    start: DateTime(1970), // Or any other "empty" marker date
    end: DateTime(1970),
  );

  String selectedBarangay = '';
  String selectedFarmer = '';
  String selectedView = '';
  String selectedCount = '';
  String selectedSector = '';
  String selectedProduct = '';
  String selectedAssoc = '';
  String selectedFarm = '';
  String reportType = 'farmer';
  String outputFormat = 'table';
  Set<String> selectedColumns = {};
  bool isLoading = false;
  List<Map<String, dynamic>> reportData = [];
  List<Map<String, dynamic>> filteredReportData = [];
  String searchQuery = '';
  bool hasGeneratedReport =
      false; // Add this to track if a report has been generated
  // Add a key for the ReportPreview to force rebuild
  UniqueKey _previewKey = UniqueKey();

  Future<void> generateReport() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final _isFarmer = userProvider.isFarmer;
    final _farmerId = userProvider.farmer?.id;
    setState(() => isLoading = true);

    final data = await ReportGenerator.generateReport(
      context: context,
      reportType: reportType,
      dateRange: dateRange,
      selectedBarangay: selectedBarangay,
      selectedFarmer: _isFarmer ? _farmerId.toString() : selectedFarmer,
      selectedView: selectedView,
      selectedSector: selectedSector,
      selectedProduct: selectedProduct,
      selectedAssoc: selectedAssoc,
      selectedFarm: selectedFarm,
      selectedCount: selectedCount,
    );

    setState(() {
      reportData = data;
      filteredReportData = data;
      isLoading = false;
      hasGeneratedReport = true; // Mark that a report has been generated
      // Reset the preview key to force rebuild
      _previewKey = UniqueKey();
      // Auto-select all columns if none are selected
      if (selectedColumns.isEmpty && data.isNotEmpty) {
        selectedColumns = data.first.keys.toSet();
      }
    });
  }

  void searchReports(String query) {
    setState(() {
      searchQuery = query;
      filteredReportData = query.isEmpty
          ? reportData
          : reportData.where((report) {
              return report.values.any((value) {
                return value
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase());
              });
            }).toList();
    });
  }

  void handleColumnsChanged(Set<String> newColumns) {
    setState(() => selectedColumns = newColumns);
  }

  void _handleItemsRemoved(List<int> indicesToRemove) {
    if (indicesToRemove.isEmpty) return;

    setState(() {
      // Create a new list to avoid mutating the current state directly
      final newFilteredData =
          List<Map<String, dynamic>>.from(filteredReportData);
      final newReportData = List<Map<String, dynamic>>.from(reportData);

      // Get the items to remove from filtered data
      final itemsToRemove = indicesToRemove
          .map((index) => newFilteredData[index])
          .where((item) => item != null)
          .toList();

      // Remove from both lists
      newFilteredData.removeWhere((item) => itemsToRemove.contains(item));
      newReportData.removeWhere((item) => itemsToRemove.contains(item));

      // Update state with new lists
      filteredReportData = newFilteredData;
      reportData = newReportData;

      // Force a rebuild of the preview
      _previewKey = UniqueKey();
    });

    ToastHelper.showSuccessToast(
        'Removed ${indicesToRemove.length} items', context);
  }

  // Widget for empty state when no report has been generated
  Widget _buildEmptyState() {
    return Card(
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assessment_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 24),
            Text(
              context.translate('No Report Generated'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.8), 
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              context.translate(
                  'Configure your filters above and click "Generate Report" to create your first report.'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                // You can add any specific action here or just show the message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Please configure filters and click Generate Report'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.lightbulb_outline),
              label: Text(context.translate('Get Started')),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for empty results when report was generated but no data found
  Widget _buildNoDataState() {
    return Card(
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.error.withOpacity(0.6),
            ),
            const SizedBox(height: 24),
            Text(
              context.translate('No Data Found'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.8),
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              context.translate('No Record'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      // Reset filters to default
                      dateRange = DateTimeRange(
                        start:
                            DateTime.now().subtract(const Duration(days: 30)),
                        end: DateTime.now(),
                      );
                      selectedBarangay = '';
                      selectedFarmer = '';
                      selectedCount = '';
                      selectedView = '';
                      selectedSector = '';
                      selectedProduct = '';
                      selectedAssoc = '';
                      selectedFarm = '';
                      searchQuery = '';
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(context.translate('Reset Filters')),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: generateReport,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(context.translate('Try Again')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight = screenHeight * 0.7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReportFilterPanel(
          dateRange: dateRange,
          onDateRangeChanged: (newRange) =>
              setState(() => dateRange = newRange),
          selectedBarangay: selectedBarangay,
          selectedView: selectedView,
          onViewChanged: (newValue) => setState(() => selectedView = newValue),
          selectedCount: selectedCount,
          onCountChanged: (newValue) =>
              setState(() => selectedCount = newValue),
          selectedFarmer: selectedFarmer,
          onFarmerChanged: (newValue) =>
              setState(() => selectedFarmer = newValue),
          onBarangayChanged: (newValue) =>
              setState(() => selectedBarangay = newValue),
          selectedSector: selectedSector,
          onSectorChanged: (newValue) =>
              setState(() => selectedSector = newValue),
          selectedProduct: selectedProduct,
          onProductChanged: (newValue) =>
              setState(() => selectedProduct = newValue),
          selectedAssoc: selectedAssoc,
          onAssocChanged: (newValue) =>
              setState(() => selectedAssoc = newValue),
          selectedFarm: selectedFarm,
          onFarmChanged: (newValue) => setState(() => selectedFarm = newValue),
          reportType: reportType,
          onReportTypeChanged: (newValue) {
            setState(() {
              reportType = newValue;
              // Reset all filter values
              dateRange = DateTimeRange(
                start: DateTime.now(),
                end: DateTime.now(),
              );
              selectedBarangay = '';
              selectedFarmer = '';
              selectedCount = '';
              selectedView = '';
              selectedSector = '';
              selectedProduct = '';
              selectedAssoc = '';
              selectedFarm = '';
              // Reset columns and data
              selectedColumns = {};
              reportData = [];
              filteredReportData = [];
              searchQuery = '';
              hasGeneratedReport = false; // Reset the generated flag
              _previewKey = UniqueKey();
            });
          },
          outputFormat: outputFormat,
          onOutputFormatChanged: (newValue) =>
              setState(() => outputFormat = newValue),
          selectedColumns: selectedColumns,
          onColumnsChanged: handleColumnsChanged,
          onGeneratePressed: generateReport,
          isLoading: isLoading,
        ),
        const SizedBox(height: 16),
        // Handle different states
        if (isLoading) ...[
          SizedBox(
            height: availableHeight,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(context.translate('Generating report...')),
                ],
              ),
            ),
          ),
        ] else if (!hasGeneratedReport) ...[
          // Show empty state when no report has been generated
          SizedBox(
            height: availableHeight,
            child: Center(child: _buildEmptyState()),
          ),
        ] else if (reportData.isEmpty) ...[
          // Show no data state when report was generated but returned empty
          SizedBox(
            height: availableHeight,
            child: Center(child: _buildNoDataState()),
          ),
        ] else ...[
          // Show the actual report
          SizedBox(
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ReportGenerator.buildReportTitle(
                              reportType, dateRange),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          'Generated on ${DateTime.now().toLocal().toString().split('.')[0]}',
                          // style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        hintText: context.translate('Search...'),
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: searchReports,
                    ),
                    if (searchQuery.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Search results: ${filteredReportData.length} of ${reportData.length}',
                            // style: Theme.of(context).textTheme.bodySmall,
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.clear, size: 16),
                            label: const Text('Clear Search'),
                            onPressed: () => searchReports(''),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: availableHeight,
            child: SingleChildScrollView(
              child: ReportPreview(
                key: _previewKey, // Use the key to force rebuild
                reportData: filteredReportData,
                reportType: reportType,
                outputFormat: outputFormat,
                selectedColumns: selectedColumns,
                isLoading: isLoading,
                dateRange: dateRange,
                selectedBarangay: selectedBarangay,
                selectedSector: selectedSector,
                selectedAssoc: selectedAssoc,
                selectedProductType: selectedProduct,
                selectedFarmer: selectedFarmer,
                //  selectedCount: selectedCount,
                selectedView: selectedView,
                onDeleteSelected: _handleItemsRemoved,
              ),
            ),
          ),
          ReportExportOptions(
            reportType: reportType,
            reportData: filteredReportData,
            selectedColumns: selectedColumns,
            dateRange: dateRange,
            context: context,
          ),
        ],
      ],
    );
  }
}
