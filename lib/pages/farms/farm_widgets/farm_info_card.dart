import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/pages/farmers/farmer/farmer_bloc.dart';
import 'package:flareline/pages/test/map_widget/stored_polygons.dart';
import 'package:flareline/pages/widget/combo_box.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flareline_uikit/components/forms/outborder_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class FarmInfoCard extends StatefulWidget {
  final Map<String, dynamic> farm;
  final Function(Map<String, dynamic>) onSave;

  const FarmInfoCard({
    super.key,
    required this.farm,
    required this.onSave,
  });

  @override
  State<FarmInfoCard> createState() => _FarmInfoCardState();
}

class _FarmInfoCardState extends State<FarmInfoCard> {
  late Map<String, dynamic> _editedFarm;
  bool _hasChanges = false;
  bool _isEditing = false;
  final List<String> _sectors = [
    'HVC',
    'Livestock',
    'Corn',
    'Fishery',
    'Organic',
    'Rice'
  ];
  late List<String> barangayNames = [];
  List<dynamic> _farmers = [];

  @override
  void initState() {
    super.initState();
    _editedFarm = Map<String, dynamic>.from(widget.farm);
    _editedFarm['sector'] =
        _editedFarm['sector']?.toString() ?? 'Mixed Farming';
    _editedFarm['status'] = _editedFarm['status']?.toString() ?? 'Active';

    context.read<FarmerBloc>().add(LoadFarmers());

    _editedFarm['products'] = (_editedFarm['products'] as List?)
            ?.map((p) => p is Map ? p['name'].toString() : p.toString())
            .toList() ??
        [];

    barangayNames = barangays.map((b) => b['name'] as String).toList();
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing && _hasChanges) {
        _saveChanges();
      }
    });
  }

  void _handleFieldChange(String field, dynamic value) {
    setState(() {
      _editedFarm[field] = value;
      _hasChanges = true;
    });
  }

  void _saveChanges() {
    final selectedFarmer = _farmers.firstWhere(
      (farmer) => farmer['name'] == _editedFarm['farmOwner'],
      orElse: () => {'id': '', 'name': ''},
    );

    int getSectorId(String? sector) {
      if (sector == null) return 0;
      switch (sector) {
        case 'Rice':
          return 1;
        case 'Corn':
          return 2;
        case 'HVC':
          return 3;
        case 'Livestock':
          return 4;
        case 'Fishery':
          return 5;
        case 'Organic':
          return 6;
        default:
          return 0;
      }
    }

    // Add debug logging
    print('Before getSectorId - sector: ${_editedFarm['sector']}');
    final sectorId = getSectorId(_editedFarm['sector']?.toString());
    print('After getSectorId - sectorId: $sectorId');

    final saveData = {
      'farmName': _editedFarm['farmName'] ?? '',
      'farmerId': selectedFarmer['id'] ?? '',
      'sectorId': sectorId,
      'products': _editedFarm['products'] ?? [],
      'barangayName': _editedFarm['barangay'] ?? '',
      'status': _editedFarm['status'] ?? 'Active',
    };

    print('Saved farm data: $saveData');
    widget.onSave(saveData);

    setState(() {
      _hasChanges = false;
    });
  }

  String _getProductDisplayName(dynamic product) {
    if (product == null) return '';
    if (product is String && product.contains(':')) {
      return product.split(':').last.trim();
    } else if (product is Map) {
      return product['name']?.toString() ?? '';
    }
    return product.toString();
  }

  bool get isMobile {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.width < 600; // Common breakpoint for mobile
  }

  Widget _buildStatusField() {
    const statusOptions = ['Active', 'Inactive'];
    final userProvider = context.read<UserProvider>();
    final isFarmerUser = userProvider.isFarmer;

    if (_isEditing && !isFarmerUser) {
      // Normal edit mode for non-farmer users (admin, etc.)
      return buildComboBox(
          context: context,
          hint: 'Select Status',
          options: statusOptions,
          selectedValue: _editedFarm['status'] ?? 'Active',
          onSelected: (value) => _handleFieldChange('status', value),
          width: isMobile ? double.infinity : 180,
          height: 38);
    } else if (_isEditing && isFarmerUser) {
      // Locked field for farmer users - show as read-only with lock icon
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              _editedFarm['status'] ?? 'Active',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    } else {
      // Read-only mode (not editing)
      return Text(
        _editedFarm['status'] ?? 'Active',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color:
                  _editedFarm['status'] == 'Active' ? Colors.green : Colors.red,
            ),
      );
    }
  }

  Widget _buildOwnerField() {
    // Use context.read to get the UserProvider
    final userProvider = context.read<UserProvider>();
    final isFarmerUser = userProvider.isFarmer;

    // If user is a farmer and we're in edit mode, show locked field
    if (_isEditing && !isFarmerUser) {
      // Normal edit mode for non-farmer users (admin, etc.)
      return buildComboBox(
          context: context,
          hint: 'Select Farm Owner',
          options: _farmers.map((farmer) => farmer['name'].toString()).toList(),
          selectedValue: _editedFarm['farmOwner'] ?? '',
          onSelected: (value) => _handleFieldChange('farmOwner', value),
          width: isMobile ? double.infinity : 180,
          height: 38);
    } else if (_isEditing && isFarmerUser) {
      // Locked field for farmer users - show as read-only with lock icon
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _editedFarm['farmOwner'] ?? 'Unknown Owner',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                overflow: isMobile ? TextOverflow.ellipsis : null,
              ),
            ),
          ],
        ),
      );
    } else {
      // Read-only mode (not editing)
      return Text(
        _editedFarm['farmOwner'] ?? 'Unknown Owner',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: isMobile ? 12 : null,
            ),
      );
    }
  }

  Widget _buildSectorField() {
    if (_isEditing) {
      return buildComboBox(
          context: context,
          hint: 'Select Sector',
          options: _sectors,
          selectedValue: _editedFarm['sector']?.toString() ?? _sectors.first,
          onSelected: (value) => _handleFieldChange('sector', value),
          width: isMobile ? double.infinity : 180,
          height: 38);
    } else {
      return Text(
        _editedFarm['sector']?.toString() ?? 'Not specified',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: isMobile ? 12 : null,
            ),
      );
    }
  }

  Widget _buildLocationField() {
    if (_isEditing) {
      return buildComboBox(
          context: context,
          hint: 'Select Barangay',
          options: barangayNames,
          selectedValue: _editedFarm['barangay'] ?? '',
          onSelected: (value) => _handleFieldChange('barangay', value),
          width: isMobile ? double.infinity : 180,
          height: 38);
    } else {
      return Text(
        '${_editedFarm['barangay'] ?? ''}',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: isMobile ? 12 : null,
            ),
      );
    }
  }

  Widget _buildFarmNameField() {
    if (_isEditing) {
      return SizedBox(
        width: double.infinity,
        child: OutBorderTextFormField(
          initialValue: _editedFarm['farmName'] ?? '',
          hintText: 'Enter farm name',
          height: 38,
          textStyle: Theme.of(context).textTheme.bodyMedium,
          onFieldSubmitted: (value) => _handleFieldChange('farmName', value),
          onChanged: (value) =>
              _handleFieldChange('farmName', value), // Add this line
        ),
      );
    } else {
      return Text(
        _editedFarm['farmName'] ?? '',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: isMobile ? 12 : null,
            ),
      );
    }
  }

  // Helper method to build card-style fields for mobile
  Widget _buildMobileFieldCard({
    required IconData icon,
    required String label,
    required Widget content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? GlobalColors.darkerCardColor
            : GlobalColors.surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 4),
                content,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build card-style fields for desktop edit mode
  Widget _buildDesktopEditCard({
    required IconData icon,
    required String label,
    required Widget content,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 200),
      child: IntrinsicWidth(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? GlobalColors.darkerCardColor
                : GlobalColors.surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 8),
                child: Icon(
                  icon,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  content,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return BlocListener<FarmerBloc, FarmerState>(
      listener: (context, state) {
        if (state is FarmersLoaded) {
          setState(() {
            _farmers = state.farmers
                .map((farmer) => {
                      'id': farmer.id,
                      'name': farmer.name,
                    })
                .toList();
          });
        }
      },
      child: Stack(
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section with farm name and avatar
                  isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment
                                  .center, // Changed from start to center
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundColor:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? GlobalColors.darkerCardColor
                                          : GlobalColors.surfaceColor,
                                  child: Icon(
                                    Icons.agriculture,
                                    size: 32,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment
                                        .center, // Added this line
                                    children: [
                                      Text(
                                        'Farm Details',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Mobile: Use card-style fields for all form elements
                            if (_isEditing) ...[
                              _buildMobileFieldCard(
                                icon: Icons.agriculture,
                                label: 'Farm Name',
                                content: _buildFarmNameField(),
                              ),
                              _buildMobileFieldCard(
                                icon: Icons.person,
                                label: 'Farm Owner',
                                content: _buildOwnerField(),
                              ),
                              _buildMobileFieldCard(
                                icon: Icons.info,
                                label: 'Status',
                                content: _buildStatusField(),
                              ),
                            ] else ...[
                              // Read-only mode - show farm name prominently
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? GlobalColors.darkerCardColor
                                      : GlobalColors.surfaceColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Farm Name',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _editedFarm['farmName'] ?? '',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!_isEditing) ...[
                              CircleAvatar(
                                radius: 48,
                                backgroundColor: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? GlobalColors.darkerCardColor
                                    : GlobalColors.surfaceColor,
                                child: Icon(
                                  Icons.agriculture,
                                  size: 40,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                              ),
                            ],
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Always show farm name in read-only style when not editing
                                  if (!_isEditing) ...[
                                    TextFormField(
                                      initialValue:
                                          _editedFarm['farmName'] ?? '',
                                      // style: Theme.of(context)
                                      //     .textTheme
                                      //     .headlineSmall
                                      //     ?.copyWith(),

                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),

                                      // style: Theme.of(context)
                                      //     .textTheme
                                      //     .bodyMedium
                                      //     ?.copyWith(
                                      //       color: Colors.grey[600],
                                      //     ),

                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      readOnly: true,
                                    ),
                                    const SizedBox(height: 4),
                                    _buildOwnerField(),
                                    const SizedBox(height: 4),
                                    _buildStatusField(),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),

                  // const Divider(height: 32),

                  // Info sections - different layout for mobile vs desktop
                  isMobile
                      ? Column(
                          children: [
                            // Mobile: Use card-style fields for all form elements
                            if (!_isEditing) ...[
                              // Only show these in read-only mode if they weren't shown above
                              _buildMobileFieldCard(
                                icon: Icons.person,
                                label: 'Farm Owner',
                                content: _buildOwnerField(),
                              ),
                              _buildMobileFieldCard(
                                icon: Icons.info,
                                label: 'Status',
                                content: _buildStatusField(),
                              ),
                            ],

                            _buildMobileFieldCard(
                              icon: Icons.business,
                              label: 'Primary Sector',
                              content: _buildSectorField(),
                            ),
                            _buildMobileFieldCard(
                              icon: Icons.location_on,
                              label: 'Location',
                              content: _buildLocationField(),
                            ),
                            if (_editedFarm['farmSize'] != null)
                              _buildMobileFieldCard(
                                icon: Icons.agriculture,
                                label: 'Farm Size',
                                content: Text(
                                  '${_editedFarm['farmSize']} hectares',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                          ],
                        )
                      : Container(
                          width: double.infinity,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              // When editing, show all fields including farm name, owner, and status in the wrap
                              if (_isEditing) ...[
                                // Farm Name
                                _buildDesktopEditCard(
                                  icon: Icons.agriculture,
                                  label: 'Farm Name',
                                  content: SizedBox(
                                    width: 200,
                                    child: OutBorderTextFormField(
                                      initialValue:
                                          _editedFarm['farmName'] ?? '',
                                      hintText: 'Enter farm name',
                                      height: 38,

                                      onChanged: (value) => _handleFieldChange(
                                          'farmName', value), // Add this line
                                    ),
                                  ),
                                ),

                                // Farm Owner
                                _buildDesktopEditCard(
                                  icon: Icons.person,
                                  label: 'Farm Owner',
                                  content: _buildOwnerField(),
                                ),

                                // Status
                                _buildDesktopEditCard(
                                  icon: Icons.info,
                                  label: 'Status',
                                  content: _buildStatusField(),
                                ),
                              ],

                              // Primary Sector
                              _buildDesktopEditCard(
                                icon: Icons.business,
                                label: 'Primary Sector',
                                content: _buildSectorField(),
                              ),

                              // Location
                              _buildDesktopEditCard(
                                icon: Icons.location_on,
                                label: 'Location',
                                content: _buildLocationField(),
                              ),

                              // Farm Size
                              if (_editedFarm['farmSize'] != null)
                                _buildDesktopEditCard(
                                  icon: Icons.agriculture,
                                  label: 'Farm Size',
                                  content: Text(
                                    '${_editedFarm['farmSize']} hectares',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                            ],
                          ),
                        ),

                  const SizedBox(height: 16),

                  // Products section (unchanged)
                  Container(
                    padding: EdgeInsets.all(isMobile ? 8 : 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? GlobalColors.darkerCardColor
                          : GlobalColors.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.inventory,
                              size: isMobile ? 16 : 20,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Products',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isMobile ? 14 : null,
                                  ),
                            ),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_editedFarm['products'].isEmpty)
                          Text(
                            'No products added yet',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: isMobile ? 12 : null,
                            ),
                          )
                        else
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: isMobile ? 100 : 120,
                            ),
                            child: SingleChildScrollView(
                              child: Wrap(
                                spacing: isMobile ? 4 : 8,
                                runSpacing: isMobile ? 4 : 8,
                                children: List.generate(
                                  _editedFarm['products'].length,
                                  (index) => Chip(
                                    backgroundColor:
                                        Theme.of(context).cardTheme.color,
                                    label: Text(
                                      _getProductDisplayName(
                                          _editedFarm['products'][index]),
                                      style: TextStyle(
                                        fontSize: isMobile ? 11 : null,
                                      ),
                                    ),
                                    deleteIcon: Icon(
                                      Icons.close,
                                      size: isMobile ? 14 : 16,
                                    ),
                                    materialTapTargetSize: isMobile
                                        ? MaterialTapTargetSize.shrinkWrap
                                        : MaterialTapTargetSize.padded,
                                    visualDensity: isMobile
                                        ? VisualDensity.compact
                                        : VisualDensity.standard,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: FloatingActionButton.small(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? GlobalColors.darkerCardColor
                  : GlobalColors.surfaceColor,
              onPressed: _toggleEditing,
              child: Icon(
                _isEditing
                    ? (_hasChanges ? Icons.save : Icons.close)
                    : Icons.edit,
                size: isMobile ? 18 : 24,
              ),
              tooltip: _isEditing
                  ? (_hasChanges ? 'Save Changes' : 'Cancel Editing')
                  : 'Edit Farm',
            ),
          ),
        ],
      ),
    );
  }
}
