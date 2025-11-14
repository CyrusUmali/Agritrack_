import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:flareline/pages/test/map_widget/polygon_manager.dart';
import 'package:flareline/pages/test/map_widget/pin_style.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flareline/core/models/farmer_model.dart';
import 'package:provider/provider.dart';
import 'package:flareline/services/lanugage_extension.dart';
import 'package:flareline/pages/farmers/farmer/farmer_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FarmCreationModal {
  static Future<bool> show({
    required BuildContext context,
    required PolygonData polygon,
    required Function(String) onNameChanged,
    required Function(PinStyle) onPinStyleChanged,
    required List<Farmer> farmers,
    required Function(int?, String?) onFarmerChanged,
  }) async {
    final theme = Theme.of(context);
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    if (isLargeScreen) {
      return await _showLargeScreenModal(
        context: context,
        polygon: polygon,
        onNameChanged: onNameChanged,
        onPinStyleChanged: onPinStyleChanged,
        farmers: farmers,
        onFarmerChanged: onFarmerChanged,
        theme: theme,
      );
    } else {
      return await _showSmallScreenModal(
        context: context,
        polygon: polygon,
        onNameChanged: onNameChanged,
        onPinStyleChanged: onPinStyleChanged,
        farmers: farmers,
        onFarmerChanged: onFarmerChanged,
        theme: theme,
      );
    }
  }

  static Future<bool> _showLargeScreenModal({
    required BuildContext context,
    required PolygonData polygon,
    required Function(String) onNameChanged,
    required Function(PinStyle) onPinStyleChanged,
    required List<Farmer> farmers,
    required Function(int?, String?) onFarmerChanged,
    required ThemeData theme,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return _LargeScreenDialog(
              polygon: polygon,
              onNameChanged: onNameChanged,
              onFarmerChanged: onFarmerChanged,
              initialFarmers: farmers,
              theme: theme,
            );
          },
        ) ??
        false;
  }

  static Future<bool> _showSmallScreenModal({
    required BuildContext context,
    required PolygonData polygon,
    required Function(String) onNameChanged,
    required Function(PinStyle) onPinStyleChanged,
    required List<Farmer> farmers,
    required Function(int?, String?) onFarmerChanged,
    required ThemeData theme,
  }) async {
    final validationNotifier = ValueNotifier<bool>(false);

    return await WoltModalSheet.show(
      context: context,
      pageListBuilder: (modalContext) {
        return [
          WoltModalSheetPage(
            backgroundColor: Theme.of(context).cardTheme.color,
            hasSabGradient: false,
            topBar: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.translate('Create New Farm'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 24, color: Colors.black54),
                    onPressed: () => Navigator.of(modalContext).pop(false),
                  ),
                ],
              ),
            ),
            isTopBarLayerAlwaysVisible: true,
            child: _ModalContent(
              polygon: polygon,
              initialFarmers: farmers,
              onNameChanged: onNameChanged,
              onFarmerChanged: onFarmerChanged,
              validationNotifier: validationNotifier,
            ),
            stickyActionBar: _StickyActionBar(
              modalContext: modalContext,
              onNameChanged: onNameChanged,
              validationNotifier: validationNotifier,
            ),
          )
        ];
      },
      modalTypeBuilder: (context) => WoltModalType.bottomSheet(),
      onModalDismissedWithBarrierTap: () => Navigator.of(context).pop(false),
    );
  }
}

// New stateful widget for large screen dialog
class _LargeScreenDialog extends StatefulWidget {
  final PolygonData polygon;
  final Function(String) onNameChanged;
  final Function(int?, String?) onFarmerChanged;
  final List<Farmer> initialFarmers;
  final ThemeData theme;

  const _LargeScreenDialog({
    required this.polygon,
    required this.onNameChanged,
    required this.onFarmerChanged,
    required this.initialFarmers,
    required this.theme,
  });

  @override
  State<_LargeScreenDialog> createState() => _LargeScreenDialogState();
}

class _LargeScreenDialogState extends State<_LargeScreenDialog> {
  late TextEditingController nameController;
  late TextEditingController farmerTextController;
  late UserProvider userProvider;
  late List<Farmer> _currentFarmers;
  late PinStyle selectedPinStyle;

  int? selectedFarmerId;
  String? selectedFarmerName;
  bool isFarmerValid = false;
  bool isNameValid = false;
  bool isLoadingFarmers = false;

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProvider>(context, listen: false);
    nameController = TextEditingController(text: widget.polygon.name);
    farmerTextController = TextEditingController();
    _currentFarmers = widget.initialFarmers;
    selectedPinStyle = widget.polygon.pinStyle;
    isNameValid = widget.polygon.name.isNotEmpty;

    // Auto-select farmer if user is a farmer
    if (userProvider.isFarmer && userProvider.farmer != null) {
      selectedFarmerId = userProvider.farmer!.id;
      selectedFarmerName = userProvider.farmer!.name;
      isFarmerValid = true;
      widget.onFarmerChanged(selectedFarmerId, selectedFarmerName);
    } else {
      // Use existing polygon owner if available
      selectedFarmerId = widget.polygon.owner != null
          ? int.tryParse(widget.polygon.owner!)
          : null;
      isFarmerValid = selectedFarmerId != null;

      // Find initial farmer name if ID exists
      if (selectedFarmerId != null) {
        final farmer = _currentFarmers.firstWhere(
          (f) => f.id == selectedFarmerId,
          orElse: () => Farmer(id: -1, name: 'Unknown', sector: ''),
        );
        selectedFarmerName = farmer.name;
        farmerTextController.text = selectedFarmerName ?? '';
      }
    }

    print(
        'LargeScreenDialog initialized with ${_currentFarmers.length} farmers');
  }

  void _retryLoadFarmers() {
    print('Retry Load Farmers button pressed in large screen dialog');
    setState(() {
      isLoadingFarmers = true;
    });

    try {
      context.read<FarmerBloc>().add(LoadFarmers());
      print('LoadFarmers event dispatched from large screen dialog');
    } catch (e) {
      print('Error loading farmers in large screen dialog: $e');
      setState(() {
        isLoadingFarmers = false;
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    farmerTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FarmerBloc, FarmerState>(
      listener: (context, state) {
        print('FarmerBloc state changed in large dialog: $state');
        if (state is FarmersLoaded) {
          print(
              'Farmers loaded in large dialog: ${state.farmers.length} farmers');
          setState(() {
            _currentFarmers = state.farmers;
            isLoadingFarmers = false;

            // Re-validate farmer selection
            if (_currentFarmers.isNotEmpty && selectedFarmerId != null) {
              final farmerExists =
                  _currentFarmers.any((f) => f.id == selectedFarmerId);
              if (!farmerExists) {
                selectedFarmerId = null;
                selectedFarmerName = null;
                isFarmerValid = false;
                farmerTextController.clear();
              }
            }
          });
        } else if (state is FarmersError) {
          print('Error loading farmers in large dialog: ${state.message}');
          setState(() {
            isLoadingFarmers = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load farmers: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is FarmersLoading) {
          setState(() {
            isLoadingFarmers = true;
          });
        }
      },
      child: Dialog(
        insetPadding: const EdgeInsets.all(20),
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.5,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.translate('Create New Farm'),
                    style: widget.theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Farm Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: FlarelineColors.border,
                    ),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? GlobalColors.darkerCardColor
                      : Colors.grey.shade50,
                  errorText: isNameValid
                      ? null
                      : context.translate('Name is required'),
                  errorStyle: const TextStyle(color: Colors.red),
                ),
                onChanged: (value) {
                  setState(() {
                    isNameValid = value.isNotEmpty;
                  });
                  widget.onNameChanged(value);
                },
              ),
              const SizedBox(height: 16),
              // Only show farmer selection if user is not a farmer
              if (!userProvider.isFarmer)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show retry button if farmers list is empty
                    if (_currentFarmers.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.orange.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: Colors.orange.shade600, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No farmers available. Please load farmers to continue.',
                                    style: TextStyle(
                                      color: Colors.orange.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double
                                  .infinity, // This makes the button expand horizontally
                              child: ElevatedButton.icon(
                                onPressed:
                                    isLoadingFarmers ? null : _retryLoadFarmers,
                                icon: isLoadingFarmers
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.refresh,
                                        size: 18, color: Colors.white),
                                label: Text(
                                    isLoadingFarmers ? 'Loading...' : 'Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      _buildFarmerAutocomplete(),
                    if (!isFarmerValid && _currentFarmers.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0, left: 12.0),
                        child: Text(
                          'Please select a farmer',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                )
              else
                // Show selected farmer info for farmer users
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.green.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Farmer: ${userProvider.farmer!.name}',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFarmerValid && isNameValid
                          ? FlarelineColors.primary
                          : Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isFarmerValid && isNameValid
                        ? () {
                            widget.onNameChanged(nameController.text);
                            Navigator.of(context).pop(true);
                          }
                        : null,
                    child: Text(context.translate('Create Farm')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFarmerAutocomplete() {
    final farmerOptions = _currentFarmers.map((farmer) => farmer.name).toList();

    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return farmerOptions;
        }
        return farmerOptions.where((String option) {
          return option
              .toLowerCase()
              .contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        final selectedFarmer =
            _currentFarmers.firstWhere((farmer) => farmer.name == selection);
        setState(() {
          selectedFarmerId = selectedFarmer.id;
          selectedFarmerName = selectedFarmer.name;
          isFarmerValid = true;
        });
        widget.onFarmerChanged(selectedFarmerId, selectedFarmerName);
        farmerTextController.text = selectedFarmerName!;
      },
      fieldViewBuilder: (BuildContext context,
          TextEditingController textEditingController,
          FocusNode focusNode,
          VoidCallback onFieldSubmitted) {
        if (farmerTextController.text != textEditingController.text) {
          textEditingController.text = farmerTextController.text;
        }

        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Farmer',
            hintText: 'Search for a farmer...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: FlarelineColors.border,
              ),
            ),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? GlobalColors.darkerCardColor
                : Colors.grey.shade50,
            errorStyle: const TextStyle(color: Colors.red),
            suffixIcon: textEditingController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      textEditingController.clear();
                      farmerTextController.clear();
                      setState(() {
                        selectedFarmerId = null;
                        selectedFarmerName = null;
                        isFarmerValid = false;
                      });
                      widget.onFarmerChanged(null, null);
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            farmerTextController.text = value;
            if (value.isEmpty) {
              setState(() {
                selectedFarmerId = null;
                selectedFarmerName = null;
                isFarmerValid = false;
              });
              widget.onFarmerChanged(null, null);
            }
          },
        );
      },
      optionsViewBuilder: (BuildContext context,
          AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            color: Theme.of(context).brightness == Brightness.dark
                ? GlobalColors.darkerCardColor
                : Colors.grey.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 200,
                maxWidth: MediaQuery.of(context).size.width * 0.5 - 48,
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return ListTile(
                    title: Text(option),
                    onTap: () {
                      onSelected(option);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ModalContent extends StatefulWidget {
  final PolygonData polygon;
  final List<Farmer> initialFarmers;
  final Function(String) onNameChanged;
  final Function(int?, String?) onFarmerChanged;
  final ValueNotifier<bool> validationNotifier;

  const _ModalContent({
    required this.polygon,
    required this.initialFarmers,
    required this.onNameChanged,
    required this.onFarmerChanged,
    required this.validationNotifier,
  });

  @override
  State<_ModalContent> createState() => _ModalContentState();
}

class _ModalContentState extends State<_ModalContent> {
  late TextEditingController nameController;
  late TextEditingController farmerTextController;
  late UserProvider userProvider;
  List<Farmer> _currentFarmers = [];

  int? selectedFarmerId;
  String? selectedFarmerName;
  bool isFarmerValid = false;
  bool isNameValid = false;
  bool isLoadingFarmers = false;

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProvider>(context, listen: false);
    nameController = TextEditingController(text: widget.polygon.name);
    farmerTextController = TextEditingController();
    _currentFarmers = widget.initialFarmers;

    isNameValid = widget.polygon.name.isNotEmpty;

    // Auto-select farmer if user is a farmer
    if (userProvider.isFarmer && userProvider.farmer != null) {
      selectedFarmerId = userProvider.farmer!.id;
      selectedFarmerName = userProvider.farmer!.name;
      isFarmerValid = true;
      widget.onFarmerChanged(selectedFarmerId, selectedFarmerName);
    } else {
      // Use existing polygon owner if available
      selectedFarmerId = widget.polygon.owner != null
          ? int.tryParse(widget.polygon.owner!)
          : null;
      isFarmerValid = selectedFarmerId != null;

      // Find initial farmer name if ID exists
      if (selectedFarmerId != null) {
        final farmer = _currentFarmers.firstWhere(
          (f) => f.id == selectedFarmerId,
          orElse: () => Farmer(id: -1, name: 'Unknown', sector: ''),
        );
        selectedFarmerName = farmer.name;
        farmerTextController.text = selectedFarmerName ?? '';
      }
    }

    // Update validation state initially
    _updateValidationState();

    print('ModalContent initialized with ${_currentFarmers.length} farmers');
  }

  void _updateValidationState() {
    final isValid = isNameValid && isFarmerValid;
    widget.validationNotifier.value = isValid;
  }

  void _retryLoadFarmers() {
    print('Retry Load Farmers button pressed in small screen modal');
    setState(() {
      isLoadingFarmers = true;
    });

    try {
      context.read<FarmerBloc>().add(LoadFarmers());
      print('LoadFarmers event dispatched from small screen modal');
    } catch (e) {
      print('Error loading farmers in small screen modal: $e');
      setState(() {
        isLoadingFarmers = false;
      });
    }
  }

  void _updateFarmers(List<Farmer> newFarmers) {
    setState(() {
      _currentFarmers = newFarmers;
      isLoadingFarmers = false;
      print('Farmers updated to ${_currentFarmers.length} farmers');

      // Re-validate farmer selection if we have farmers now
      if (_currentFarmers.isNotEmpty && selectedFarmerId != null) {
        // Check if the previously selected farmer still exists
        final farmerExists =
            _currentFarmers.any((f) => f.id == selectedFarmerId);
        if (!farmerExists) {
          selectedFarmerId = null;
          selectedFarmerName = null;
          isFarmerValid = false;
          farmerTextController.clear();
        }
      }
      _updateValidationState();
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    farmerTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FarmerBloc, FarmerState>(
      listener: (context, state) {
        print('FarmerBloc state changed: $state');
        if (state is FarmersLoaded) {
          print('Farmers loaded: ${state.farmers.length} farmers');
          _updateFarmers(state.farmers);
        } else if (state is FarmersError) {
          print('Error loading farmers: ${state.message}');
          setState(() {
            isLoadingFarmers = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load farmers: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is FarmersLoading) {
          setState(() {
            isLoadingFarmers = true;
          });
        }
      },
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    final farmerOptions = _currentFarmers.map((farmer) => farmer.name).toList();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Farm Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey.shade400,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: FlarelineColors.border,
                ),
              ),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? GlobalColors.darkerCardColor
                  : Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              errorText:
                  isNameValid ? null : context.translate('Name is required'),
              errorStyle: const TextStyle(color: Colors.red),
            ),
            onChanged: (value) {
              setState(() {
                isNameValid = value.isNotEmpty;
              });
              widget.onNameChanged(value);
              _updateValidationState();
            },
          ),
          const SizedBox(height: 16),
          // Only show farmer selection if user is not a farmer
          if (!userProvider.isFarmer)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show retry button if farmers list is empty
                if (_currentFarmers.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      border: Border.all(color: Colors.orange.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.orange.shade600, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No farmers available. Please load farmers to continue.',
                                style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                isLoadingFarmers ? null : _retryLoadFarmers,
                            icon: isLoadingFarmers
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.refresh,
                                    size: 18, color: Colors.white),
                            label:
                                Text(isLoadingFarmers ? 'Loading...' : 'Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') {
                        return farmerOptions;
                      }
                      return farmerOptions.where((String option) {
                        return option
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (String selection) {
                      final selectedFarmer = _currentFarmers
                          .firstWhere((farmer) => farmer.name == selection);
                      setState(() {
                        selectedFarmerId = selectedFarmer.id;
                        selectedFarmerName = selectedFarmer.name;
                        isFarmerValid = true;
                      });
                      widget.onFarmerChanged(
                          selectedFarmerId, selectedFarmerName);
                      farmerTextController.text = selectedFarmerName!;
                      _updateValidationState();
                    },
                    fieldViewBuilder: (BuildContext context,
                        TextEditingController textEditingController,
                        FocusNode focusNode,
                        VoidCallback onFieldSubmitted) {
                      if (farmerTextController.text !=
                          textEditingController.text) {
                        textEditingController.text = farmerTextController.text;
                      }

                      return TextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Farmer',
                          hintText: 'Search for a farmer...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: FlarelineColors.border,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          errorStyle: const TextStyle(color: Colors.red),
                          suffixIcon: textEditingController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    textEditingController.clear();
                                    farmerTextController.clear();
                                    setState(() {
                                      selectedFarmerId = null;
                                      selectedFarmerName = null;
                                      isFarmerValid = false;
                                    });
                                    widget.onFarmerChanged(null, null);
                                    _updateValidationState();
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          farmerTextController.text = value;
                          if (value.isEmpty) {
                            setState(() {
                              selectedFarmerId = null;
                              selectedFarmerName = null;
                              isFarmerValid = false;
                            });
                            widget.onFarmerChanged(null, null);
                            _updateValidationState();
                          }
                        },
                      );
                    },
                    optionsViewBuilder: (BuildContext context,
                        AutocompleteOnSelected<String> onSelected,
                        Iterable<String> options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? GlobalColors.darkerCardColor
                              : Colors.grey.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: 200,
                              maxWidth: MediaQuery.of(context).size.width - 32,
                            ),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final String option = options.elementAt(index);
                                return ListTile(
                                  title: Text(option),
                                  onTap: () {
                                    onSelected(option);
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                if (!isFarmerValid && _currentFarmers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, left: 12.0),
                    child: Text(
                      'Please select a farmer',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            )
          else
            // Show selected farmer info for farmer users
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border.all(color: Colors.green.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      color: Colors.green.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Farmer: ${userProvider.farmer!.name}',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

// Separate stateful widget for the sticky action bar
class _StickyActionBar extends StatefulWidget {
  final BuildContext modalContext;
  final Function(String) onNameChanged;
  final ValueNotifier<bool> validationNotifier;

  const _StickyActionBar({
    required this.modalContext,
    required this.onNameChanged,
    required this.validationNotifier,
  });

  @override
  State<_StickyActionBar> createState() => _StickyActionBarState();
}

class _StickyActionBarState extends State<_StickyActionBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          )
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: ValueListenableBuilder<bool>(
        valueListenable: widget.validationNotifier,
        builder: (context, isValid, child) {
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isValid ? FlarelineColors.primary : Colors.grey.shade300,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(double.infinity, 52),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: isValid
                ? () {
                    Navigator.of(widget.modalContext).pop(true);
                  }
                : null,
            child: Text(
              context.translate('Create Farm'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }
}
