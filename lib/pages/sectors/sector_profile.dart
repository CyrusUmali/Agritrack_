import 'package:flareline/services/lanugage_extension.dart';
import 'package:flareline_uikit/components/breaktab.dart';
import 'package:flareline/pages/sectors/sector_service.dart';
import 'package:flareline/pages/test/map_widget/map_panel/polygon_modal_components/lake_yield_data_table.dart';

import 'package:flutter/material.dart';
import 'package:flareline/pages/layout.dart';
import 'package:flareline/pages/sectors/sector_profile/sector_header.dart';
import 'package:flareline/pages/sectors/sector_profile/sector_kpi.dart';
import 'package:flareline/pages/sectors/sector_profile/sector_overview.dart';
import 'package:flareline/pages/sectors/sector_profile/sector_yield_data.dart';
import 'package:provider/provider.dart';

class SectorProfile extends LayoutWidget {
  final Map<String, dynamic> sector;

  const SectorProfile({super.key, required this.sector});

  @override
  String breakTabTitle(BuildContext context) {
    return 'Sector Profile';
  }

  @override
  List<BreadcrumbItem> breakTabBreadcrumbs(BuildContext context) {
    return [
      BreadcrumbItem(context.translate('Dashboard'), '/'),
      BreadcrumbItem(context.translate('Sectors'), '/sectors'),
    ];
  }

  @override
  Widget contentDesktopWidget(BuildContext context) {
    return _SectorProfileContent(sector: sector, isMobile: false);
  }

  @override
  Widget contentMobileWidget(BuildContext context) {
    return _SectorProfileContent(sector: sector, isMobile: true);
  }
}

class _SectorProfileContent extends StatefulWidget {
  final Map<String, dynamic> sector;
  final bool isMobile;

  const _SectorProfileContent({
    required this.sector,
    required this.isMobile,
  });

  @override
  State<_SectorProfileContent> createState() => _SectorProfileContentState();
}

class _SectorProfileContentState extends State<_SectorProfileContent> {
  late SectorService _sectorService;
  Map<String, dynamic>? _updatedSector;
  List<Map<String, dynamic>>? _yieldDistribution;
  bool _isLoading = false;
  bool _isLoadingYield = false;
  String? _error;
  String? _yieldError;
  String _selectedLake = 'Sampaloc Lake'; // Default selected lake

  static const List<String> _lakes = [
    'Sampaloc Lake',
    'Bunot Lake',
    'Kalibato Lake',
    'Pandin Lake',
    'Yambo Lake',
    'Mojicap Lake',
    'Palakpakin Lake'
  ];

  @override
  void initState() {
    super.initState();
    _sectorService = Provider.of<SectorService>(context, listen: false);
    _loadSectorData();
    _loadYieldDistribution();
  }

  Future<void> _loadYieldDistribution() async {
    if (widget.sector['id'] == null) return;

    setState(() {
      _isLoadingYield = true;
      _yieldError = null;
    });

    try {
      final distribution = await _sectorService.fetchYieldDistribution(
        sectorId: widget.sector['id'],
        // You could add year here if needed
        // year: 2023,
      );
      setState(() {
        _yieldDistribution = distribution;
        _isLoadingYield = false;
      });
    } catch (e) {
      setState(() {
        _yieldError = e.toString();
        _isLoadingYield = false;
      });
    }
  }

  Future<void> _loadSectorData() async {
    if (widget.sector['id'] == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sector = await _sectorService.fetchSectorDetails(
        sectorId: widget.sector['id'],
      );
      setState(() {
        _updatedSector = sector;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildYieldDataSection() {
    final currentSector = _updatedSector ?? widget.sector;
    final sectorId = currentSector['id'];

    // Check if sector ID is 5 to show lake-specific data
    if (sectorId == 5) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lake Selection Dropdown
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              children: [
                const Text(
                  'Select Lake: ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedLake,
                    underline: const SizedBox(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedLake = newValue;
                        });
                      }
                    },
                    dropdownColor: Theme.of(context).cardTheme.color,
                    items: _lakes.map<DropdownMenuItem<String>>((String lake) {
                      return DropdownMenuItem<String>(
                        value: lake,
                        child: Text(lake),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Lake Yield Data Table with ValueKey to force rebuild
          LakeYieldDataTable(
            key: ValueKey(_selectedLake), // Add this line
            lake: _selectedLake,
          ),
        ],
      );
    } else {
      // Regular Sector Yield Data Table
      return SectorYieldDataTable(
        sectorId: sectorId.toString(),
        sectorName: widget.sector['name'] ?? 'Unknown',
      );
    }
  }

  Widget _buildContent() {
    // Use updated sector data if available, otherwise use initial data
    final currentSector = _updatedSector ?? widget.sector;

    return SingleChildScrollView(
      child: Column(
        children: [
          if (_isLoading)
            const LinearProgressIndicator()
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text('Error: $_error'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _loadSectorData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          SectorHeader(sector: currentSector, isMobile: widget.isMobile),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectorKpiCards(
                    sector: currentSector, isMobile: widget.isMobile),
                const SizedBox(height: 24),

                // Overview Panel and Chart
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IntrinsicHeight(
                        child: Flex(
                          direction:
                              widget.isMobile ? Axis.vertical : Axis.horizontal,
                          children: [
                            // Overview Panel (70%)
                            Flexible(
                              flex: 7,
                              child: SectorOverviewPanel(
                                sector: currentSector,
                                isMobile: widget.isMobile,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.isMobile) const SizedBox(height: 16),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Yield Data Section - Either Lake or Sector based on ID
                _buildYieldDataSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }
}
