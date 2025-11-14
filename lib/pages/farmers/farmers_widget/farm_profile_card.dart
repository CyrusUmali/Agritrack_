import 'package:flareline/pages/test/map_widget/farm_service.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import './section_header.dart';
import './detail_field.dart';
import '../../farms/farm_widgets/farm_map_card.dart';
import 'package:flareline/pages/farms/farm_profile.dart';

class FarmProfileCard extends StatefulWidget {
  final Map<String, dynamic> farmer;
  final bool isMobile;
  final int selectedFarmIndex;
  final Function(int)? onFarmSelected;

  const FarmProfileCard({
    super.key,
    required this.farmer,
    this.isMobile = false,
    this.selectedFarmIndex = 0,
    this.onFarmSelected,
  });

  @override
  State<FarmProfileCard> createState() => _FarmProfileCardState();
}

class _FarmProfileCardState extends State<FarmProfileCard> {
  List<dynamic> _farms = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchFarms();
  }

  Future<void> _fetchFarms() async {
    try {
      final farmService = RepositoryProvider.of<FarmService>(context);
      final farmerFarms = await farmService.fetchFarmsByFarmerId(
        widget.farmer['id'].toString(),
      );

      if (mounted) {
        setState(() {
          _farms = farmerFarms;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final farms = _farms;
    final currentFarm =
        farms.isNotEmpty ? farms[widget.selectedFarmIndex] : null;
    final hasMultipleFarms = farms.length > 1;

    return CommonCard(
      padding: EdgeInsets.all(widget.isMobile ? 12 : 16),
      child: Padding(
        padding: EdgeInsets.all(widget.isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SectionHeader(
                    title: 'Farm Profile', icon: Icons.agriculture),
                if (currentFarm != null)
                  IconButton(
                    icon: const Icon(Icons.open_in_new, size: 20),
                    tooltip: 'View full farm details',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              FarmProfile(farmId: currentFarm['id']),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ] else if (_error != null) ...[
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 8),
                    Text('Error loading farms: $_error'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _fetchFarms,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ] else if (farms.isEmpty) ...[
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.agriculture_outlined,
                        size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('No farms found for this farmer'),
                  ],
                ),
              ),
            ] else ...[
              if (hasMultipleFarms) ...[
                _FarmSelector(
                  farms: farms,
                  selectedIndex: widget.selectedFarmIndex,
                  onSelected: (index) {
                    if (widget.onFarmSelected != null) {
                      widget.onFarmSelected!(index);
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
              if (currentFarm != null) ...[
                _FarmDetails(farm: currentFarm),
                const SizedBox(height: 16),
                const SectionHeader(title: 'Farm Location', icon: Icons.map),
                const SizedBox(height: 16),
                FarmMapCard(
                  key: ValueKey(currentFarm['id']), // Add this line
                  farm: _prepareFarmDataForMap(currentFarm),
                  isMobile: widget.isMobile,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // Helper method to prepare farm data for the map widget
  Map<String, dynamic> _prepareFarmDataForMap(Map<String, dynamic> farm) {
    // Convert vertices to the format expected by FarmMapCard
    final vertices = farm['vertices'] as List<dynamic>?;
    final preparedVertices = vertices?.map((vertex) {
      return {
        'latitude': vertex['lat'] ?? 0.0,
        'longitude': vertex['lng'] ?? 0.0,
      };
    }).toList();

    return {
      ...farm,
      'vertices': preparedVertices ?? [],
      'hectare': farm['area'] ?? 0.0,
      'sector': farm['sectorName'] ?? '',
    };
  }
}

class _FarmSelector extends StatelessWidget {
  final List<dynamic> farms;
  final int selectedIndex;
  final Function(int)? onSelected;

  const _FarmSelector({
    required this.farms,
    required this.selectedIndex,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Farm:',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: List.generate(farms.length, (index) {
              final farm = farms[index];
              final isSelected = index == selectedIndex;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Material(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () {
                        onSelected?.call(index);
                        HapticFeedback.lightImpact();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 8),
                        child: Column(
                          children: [
                            Text(
                              farm['name']?.toString() ?? 'Farm ${index + 1}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer
                                        : null,
                                  ),
                            ),
                            Text(
                              farm['sectorName']?.toString() ?? 'No sector',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: isSelected
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer
                                        : null,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _FarmDetails extends StatelessWidget {
  final Map<String, dynamic> farm;

  const _FarmDetails({required this.farm});

  String _getAreaString() {
    if (farm['area'] != null) {
      return '${farm['area']} hectares';
    }
    return 'Not specified';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DetailField(
                  label: 'Farm Name',
                  value: farm['name']?.toString() ?? 'Unnamed Farm'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DetailField(
                  label: 'Sector',
                  value: farm['sectorName']?.toString() ?? 'Not specified'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DetailField(
                  label: 'Barangay',
                  value: farm['parentBarangay']?.toString() ?? 'Not specified'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DetailField(label: 'Area', value: _getAreaString()),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (farm['description'] != null) ...[
          DetailField(
            label: 'Description',
            value: farm['description'].toString(),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
