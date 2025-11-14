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

class AssocKpi extends StatefulWidget {
  const AssocKpi({super.key});

  @override
  State<AssocKpi> createState() => _AssocKpiState();
}

class _AssocKpiState extends State<AssocKpi> {
  List<Map<String, dynamic>> _associations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAssocData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final yearProvider =
        Provider.of<YearPickerProvider>(context, listen: false);
    yearProvider.addListener(_fetchAssocData);
  }

  @override
  void dispose() {
    final yearProvider =
        Provider.of<YearPickerProvider>(context, listen: false);
    yearProvider.removeListener(_fetchAssocData);
    super.dispose();
  }

  Future<void> _fetchAssocData() async {
    final sectorService = RepositoryProvider.of<SectorService>(context);
    final yearProvider =
        Provider.of<YearPickerProvider>(context, listen: false);
    final selectedYear = yearProvider.selectedYear;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final associations =
          await sectorService.fetchAssociations(year: selectedYear);
      setState(() {
        _associations = associations;

        // print(associations);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _calculateKpis() {
    int totalMembers = 0;
    int totalActive = 0;
    String topAssocName = 'N/A';
    int topAssocMembers = 0;

    for (var assoc in _associations) {
      totalMembers += assoc['stats']['totalFarmers'] as int? ?? 0;

      // Convert integer to boolean for isActive check
      final isActiveInt = assoc['isActive'] as int? ?? 0;
      if (isActiveInt == 1) {
        // Treat 1 as true, 0 as false
        totalActive++;
      }

      // Check if this is the top association
      // final members = assoc['memberCount'] as int? ?? 0;
      if (totalMembers > topAssocMembers) {
        topAssocMembers = totalMembers;
        topAssocName = assoc['name'] as String? ?? 'N/A';
      }
    }

    return {
      'totalMembers': totalMembers,
      'totalAssociations': _associations.length,
      'topAssocName': topAssocName,
      'topAssocMembers': topAssocMembers,
      'totalActive': totalActive,
    };
  }

  Widget _buildErrorLayout(
      BuildContext context, String error, VoidCallback onRetry) {
    String errorMessage;
    if (error.contains('timeout') || error.contains('network')) {
      errorMessage =
          'Connection failed. Please check your internet connection.';
    } else if (error.contains('server')) {
      errorMessage = 'Server error. Please try again later.';
    } else {
      errorMessage =
          'Failed to load association data: ${error.replaceAll(RegExp(r'^Exception: '), '')}';
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
      return _buildErrorLayout(context, _error!, _fetchAssocData);
    }

    final kpis = _calculateKpis();

    return ScreenTypeLayout.builder(
      desktop: (context) => _desktopLayout(context, kpis),
      mobile: (context) => _mobileLayout(context, kpis),
      tablet: (context) => _mobileLayout(context, kpis),
    );
  }

  Widget _desktopLayout(BuildContext context, Map<String, dynamic> kpis) {
    return Row(
      children: [
        Expanded(
          child: _isLoading
              ? _buildShimmerCard(DeviceScreenType.desktop)
              : _buildAssocCard(
                  context,
                  const Iconify(Mdi.account_group, color: Colors.deepPurple),
                  '${kpis['totalMembers']}',
                  context.translate('Total Members'),
                  DeviceScreenType.desktop,
                  Colors.deepPurple[50]!,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _isLoading
              ? _buildShimmerCard(DeviceScreenType.desktop)
              : _buildAssocCard(
                  context,
                  const Iconify(Mdi.office_building, color: Colors.teal),
                  '${kpis['totalAssociations']}',
                  context.translate('Total Associations'),
                  DeviceScreenType.desktop,
                  Colors.teal[50]!,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _isLoading
              ? _buildShimmerCard(DeviceScreenType.desktop)
              : _buildAssocCard(
                  context,
                  const Iconify(Mdi.crown, color: Colors.amber),
                  kpis['topAssocName'],
                  'Top Association',
                  DeviceScreenType.desktop,
                  Colors.amber[50]!,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _isLoading
              ? _buildShimmerCard(DeviceScreenType.desktop)
              : _buildAssocCard(
                  context,
                  const Iconify(Mdi.check_circle, color: Colors.green),
                  '${kpis['totalAssociations']}',
                  context.translate('Active Associations'),
                  DeviceScreenType.desktop,
                  Colors.green[50]!,
                ),
        ),
      ],
    );
  }

  Widget _mobileLayout(BuildContext context, Map<String, dynamic> kpis) {
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
            : _buildAssocCard(
                context,
                const Iconify(Mdi.account_group, color: Colors.deepPurple),
                '${kpis['totalMembers']}',
                context.translate('Total Members'),
                DeviceScreenType.mobile,
                Colors.deepPurple[50]!,
              ),
        _isLoading
            ? _buildShimmerCard(DeviceScreenType.mobile)
            : _buildAssocCard(
                context,
                const Iconify(Mdi.office_building, color: Colors.teal),
                '${kpis['totalAssociations']}',
                context.translate('Total Associations'),
                DeviceScreenType.mobile,
                Colors.teal[50]!,
              ),
        _isLoading
            ? _buildShimmerCard(DeviceScreenType.mobile)
            : _buildAssocCard(
                context,
                const Iconify(Mdi.crown, color: Colors.amber),
                kpis['topAssocName'],
                'Top',
                DeviceScreenType.mobile,
                Colors.amber[50]!,
              ),
        _isLoading
            ? _buildShimmerCard(DeviceScreenType.mobile)
            : _buildAssocCard(
                context,
                const Iconify(Mdi.check_circle, color: Colors.green),
                '${kpis['totalAssociations']}',
                context.translate('Active'),
                DeviceScreenType.mobile,
                Colors.green[50]!,
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

  Widget _buildAssocCard(
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: icon,
            ),
            const SizedBox(width: 12),
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
