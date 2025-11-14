import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:flareline/pages/sectors/sector_service.dart';

class FarmerKpi extends StatefulWidget {
  const FarmerKpi({super.key});

  @override
  State<FarmerKpi> createState() => _FarmerKpiState();
}

class _FarmerKpiState extends State<FarmerKpi> {
  Map<String, dynamic>? _farmerStats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchFarmerStatistics();
  }

  Future<void> _fetchFarmerStatistics() async {
    final sectorService = RepositoryProvider.of<SectorService>(context);

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await sectorService.fetchFarmerStatistics();
      setState(() {
        _farmerStats = stats;
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
      return _buildErrorLayout(context, _error!, _fetchFarmerStatistics);
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
          'Failed to load farmer statistics: ${error.replaceAll(RegExp(r'^Exception: '), '')}';
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
                  Icons.people_outline,
                  '${_farmerStats?['totalFarmers'] ?? '0'}',
                  'Total Farmers',
                  DeviceScreenType.desktop,
                  Colors.blue[50]!,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _isLoading
              ? _buildShimmerCard(DeviceScreenType.desktop)
              : _buildKpiCard(
                  context,
                  Icons.work_outline,
                  '${_farmerStats?['activeFarmers'] ?? '0'}',
                  'Active Farmers',
                  DeviceScreenType.desktop,
                  Colors.green[50]!,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _isLoading
              ? _buildShimmerCard(DeviceScreenType.desktop)
              : _buildKpiCard(
                  context,
                  Icons.person_off_outlined,
                  '${_farmerStats?['unregisteredFarmers'] ?? '0'}',
                  'Unregistered Farmers',
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
                  Icons.how_to_reg,
                  '${_farmerStats?['registeredFarmers'] ?? '0'}',
                  'Registered Farmers',
                  DeviceScreenType.desktop,
                  Colors.purple[50]!,
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
                Icons.people_outline,
                '${_farmerStats?['totalFarmers'] ?? '0'}',
                'Total Farmers',
                DeviceScreenType.mobile,
                Colors.blue[50]!,
              ),
        _isLoading
            ? _buildShimmerCard(DeviceScreenType.mobile)
            : _buildKpiCard(
                context,
                Icons.work_outline,
                '${_farmerStats?['activeFarmers'] ?? '0'}',
                'Active Farmers',
                DeviceScreenType.mobile,
                Colors.green[50]!,
              ),
        _isLoading
            ? _buildShimmerCard(DeviceScreenType.mobile)
            : _buildKpiCard(
                context,
                Icons.person_off_outlined,
                '${_farmerStats?['unregisteredFarmers'] ?? '0'}',
                'Unregistered Farmers',
                DeviceScreenType.mobile,
                Colors.orange[50]!,
              ),
        _isLoading
            ? _buildShimmerCard(DeviceScreenType.mobile)
            : _buildKpiCard(
                context,
                Icons.how_to_reg,
                '${_farmerStats?['registeredFarmers'] ?? '0'}',
                'Registered Farmers',
                DeviceScreenType.mobile,
                Colors.purple[50]!,
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
                  const SizedBox(height: 4),
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
    IconData icon,
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
              child: Icon(icon, color: _getIconColor(iconBgColor)),
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
                  const SizedBox(height: 4),
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

  Color _getIconColor(Color bgColor) {
    if (bgColor == Colors.blue[50]) return Colors.blue;
    if (bgColor == Colors.green[50]) return Colors.green;
    if (bgColor == Colors.orange[50]) return Colors.orange;
    if (bgColor == Colors.purple[50]) return Colors.purple;
    return Colors.black;
  }
}
