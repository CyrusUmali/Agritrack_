import 'package:flareline_uikit/service/year_picker_provider.dart';
import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:iconify_flutter_plus/iconify_flutter_plus.dart';
import 'package:iconify_flutter_plus/icons/mdi.dart';
import 'package:flareline/pages/sectors/sector_service.dart';
import 'package:flareline/services/lanugage_extension.dart';

class SectorKpi extends StatefulWidget {
  const SectorKpi({super.key});

  @override
  State<SectorKpi> createState() => _SectorKpiState();
}

class _SectorKpiState extends State<SectorKpi> {
  List<Map<String, dynamic>> _sectors = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSectorData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen for year changes and refresh data
    final yearProvider =
        Provider.of<YearPickerProvider>(context, listen: false);
    yearProvider.addListener(_fetchSectorData);
  }

  @override
  void dispose() {
    // Clean up the listener
    final yearProvider =
        Provider.of<YearPickerProvider>(context, listen: false);
    yearProvider.removeListener(_fetchSectorData);
    super.dispose();
  }

  Future<void> _fetchSectorData() async {
    final sectorService = RepositoryProvider.of<SectorService>(context);
    final yearProvider =
        Provider.of<YearPickerProvider>(context, listen: false);
    final selectedYear = yearProvider.selectedYear;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sectors = await sectorService.fetchSectors(year: selectedYear);
      setState(() {
        _sectors = sectors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Helper method to calculate totals from sectors data
  Map<String, dynamic> _calculateTotals() {
    double totalLandArea = 0;
    int totalFarmers = 0;
    int totalFarms = 0;
    int totalYields = 0;
    double totalYieldVolume = 0;
    double totalYieldValue = 0;

    for (var sector in _sectors) {
      final stats = sector['stats'] as Map<String, dynamic>? ?? {};
      totalLandArea += (stats['totalLandArea'] as num?)?.toDouble() ?? 0;
      totalFarmers += (stats['totalFarmers'] as int?) ?? 0;
      totalFarms += (stats['totalFarms'] as int?) ?? 0;
      totalYields += (stats['totalYields'] as int?) ?? 0;
      totalYieldVolume += (stats['totalYieldVolume'] as num?)?.toDouble() ?? 0;
      totalYieldValue += (stats['totalYieldValue'] as num?)?.toDouble() ?? 0;
    }

    return {
      'totalLandArea': totalLandArea,
      'totalFarmers': totalFarmers,
      'totalFarms': totalFarms,
      'totalYields': totalYields,
      'totalYieldVolume': totalYieldVolume,
      'totalYieldValue': totalYieldValue,
    };
  }

  Widget _buildErrorLayout(
      BuildContext context, String error, VoidCallback onRetry) {
    // Determine the error message based on the error type
    String errorMessage;
    if (error.contains('timeout') || error.contains('network')) {
      errorMessage =
          'Connection failed. Please check your internet connection.';
    } else if (error.contains('server')) {
      errorMessage = 'Server error. Please try again later.';
    } else {
      errorMessage =
          'Failed to load user statistics: ${error.replaceAll(RegExp(r'^Exception: '), '')}';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorLayout(context, _error!, _fetchSectorData);
    }

    final totals = _calculateTotals();

    return ScreenTypeLayout.builder(
      desktop: (context) => _desktopLayout(context, totals),
      mobile: (context) => _mobileLayout(context, totals),
      tablet: (context) => _mobileLayout(context, totals),
    );
  }

  Widget _desktopLayout(BuildContext context, Map<String, dynamic> totals) {
    return Row(
      children: [
        Expanded(
          child: _isLoading
              ? _buildShimmerCard(DeviceScreenType.desktop)
              : _buildSectorCard(
                  context,
                  const Iconify(Mdi.account_group, color: Colors.deepPurple),
                  '${totals['totalFarmers'] ?? '0'}',
                  context.translate('Farmers'),
                  DeviceScreenType.desktop,
                  Colors.deepPurple[50]!,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _isLoading
              ? _buildShimmerCard(DeviceScreenType.desktop)
              : _buildSectorCard(
                  context,
                  const Iconify(Mdi.domain, color: Colors.teal),
                  '${_sectors.length}',
                  context.translate('Sectors'),
                  DeviceScreenType.desktop,
                  Colors.teal[50]!,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _isLoading
              ? _buildShimmerCard(DeviceScreenType.desktop)
              : _buildSectorCard(
                  context,
                  const Iconify(Mdi.chart_line, color: Colors.orange),
                  '${totals['totalYieldVolume']?.toStringAsFixed(0) ?? '0'} Kg',
                  context.translate('Total Production'),
                  DeviceScreenType.desktop,
                  Colors.orange[50]!,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _isLoading
              ? _buildShimmerCard(DeviceScreenType.desktop)
              : _buildSectorCard(
                  context,
                  const Iconify(Mdi.map, color: Colors.blue),
                  '${totals['totalLandArea']?.toStringAsFixed(2) ?? '0'} Ha',
                  context.translate('Total Area'),
                  DeviceScreenType.desktop,
                  Colors.blue[50]!,
                ),
        ),
      ],
    );
  }

  Widget _mobileLayout(BuildContext context, Map<String, dynamic> totals) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _isLoading
            ? _buildShimmerCard(DeviceScreenType.mobile)
            : _buildSectorCard(
                context,
                const Iconify(Mdi.account_group, color: Colors.deepPurple),
                '${totals['totalFarmers'] ?? '0'}',
                context.translate('Farmers'),
                DeviceScreenType.mobile,
                Colors.deepPurple[50]!,
              ),
        _isLoading
            ? _buildShimmerCard(DeviceScreenType.mobile)
            : _buildSectorCard(
                context,
                const Iconify(Mdi.domain, color: Colors.teal),
                '${_sectors.length}',
                context.translate('Sectors'),
                DeviceScreenType.mobile,
                Colors.teal[50]!,
              ),
        _isLoading
            ? _buildShimmerCard(DeviceScreenType.mobile)
            : _buildSectorCard(
                context,
                const Iconify(Mdi.chart_line, color: Colors.orange),
                '${totals['totalYieldVolume']?.toStringAsFixed(0) ?? '0'} Kg',
                context.translate('Total Production'),
                DeviceScreenType.mobile,
                Colors.orange[50]!,
              ),
        _isLoading
            ? _buildShimmerCard(DeviceScreenType.mobile)
            : _buildSectorCard(
                context,
                const Iconify(Mdi.map, color: Colors.blue),
                '${totals['totalLandArea']?.toStringAsFixed(2) ?? '0'} Ha',
                context.translate('Total Area'),
                DeviceScreenType.mobile,
                Colors.blue[50]!,
              ),
      ],
    );
  }

  Widget _buildShimmerCard(DeviceScreenType screenType) {
    final isDesktop = screenType == DeviceScreenType.desktop;

    return CommonCard(
      height: isDesktop ? 100 : 90,
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 16 : 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Shimmer Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              width: 40,
              height: 40,
            ),
            const SizedBox(width: 12),
            // Shimmer Content
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: 100,
                    color: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 20,
                    width: 80,
                    color: Colors.grey.shade200,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectorCard(
    BuildContext context,
    Widget icon,
    String value,
    String title,
    DeviceScreenType screenType,
    Color iconBgColor,
  ) {
    final isDesktop = screenType == DeviceScreenType.desktop;

    return CommonCard(
      height: isDesktop ? 100 : 90,
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 16 : 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon Column
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: icon,
            ),
            const SizedBox(width: 12),

            // Content Column
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: isDesktop ? 16 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: isDesktop ? 18 : 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
