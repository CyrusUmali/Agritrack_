import 'package:flareline/pages/test/map_widget/farm_list_panel/barangay_filter_panel.dart';
import 'package:flareline/pages/test/map_widget/pin_style.dart';
import 'package:flareline/pages/test/map_widget/polygon_manager.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FarmListPanel extends StatefulWidget {
  final PolygonManager polygonManager;
  final BarangayManager barangayManager;
  final LakeManager lakeManager;
  final List<String> selectedBarangays;
  final List<String> selectedProducts;
  final bool showExceedingAreaOnly;
  final Function(List<String>) onBarangayFilterChanged;
  final Function(List<String>) onProductFilterChanged;
  final Function(int) onPolygonSelected;
  final Function() onFiltersChanged;

  const FarmListPanel({
    Key? key,
    required this.polygonManager,
    required this.barangayManager,
    required this.lakeManager,
    required this.selectedBarangays,
    required this.selectedProducts,
    required this.showExceedingAreaOnly,
    required this.onBarangayFilterChanged,
    required this.onProductFilterChanged,
    required this.onPolygonSelected,
    required this.onFiltersChanged,
  }) : super(key: key);

  @override
  _FarmListPanelState createState() => _FarmListPanelState();
}

class _FarmListPanelState extends State<FarmListPanel>
    with AutomaticKeepAliveClientMixin {
  String searchQuery = '';
  bool showBarangayFilter = false;

  @override
  bool get wantKeepAlive => true;

  // Cache variables
  List<PolygonData>? _cachedFilteredPolygons;
  List<String>? _lastSelectedBarangays;
  List<String>? _lastSelectedProducts;
  String? _lastSearchQuery;
  Map<String, bool>? _lastFilterOptions;
  Map<String, bool>? _lastUserFilterOptions;
  List<PolygonData>? _lastPolygons;

  @override
  void didUpdateWidget(FarmListPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.polygonManager.polygons != _lastPolygons ||
        widget.selectedBarangays != _lastSelectedBarangays ||
        widget.selectedProducts != _lastSelectedProducts) {
      _cachedFilteredPolygons = null;
    }
  }

  List<PolygonData> get filteredPolygons {
    if (_cachedFilteredPolygons != null &&
        _lastSelectedBarangays == widget.selectedBarangays &&
        _lastSelectedProducts == widget.selectedProducts &&
        _lastSearchQuery == searchQuery &&
        _lastFilterOptions == BarangayFilterPanel.filterOptions &&
        _lastUserFilterOptions == BarangayFilterPanel.userFilterOptions &&
        _lastPolygons == widget.polygonManager.polygons) {
      return _cachedFilteredPolygons!;
    }

    _lastSelectedBarangays = widget.selectedBarangays;
    _lastSelectedProducts = widget.selectedProducts;
    _lastSearchQuery = searchQuery;
    _lastFilterOptions = Map.from(BarangayFilterPanel.filterOptions);
    _lastUserFilterOptions = Map.from(BarangayFilterPanel.userFilterOptions);
    _lastPolygons = widget.polygonManager.polygons;

    List<PolygonData> result = widget.polygonManager.polygons;

    // Get user context
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isFarmer = userProvider.isFarmer;
    final farmerId = userProvider.farmer?.id?.toString();

    // Apply user-based filters first
    if (isFarmer &&
        BarangayFilterPanel.userFilterOptions['showOwnedOnly'] == true) {
      // Show only farms owned by current farmer
      result = result.where((polygon) {
        return polygon.farmerId?.toString() == farmerId;
      }).toList();
    } else if (!isFarmer &&
        BarangayFilterPanel.userFilterOptions['showActiveOnly'] == true) {
      // Show only active farms for non-farmers
      result = result.where((polygon) {
        return polygon.status?.toLowerCase() == 'active' ||
            polygon.status == null;
      }).toList();
    }

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      result = result
          .where((polygon) =>
              polygon.name.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    // Apply farm type filter
    result = result.where((polygon) {
      final pinStyle = polygon.pinStyle.toString().split('.').last;
      final filterKey = pinStyle[0].toUpperCase() + pinStyle.substring(1);
      return BarangayFilterPanel.filterOptions[filterKey] ?? false;
    }).toList();

    // Apply barangay filter
    if (widget.selectedBarangays.isNotEmpty) {
      result = result
          .where((p) => widget.selectedBarangays.contains(p.parentBarangay))
          .toList();
    }

    // Apply product filter
    if (widget.selectedProducts.isNotEmpty) {
      result = result
          .where((p) => widget.selectedProducts
              .any((product) => p.products?.contains(product) ?? false))
          .toList();
    }

    // Apply exceeding area filter
    if (widget.showExceedingAreaOnly) {
      result = result.where((polygon) {
        return widget.polygonManager.polygonExceedsAreaLimit(polygon);
      }).toList();
    }

    _cachedFilteredPolygons = result;
    return result;
  }

  // Updated: Polygon Preview with Pin Icon
  Widget _buildPolygonPreview(PolygonData polygon) {
    final exceedsLimit = widget.polygonManager.polygonExceedsAreaLimit(polygon);
    final color = getPinColor(polygon.pinStyle);

    return Stack(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: color.withOpacity(0.3),
            border: Border.all(
              color: exceedsLimit ? Colors.red : color,
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: getPinIcon(polygon.pinStyle),
          ),
        ),
        if (exceedsLimit)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Icon(
                Icons.square_foot,
                color: Colors.white,
                size: 8,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Needed for AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);

    if (showBarangayFilter) {
      return BarangayFilterPanel(
        barangayManager: widget.barangayManager,
        polygonManager: widget.polygonManager,
        selectedBarangays: widget.selectedBarangays,
        selectedProducts: widget.selectedProducts,
        onFiltersChanged: (barangays, products, farmFilters, userFilters) {
          setState(() {
            widget.onBarangayFilterChanged(barangays);
            widget.onProductFilterChanged(products);
            BarangayFilterPanel.filterOptions = farmFilters;
            BarangayFilterPanel.userFilterOptions = userFilters;
          });
          widget.onFiltersChanged();
        },
        onClose: () => setState(() => showBarangayFilter = false),
      );
    }

    return Container(
      width: 280, // Slightly wider to accommodate the previews
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        border: Border(
          left: BorderSide(
              color: theme.cardTheme.surfaceTintColor ?? Colors.grey,
              width: 2.0),
        ),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search farms...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                  onChanged: (value) => setState(() => searchQuery = value),
                ),
              ),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.tune_sharp,
                    color: (widget.selectedBarangays.isNotEmpty ||
                            widget.selectedProducts.isNotEmpty ||
                            BarangayFilterPanel.filterOptions.values
                                .any((value) => !value) ||
                            _hasActiveUserFilters())
                        ? theme.colorScheme.primary
                        : theme.disabledColor),
                onPressed: () {
                  setState(() => showBarangayFilter = true);
                },
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Text('Farms',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontSize: 20, fontWeight: FontWeight.w400)),
              SizedBox(width: 8),
              if (filteredPolygons.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${filteredPolygons.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: filteredPolygons.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Colors.grey.withOpacity(0.5),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No farms found',
                          style: TextStyle(
                            color: Colors.grey.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Try adjusting your filters',
                          style: TextStyle(
                            color: Colors.grey.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredPolygons.length,
                    itemBuilder: (context, filteredIndex) {
                      final polygon = filteredPolygons[filteredIndex];
                      final originalIndex =
                          widget.polygonManager.polygons.indexOf(polygon);
                      final exceedsLimit = widget.polygonManager
                          .polygonExceedsAreaLimit(polygon);

                      return Container(
                        margin: EdgeInsets.only(bottom: 4),
                        child: ListTile(
                          leading: _buildPolygonPreview(polygon),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  polygon.name,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: exceedsLimit ? Colors.red : null,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (polygon.area != null)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${polygon.area!.toStringAsFixed(1)} ha',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (polygon.parentBarangay != null)
                                Text(
                                  'Barangay: ${polygon.parentBarangay}',
                                  style: TextStyle(fontSize: 12),
                                ),
                              if (polygon.products != null &&
                                  polygon.products!.isNotEmpty)
                                Text(
                                  'Products: ${polygon.products!.join(', ')}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (exceedsLimit)
                                Row(
                                  children: [
                                    Icon(Icons.square_foot,
                                        size: 12, color: Colors.red),
                                    SizedBox(width: 4),
                                    Text(
                                      'Area exceeds limit',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          tileColor:
                              widget.polygonManager.selectedPolygonIndex ==
                                      originalIndex
                                  ? theme.colorScheme.primary.withOpacity(0.2)
                                  : (exceedsLimit
                                      ? Colors.red.withOpacity(0.05)
                                      : null),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onTap: () {
                            final overlayContext =
                                Navigator.of(context, rootNavigator: true)
                                    .context;
                            widget.polygonManager.selectPolygon(originalIndex,
                                context: overlayContext);
                            widget.onPolygonSelected(originalIndex);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Helper method to check if user-based filters are active
  bool _hasActiveUserFilters() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isFarmer = userProvider.isFarmer;

    if (isFarmer) {
      return BarangayFilterPanel.userFilterOptions['showOwnedOnly'] == true;
    } else {
      return BarangayFilterPanel.userFilterOptions['showActiveOnly'] == true;
    }
  }
}
