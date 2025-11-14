import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:iconify_flutter_plus/iconify_flutter_plus.dart';
import 'package:iconify_flutter_plus/icons/mdi.dart';
import 'package:flareline/services/lanugage_extension.dart'; 

import 'package:flareline/pages/sectors/sector_service.dart';

class YieldKpi extends StatefulWidget {
  final int selectedYear; // Add selectedYear as a required parameter
  final int? farmerId;
  const YieldKpi(
      {super.key,
      required this.selectedYear,
      this.farmerId}); // Update constructor

  @override
  State<YieldKpi> createState() => _YieldKpiState();
}

class _YieldKpiState extends State<YieldKpi> {
  Map<String, dynamic>? _yieldStats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchYieldStatistics();
  }

  Future<void> _fetchYieldStatistics() async {
    final sectorService = RepositoryProvider.of<SectorService>(context);

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Pass both selectedYear and farmerId (if available) to fetchYieldStatistics
      final stats = await sectorService.fetchYieldStatistics(
        year: widget.selectedYear,
        farmerId: widget.farmerId,
      );

      setState(() {
        _yieldStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorLayout(context, _error!, _fetchYieldStatistics);
    }

    return ScreenTypeLayout.builder(
      desktop: (context) => _desktopLayout(context),
      mobile: (context) => _mobileLayout(context),
      tablet: (context) => _mobileLayout(context),
    );
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

  Widget _desktopLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _isLoading
              ? _buildShimmerCard(DeviceScreenType.desktop)
              : _buildKpiCard(
                  context,
                  const Iconify(Mdi.weight, color: Colors.deepPurple),
                  '${_yieldStats?['totalYield'] ?? '0'}kg',
                

                  context.translate('Total Yield'),

                 
                              

                  DeviceScreenType.desktop,
                  Colors.deepPurple[50]!,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _isLoading
              ? _buildShimmerCard(DeviceScreenType.desktop)
              : _buildKpiCard(
                  context,
                  const Iconify(Mdi.sack, color: Colors.teal),
                  _yieldStats?['averageYieldPerHectare'] ?? '0 t/ha',
                
                context.translate('Avg. per Hectare'),

                  DeviceScreenType.desktop,
                  Colors.teal[50]!,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _isLoading
              ? _buildShimmerCard(DeviceScreenType.desktop)
              : _buildKpiCard(
                  context,
                  const Iconify(Mdi.rice, color: Colors.orange),
                  '${_yieldStats?['topCrop']?['volume'] ?? '0'} kg ${_yieldStats?['topCrop']?['product'] ?? '-'}',

                  context.translate('Top Crop'),


                  DeviceScreenType.desktop,
                  Colors.orange[50]!,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _isLoading
              ? _buildShimmerCard(DeviceScreenType.desktop)
              : _buildKpiCard(
                  context,
                  const Iconify(Mdi.calendar_check, color: Colors.blue),
                  '${_yieldStats?['thisMonthYield'] ?? '0'}kg',
              
                context.translate('This Month') ,

                  DeviceScreenType.desktop,
                  Colors.blue[50]!,
                ),
        ),
      ],
    );
  }

  Widget _mobileLayout(BuildContext context) {
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
            : _buildKpiCard(
                context,
                const Iconify(Mdi.weight, color: Colors.deepPurple),
                '${_yieldStats?['totalYield'] ?? '0'}kg',
              
                                  context.translate('Total Yield'),

                DeviceScreenType.mobile,
                Colors.deepPurple[50]!,
              ),
        _isLoading
            ? _buildShimmerCard(DeviceScreenType.mobile)
            : _buildKpiCard(
                context,
                const Iconify(Mdi.sack, color: Colors.teal),
                _yieldStats?['averageYieldPerHectare'] ?? '0 t/ha',
              
                context.translate('Avg. per Hectare'),


                DeviceScreenType.mobile,
                Colors.teal[50]!,
              ),
        _isLoading
            ? _buildShimmerCard(DeviceScreenType.mobile)
            : _buildKpiCard(
                context,
                const Iconify(Mdi.rice, color: Colors.orange),
                '${_yieldStats?['topCrop']?['volume'] ?? '0'} kg ${_yieldStats?['topCrop']?['product'] ?? '-'}',
              
                  context.translate('Top Crop'),

                DeviceScreenType.desktop,
                Colors.orange[50]!,
              ),
        _isLoading
            ? _buildShimmerCard(DeviceScreenType.mobile)
            : _buildKpiCard(
                context,
                const Iconify(Mdi.calendar_check, color: Colors.blue),
                '${_yieldStats?['thisMonthYield'] ?? '0'}kg',
              
                context.translate('This Month') 
                
                 ,
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

  Widget _buildKpiCard(
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
                  // Modified this part to handle overflow better
                  SizedBox(
                    width: double.infinity, // Take full available width
                    child: Text(
                      value,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1, // Allow up to 2 lines before ellipsis
                      style: TextStyle(
                        fontSize: isDesktop ? 18 : 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
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
