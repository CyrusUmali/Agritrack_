import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/core/models/farms_model.dart';
import 'package:flareline/pages/farms/farm_widgets/recent_records.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flareline_uikit/components/breaktab.dart';
import 'package:flutter/material.dart';
import 'package:flareline/pages/layout.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flareline/pages/farms/farm_widgets/farm_info_card.dart';
import 'package:flareline/pages/farms/farm_widgets/farm_map_card.dart';
import 'package:flareline/pages/farms/farm_widgets/farm_products_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/pages/farms/farm_bloc/farm_bloc.dart';
import 'package:flareline/pages/yields/yield_bloc/yield_bloc.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:toastification/toastification.dart';
import 'package:flareline_uikit/components/charts/circular_chart.dart';
import 'package:flareline/services/lanugage_extension.dart';

class FarmProfile extends LayoutWidget {
  final int farmId;

  const FarmProfile({super.key, required this.farmId});

  @override
  String breakTabTitle(BuildContext context) {
    return context.translate('Farm Profile');
  }

  @override
  List<BreadcrumbItem> breakTabBreadcrumbs(BuildContext context) {
    return [
      BreadcrumbItem(context.translate('Dashboard'), '/'),
      BreadcrumbItem(context.translate('Farms'), '/farms'),
    ];
  }

  @override
  Widget contentDesktopWidget(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => FarmBloc(
            farmRepository: context.read<FarmBloc>().farmRepository,
          )..add(GetFarmById(farmId)),
        ),
        BlocProvider(
          create: (context) => YieldBloc(
            yieldRepository: context.read<YieldBloc>().yieldRepository,
          )..add(GetYieldByFarmId(farmId)),
        )
      ],
      child: const FarmProfileDesktop(),
    );
  }

  @override
  Widget contentMobileWidget(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => FarmBloc(
            farmRepository: context.read<FarmBloc>().farmRepository,
          )..add(GetFarmById(farmId)),
        ),
        BlocProvider(
          create: (context) => YieldBloc(
            yieldRepository: context.read<YieldBloc>().yieldRepository,
          )..add(GetYieldByFarmId(farmId)),
        )
      ],
      child: const FarmProfileMobile(),
    );
  }
}

class FarmProfileDesktop extends StatefulWidget {
  const FarmProfileDesktop({super.key});

  @override
  State<FarmProfileDesktop> createState() => _FarmProfileDesktopState();
}

class _FarmProfileDesktopState extends State<FarmProfileDesktop> {
  int _selectedViewIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocListener<FarmBloc, FarmState>(
      listener: (context, state) {
        if (state is FarmsLoaded && state.message != null) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.flat,
            title: Text(state.message!),
            autoCloseDuration: const Duration(seconds: 5),
          );
        }
        if (state is FarmsError) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            style: ToastificationStyle.flat,
            title: Text(state.message),
            autoCloseDuration: const Duration(seconds: 5),
          );
        }
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final farmState = context.watch<FarmBloc>().state;
    final yieldState = context.watch<YieldBloc>().state;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final _isFarmer = userProvider.isFarmer;
    final _farmerId = userProvider.farmer?.id;

    if (farmState is FarmsLoading || yieldState is YieldsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (farmState is FarmsError) {
      return Center(child: Text('Error loading farm: ${farmState.message}'));
    }

    if (yieldState is YieldsError) {
      return Center(child: Text('Error loading yields: ${yieldState.message}'));
    }
 

    if (farmState is! FarmLoaded || yieldState is! YieldsLoaded) {
      return const Center(child: Text('Unexpected state'));
    }

    final transformedFarm = transformFarmData(farmState, yieldState);
    final hasProducts = transformedFarm['products'] != null &&
        (transformedFarm['products'] as List).isNotEmpty;
    final hasYields = yieldState.yields.isNotEmpty;

 
    // Check if we should show the toggle and content
    final shouldShowToggleAndContent = !_isFarmer ||
        (_isFarmer &&
            yieldState.yields.isNotEmpty &&
            yieldState.yields.first.farmerId == _farmerId);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CommonCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(16),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 7,
                      child: FarmInfoCard(
                        farm: transformedFarm,
                        onSave: (updatedData) {
                          final updatedFarm = Farm(
                              id: farmState.farm.id,
                              name: updatedData['farmName'],
                              sectorId: updatedData['sectorId'],
                              barangay: updatedData['barangayName'],
                              farmerId: updatedData['farmerId'],
                              updatedAt: DateTime.now(),
                              products: updatedData['products'],
                              status: updatedData['status']);
                          context.read<FarmBloc>().add(UpdateFarm(updatedFarm));
                        },
                      ),
                    ),
                    const VerticalDivider(
                      thickness: 1,
                      width: 12,
                      color: Color.fromARGB(255, 186, 185, 185),
                    ),
                    Expanded(
                      flex: 3,
                      child: FarmMapCard(farm: transformedFarm),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Only show toggle and content if conditions are met
            if (shouldShowToggleAndContent) ...[
              // View toggle buttons
              _buildViewToggle(context),
              const SizedBox(height: 16),

              // Content based on selection
              if (_selectedViewIndex == 0) ...[
                RecentRecord(yields: yieldState.yields),
              ] else if (hasProducts || hasYields) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasProducts)
                      Expanded(
                        flex: 7,
                        child: FarmProductsCard(farm: transformedFarm),
                      ),
                    if (hasProducts && hasYields) const SizedBox(width: 24),
                    if (hasYields)
                      Expanded(
                        flex: 3,
                        child: _buildProductDistributionCard(
                          context,
                          transformedFarm['products'],
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggle(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
         color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            context,
            label: context.translate('Recent Records'),
            isSelected: _selectedViewIndex == 0,
            onTap: () => setState(() => _selectedViewIndex = 0),
          ),
          _buildToggleButton(
            context,
            label: context.translate('Products & Distribution'),
            isSelected: _selectedViewIndex == 1,
            onTap: () => setState(() => _selectedViewIndex = 1),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductDistributionCard(
      BuildContext context, List<dynamic> products) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

// First calculate all yields and total sum
    final yields = products.map<double>((product) {
      return (product['yields'] as List)
          .fold<double>(0.0, (sum, yield) => sum + (yield['total'] ?? 0.0));
    }).toList();

    final totalSum = yields.fold<double>(0.0, (sum, yield) => sum + yield);

    final chartData = products.map<Map<String, dynamic>>((product) {
      final productName = product['name'] ?? 'Unknown Product';
      final productYield = (product['yields'] as List)
          .fold<double>(0.0, (sum, yield) => sum + (yield['total'] ?? 0.0));

      // Calculate percentage with 1 decimal precision
      final percentage = totalSum > 0
          ? double.parse((productYield / totalSum * 100).toStringAsFixed(1))
          : 0.0;

      return {
        'x': productName,
        'y': percentage, // Now using percentage instead of absolute value
      };
    }).toList();

    return CommonCard(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 12),
              Text(
                'Product Distribution',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: CircularhartWidget(
              title: '',
              palette: const [
                GlobalColors.warn,
                GlobalColors.secondary,
                GlobalColors.primary,
                GlobalColors.success,
                GlobalColors.danger,
                GlobalColors.dark,
              ],
              chartData: chartData,
              position: LegendPosition.bottom,
              orientation: LegendItemOrientation.horizontal,
              // You might want to add valueFormatter to show percentages in tooltips
              // if your CircularChartWidget supports it
            ),
          ),
        ],
      ),
    );
  }
}

class FarmProfileMobile extends StatefulWidget {
  const FarmProfileMobile({super.key});

  @override
  State<FarmProfileMobile> createState() => _FarmProfileMobileState();
}

class _FarmProfileMobileState extends State<FarmProfileMobile> {
  int _selectedViewIndex =
      0; // 0 for recent records, 1 for products/distribution

  @override
  Widget build(BuildContext context) {
    return BlocListener<FarmBloc, FarmState>(
      listener: (context, state) {
        if (state is FarmsLoaded && state.message != null) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.flat,
            title: Text(state.message!),
            autoCloseDuration: const Duration(seconds: 5),
          );
        }
        if (state is FarmsError) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            style: ToastificationStyle.flat,
            title: Text(state.message),
            autoCloseDuration: const Duration(seconds: 5),
          );
        }
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final farmState = context.watch<FarmBloc>().state;
    final yieldState = context.watch<YieldBloc>().state;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final _isFarmer = userProvider.isFarmer;
    final _farmerId = userProvider.farmer?.id;

    if (farmState is FarmsLoading || yieldState is YieldsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (farmState is FarmsError) {
      return Center(child: Text('Error loading farm: ${farmState.message}'));
    }

    if (yieldState is YieldsError) {
      return Center(child: Text('Error loading yields: ${yieldState.message}'));
    }

    if (farmState is! FarmLoaded || yieldState is! YieldsLoaded) {
      return const Center(child: Text('Unexpected state'));
    }

    final transformedFarm = transformFarmData(farmState, yieldState);
    final hasProducts = transformedFarm['products'] != null &&
        (transformedFarm['products'] as List).isNotEmpty;
    final hasYields = yieldState.yields.isNotEmpty;
    // Check if we should show the toggle and content
    final shouldShowToggleAndContent = !_isFarmer ||
        (_isFarmer &&
            yieldState.yields.isNotEmpty &&
            yieldState.yields.first.farmerId == _farmerId);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FarmMapCard(farm: transformedFarm, isMobile: true),
            const SizedBox(height: 16),
            FarmInfoCard(
              farm: transformedFarm,
              onSave: (updatedData) {
                final updatedFarm = Farm(
                    id: farmState.farm.id,
                    name: updatedData['farmName'],
                    sectorId: updatedData['sectorId'],
                    barangay: updatedData['barangayName'],
                    farmerId: updatedData['farmerId'],
                    updatedAt: DateTime.now(),
                    products: updatedData['products'],
                    status: updatedData['status']);
                context.read<FarmBloc>().add(UpdateFarm(updatedFarm));
              },
            ),
            const SizedBox(height: 16),

// Only show toggle and content if conditions are met
            if (shouldShowToggleAndContent)
              Column(
                children: [
                  // View toggle buttons
                  _buildViewToggle(context),
                  const SizedBox(height: 16),

                  // Content based on selection
                  if (_selectedViewIndex == 0)
                    RecentRecord(yields: yieldState.yields),
                  if (_selectedViewIndex != 0 && (hasProducts || hasYields))
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (hasProducts)
                          FarmProductsCard(farm: transformedFarm),
                        if (hasProducts && hasYields)
                          const SizedBox(height: 16),
                        if (hasYields)
                          _buildProductDistributionCard(
                            context,
                            transformedFarm['products'],
                          ),
                      ],
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggle(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            context,
            label: 'Recent Records',
            isSelected: _selectedViewIndex == 0,
            onTap: () => setState(() => _selectedViewIndex = 0),
          ),
          _buildToggleButton(
            context,
            label: 'Products & Distribution',
            isSelected: _selectedViewIndex == 1,
            onTap: () => setState(() => _selectedViewIndex = 1),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductDistributionCard(
      BuildContext context, List<dynamic> products) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // First calculate all yields and total sum
    final yields = products.map<double>((product) {
      return (product['yields'] as List)
          .fold<double>(0.0, (sum, yield) => sum + (yield['total'] ?? 0.0));
    }).toList();

    final totalSum = yields.fold<double>(0.0, (sum, yield) => sum + yield);

    final chartData = products.map<Map<String, dynamic>>((product) {
      final productName = product['name'] ?? 'Unknown Product';
      final productYield = (product['yields'] as List)
          .fold<double>(0.0, (sum, yield) => sum + (yield['total'] ?? 0.0));

      // Calculate percentage with 1 decimal precision
      final percentage = totalSum > 0
          ? double.parse((productYield / totalSum * 100).toStringAsFixed(1))
          : 0.0;

      return {
        'x': productName,
        'y': percentage, // Now using percentage instead of absolute value
      };
    }).toList();

    return CommonCard(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 12),
              Text(
                'Product Distribution',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: CircularhartWidget(
              title: '',
              palette: const [
                GlobalColors.warn,
                GlobalColors.secondary,
                GlobalColors.primary,
                GlobalColors.success,
                GlobalColors.danger,
                GlobalColors.dark,
              ],
              chartData: chartData,
              position: LegendPosition.bottom,
              orientation: LegendItemOrientation.horizontal,
              // You might want to add valueFormatter to show percentages in tooltips
              // if your CircularChartWidget supports it
            ),
          ),
        ],
      ),
    );
  }
}

Map<String, dynamic> transformFarmData(
    FarmState farmState, YieldState yieldState) {
  // Default/fallback values
  Map<String, dynamic> transformedFarm = {
    'farmName': 'Unknown Farm',
    'farmOwner': 'Unknown Owner',
    'establishedYear': 'Unknown',
    'farmSize': 0.0,
    'sector': 'Unknown',
    'status': 'Unknown',
    'barangay': 'Unknown',
    'municipality': 'Unknown',
    'province': 'Unknown',
    'vertices': '0, 0',
    'products': [],
    'hectare': '8.884',
    'created_at': '2025-06-18T08:09:09.000Z',
    'farmerId': null,
    'sectorId': null,
    'barangayName': null,
  };

  // Transform farm data if loaded
  if (farmState is FarmLoaded) {
    transformedFarm = {
      'farmName': farmState.farm.name ?? 'Unknown Farm',
      'farmOwner': farmState.farm.owner ?? 'Unknown Owner',
      'establishedYear': farmState.farm.createdAt?.year.toString() ?? 'Unknown',
      'farmSize': farmState.farm.hectare ?? 0.0,
      'sector': farmState.farm.sector ?? 'Unknown',
      'status': farmState.farm.status ?? 'Unknown',
      'barangay': farmState.farm.barangay ?? 'Unknown',
      'municipality': 'San Pablo',
      'province': 'Laguna',
      'vertices': farmState.farm.vertices ?? '0, 0',
      'products': [],
      'hectare': farmState.farm.hectare ?? 'hectare: 8.884',
      'created_at': farmState.farm.createdAt ?? '2025-06-18T08:09:09.000Z',
      'farmerId': farmState.farm.farmerId,
      'barangayName': farmState.farm.barangay,
    };
  }

  // Transform yield data if loaded
  if (yieldState is YieldsLoaded) {
    final productMap = <String,
        Map<int, Map<int, double>>>{}; // product -> year -> month -> sum

    for (var yield in yieldState.yields) {
      final productName = yield.productName ?? 'Unknown Product';
      final harvestDate = yield.harvestDate ?? DateTime.now();
      final year = harvestDate.year;
      final month = harvestDate.month;
      final volume = yield.volume?.toDouble() ?? 0.0;

      // Initialize product if not exists
      productMap.putIfAbsent(productName, () => {});

      // Initialize year if not exists
      productMap[productName]!.putIfAbsent(year, () => {});

      // Sum volumes by month
      productMap[productName]![year]!.update(
        month,
        (existing) => existing + volume,
        ifAbsent: () => volume,
      );
    }

    // Convert to final structure
    transformedFarm['products'] = productMap.entries.map((productEntry) {
      final yearlyData = productEntry.value.entries.map((yearEntry) {
        // Create monthly array with summed values
        final monthly = List.filled(12, 0.0);
        yearEntry.value.forEach((month, volume) {
          if (month >= 1 && month <= 12) {
            monthly[month - 1] = volume;
          }
        });

        // Calculate year total
        final yearTotal =
            yearEntry.value.values.fold(0.0, (sum, volume) => sum + volume);

        return {
          'year': yearEntry.key,
          'total': yearTotal,
          'monthly': monthly,
        };
      }).toList();

      return {
        'name': productEntry.key,
        'yields': yearlyData,
      };
    }).toList();
  }

  return transformedFarm;
}

////////
