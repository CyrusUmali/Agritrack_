import 'package:flareline/components/charts/map_chart.dart';
import 'package:flareline/core/models/farmer_model.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/pages/dashboard/map_widget.dart';
import 'package:flareline/pages/farmers/farmer/farmer_bloc.dart';
import 'package:flareline/pages/sectors/sector_service.dart';
import 'package:flareline/pages/widget/network_error.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flareline_uikit/components/charts/circular_chart.dart';
import 'package:provider/provider.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:flareline/pages/dashboard/climate_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

class AnalyticsWidget extends StatelessWidget {
  final int selectedYear;
  const AnalyticsWidget({super.key, required this.selectedYear});

  @override
  Widget build(BuildContext context) {
    context.read<FarmerBloc>().add(LoadFarmers());

    final userProvider = Provider.of<UserProvider>(context);
    final userRole = userProvider.user?.role;
    final int? farmerId = userProvider.farmer?.id;

    if (userRole == 'farmer' && farmerId != null) {
      return _buildFarmerProductDistribution(context, farmerId);
    }

    return BlocBuilder<FarmerBloc, FarmerState>(
      builder: (context, state) {
        if (state is FarmersLoaded) {
          final sectorData = _processSectorData(state.farmers);
          return _analytics(sectorData);
        } else if (state is FarmersError) {
          return _buildErrorLayout(context, state.message,
              () => context.read<FarmerBloc>().add(LoadFarmers()));
        } else {
          return _buildShimmerPlaceholder();
        }
      },
    );
  }

  Widget _buildFarmerProductDistribution(BuildContext context, int farmerId) {
    final sectorService = RepositoryProvider.of<SectorService>(context);

    return FutureBuilder<Map<String, dynamic>>(
      future: sectorService.getFarmerYieldDistribution(
          farmerId: farmerId.toString(), year: selectedYear),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerPlaceholder();
        } else if (snapshot.hasError) {
          return _buildErrorLayout(context, snapshot.error.toString(),
              () => _buildFarmerProductDistribution(context, farmerId));
        } else if (snapshot.hasData) {
          final data = snapshot.data!;
          if (data['data'] != null && data['data']['products'] != null) {
            final products =
                List<Map<String, dynamic>>.from(data['data']['products']);

            // Handle empty products list
            if (products.isEmpty) {
              return _buildEmptyDataLayout(
                  context,
                  'No product data available for $selectedYear',
                  'Try selecting a different year or check back later.',
                  Icons.inventory_2_outlined,
                  () => _buildFarmerProductDistribution(context, farmerId));
            }

            return _buildProductDistributionChart(products);
          } else {
            return _buildEmptyDataLayout(
                context,
                'No product data available',
                'No products found for the selected year.',
                Icons.inventory_2_outlined,
                () => _buildFarmerProductDistribution(context, farmerId));
          }
        } else {
          return _buildEmptyDataLayout(
              context,
              'No data available',
              'Unable to load product information.',
              Icons.data_usage_outlined,
              () => _buildFarmerProductDistribution(context, farmerId));
        }
      },
    );
  }

  Widget _buildErrorLayout(
      BuildContext context, String error, VoidCallback onRetry) {
    // Wrap the NetworkErrorWidget in a CommonCard
    return CommonCard(
      child: NetworkErrorWidget(
        error: error,
        onRetry: onRetry,
        errorIcon: Icons.error_outline,
        errorColor: Colors.red,
        iconSize: 48,
        fontSize: 16,
        retryButtonText: 'Retry',
        padding: const EdgeInsets.all(32.0),
      ),
    );
  }

  // New method to handle empty data states
  Widget _buildEmptyDataLayout(BuildContext context, String title,
      String subtitle, IconData icon, VoidCallback onRetry) {
    return ScreenTypeLayout.builder(
      desktop: (context) =>
          _buildEmptyStateWeb(context, title, subtitle, icon, onRetry),
      mobile: (context) =>
          _buildEmptyStateMobile(context, title, subtitle, icon, onRetry),
      tablet: (context) =>
          _buildEmptyStateMobile(context, title, subtitle, icon, onRetry),
    );
  }

  Widget _buildEmptyStateWeb(BuildContext context, String title,
      String subtitle, IconData icon, VoidCallback onRetry) {
    return SizedBox(
      height: 280,
      child: Row(
        children: [
          Expanded(
            flex: 40,
            child: CommonCard(
              child: _buildEmptyStateContent(title, subtitle, icon, onRetry),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 35,
            child: CommonCard(
              child: const MapMiniView(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 35,
            child: CommonCard(
              child: const ClimateInfoWidget(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateMobile(BuildContext context, String title,
      String subtitle, IconData icon, VoidCallback onRetry) {
    return Column(
      children: [
        SizedBox(
          height: 350,
          child: CommonCard(
            child: _buildEmptyStateContent(title, subtitle, icon, onRetry),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: CommonCard(
            child: const MapMiniView(),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: CommonCard(
            child: const ClimateInfoWidget(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStateContent(
      String title, String subtitle, IconData icon, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDistributionChart(List<Map<String, dynamic>> products) {
    final chartData = products.map((product) {
      return {
        'x': product['productName'],
        'y': product['percentageOfVolume'],
      };
    }).toList();

    // Additional check to ensure chart data is valid
    final validChartData = chartData
        .where((item) =>
            item['x'] != null &&
            item['x'].toString().isNotEmpty &&
            item['y'] != null &&
            item['y'] is num &&
            item['y'] > 0)
        .toList();

    if (validChartData.isEmpty) {
      return _buildEmptyDataLayout(
          null as BuildContext, // This will be handled by the caller
          'No valid product data',
          'All products have zero or invalid values.',
          Icons.inventory_2_outlined,
          () {});
    }

    return ScreenTypeLayout.builder(
      desktop: (context) => _analyticsWeb(context, validChartData),
      mobile: (context) => _analyticsMobile(context, validChartData),
      tablet: (context) => _analyticsMobile(context, validChartData),
    );
  }

  Widget _buildShimmerPlaceholder() {
    return ScreenTypeLayout.builder(
      desktop: (context) => _shimmerWeb(context),
      mobile: (context) => _shimmerMobile(context),
      tablet: (context) => _shimmerMobile(context),
    );
  }

  Widget _shimmerWeb(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Row(
        children: [
          Expanded(
            flex: 40,
            child: _buildShimmerCard(DeviceScreenType.desktop),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 35,
            child: _buildShimmerCard(DeviceScreenType.desktop),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 35,
            child: _buildShimmerCard(DeviceScreenType.desktop),
          ),
        ],
      ),
    );
  }

  Widget _shimmerMobile(BuildContext context) {
    return Column(
      children: [
        _buildShimmerCard(DeviceScreenType.mobile),
        const SizedBox(height: 16),
        _buildShimmerCard(DeviceScreenType.mobile),
        const SizedBox(height: 16),
        _buildShimmerCard(DeviceScreenType.mobile),
      ],
    );
  }

  Widget _buildShimmerCard(DeviceScreenType screenType) {
    final isDesktop = screenType == DeviceScreenType.desktop;
    final height = isDesktop ? 280 : 200;

    return CommonCard(
      height: height.toDouble(),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 16 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shimmer header
              Container(
                height: 20,
                width: 150,
                color: Colors.grey.shade200,
              ),
              const SizedBox(height: 20),
              // Shimmer content
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _processSectorData(List<Farmer> farmers) {
    // Handle empty farmers list
    if (farmers.isEmpty) {
      return [];
    }

    final sectorCounts = <String, int>{};
    final totalFarmers = farmers.length;

    // Count farmers in each sector
    for (var farmer in farmers) {
      final sector = farmer.sector;
      if (sector.isNotEmpty) {
        sectorCounts[sector] = (sectorCounts[sector] ?? 0) + 1;
      }
    }

    // If no valid sectors found
    if (sectorCounts.isEmpty) {
      return [];
    }

    // Convert counts to percentages and sort by count (descending)
    final sortedSectors = sectorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 5 sectors and group the rest as "Others"
    final topSectors = sortedSectors.take(6).toList();
    final otherCount =
        sortedSectors.skip(6).fold<int>(0, (sum, entry) => sum + entry.value);

    // Prepare chart data with percentages
    final chartData = <Map<String, dynamic>>[];

    // Add top sectors
    for (var entry in topSectors) {
      final percentage = (entry.value / totalFarmers * 100).round();
      if (percentage > 0) {
        chartData.add({
          'x': entry.key,
          'y': percentage,
        });
      }
    }

    // Add "Others" if needed
    if (otherCount > 0) {
      final othersPercentage = (otherCount / totalFarmers * 100).round();
      if (othersPercentage > 0) {
        chartData.add({
          'x': 'Others',
          'y': othersPercentage,
        });
      }
    }

    // Ensure total is exactly 100% by adjusting the last item
    if (chartData.isNotEmpty) {
      final total =
          chartData.fold<int>(0, (sum, item) => sum + (item['y'] as int));
      if (total != 100 && total > 0) {
        chartData.last['y'] = (chartData.last['y'] as int) + (100 - total);
      }
    }

    return chartData;
  }

  Widget _analytics(List<Map<String, dynamic>> sectorData) {
    // Handle empty sector data
    if (sectorData.isEmpty) {
      return _buildEmptyDataLayout(
          null as BuildContext, // Context will be provided by the builder
          'No farmer data available',
          'No farmers are currently registered in the system.',
          Icons.people_outline,
          () {} // Empty callback, will be handled by parent
          );
    }

    return ScreenTypeLayout.builder(
      desktop: (context) => _analyticsWeb(context, sectorData),
      mobile: (context) => _analyticsMobile(context, sectorData),
      tablet: (context) => _analyticsMobile(context, sectorData),
    );
  }

  Widget _analyticsWeb(
      BuildContext context, List<Map<String, dynamic>> sectorData) {
    final userProvider = Provider.of<UserProvider>(context);
    final userRole = userProvider.user?.role;
    final bool isFarmer = userRole == 'farmer';

    return SizedBox(
      height: 280,
      child: Row(
        children: [
          Expanded(
            flex: 40,
            child: CommonCard(
              child: sectorData.isNotEmpty
                  ? CircularhartWidget(
                      title: isFarmer
                          ? 'Product Distribution (%)'
                          : 'Farmer Distribution by Sector (%)',
                      palette: const [
                        GlobalColors.warn,
                        GlobalColors.secondary,
                        GlobalColors.primary,
                        GlobalColors.success,
                        GlobalColors.danger,
                        GlobalColors.dark
                      ],
                      chartData: sectorData,
                    )
                  : _buildEmptyStateContent(
                      'No data to display',
                      isFarmer
                          ? 'No product data available.'
                          : 'Chart data is not available.',
                      Icons.pie_chart_outline,
                      () {}),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 35,
            child: CommonCard(
              child: const MapMiniView(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 35,
            child: CommonCard(
              child: const ClimateInfoWidget(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _analyticsMobile(
      BuildContext context, List<Map<String, dynamic>> sectorData) {
    final userProvider = Provider.of<UserProvider>(context);
    final userRole = userProvider.user?.role;
    final bool isFarmer = userRole == 'farmer';

    return Column(
      children: [
        SizedBox(
          height: 350,
          child: CommonCard(
            child: sectorData.isNotEmpty
                ? CircularhartWidget(
                    title: isFarmer
                        ? 'Product Distribution (%)'
                        : 'Farmer Distribution by Sector (%)',
                    palette: const [
                      GlobalColors.warn,
                      GlobalColors.secondary,
                      GlobalColors.primary,
                      GlobalColors.success,
                      GlobalColors.danger,
                      GlobalColors.dark
                    ],
                    chartData: sectorData,
                  )
                : _buildEmptyStateContent(
                    'No data available',
                    isFarmer
                        ? 'No product data to display.'
                        : 'No farmers are registered yet.',
                    Icons.people_outline,
                    () {}),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: CommonCard(
            child: const MapMiniView(),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: CommonCard(
            child: const ClimateInfoWidget(),
          ),
        ),
      ],
    );
  }
}
