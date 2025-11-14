import 'package:flareline/pages/yields/yield_bloc/yield_bloc.dart';
import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flareline_uikit/components/modal/modal_dialog.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flutter/material.dart';
import 'package:flareline/core/models/yield_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toastification/toastification.dart';
import 'package:flareline/services/lanugage_extension.dart';
import 'yield_profile_utils.dart';
import 'yield_profile_actions.dart';
import 'yield_image_handler.dart';

class YieldProfileForm extends StatefulWidget {
  final Yield yieldData;
  final Function(Yield)? onYieldUpdated; // Add this

  const YieldProfileForm({
    super.key,
    required this.yieldData,
    this.onYieldUpdated, // Add this
  });

  @override
  State<YieldProfileForm> createState() => _YieldProfileFormState();
}

class _YieldProfileFormState extends State<YieldProfileForm> {
  final YieldImageHandler _imageHandler = YieldImageHandler();
  late TextEditingController _areaHarvestedController;
  late TextEditingController _volumeController;
  late TextEditingController _valueController;
  late TextEditingController _notesController;
  DateTime? _selectedHarvestDate;

  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isAccepting = false;
  bool _isRejecting = false;

  // Add these variables to track the current
  String? _currentOperation;

  @override
  void initState() {
    print(widget.yieldData);

    super.initState();
    _imageHandler.existingImages = widget.yieldData.images
            ?.where((img) => img != null)
            .cast<String>()
            .toList() ??
        [];
    _areaHarvestedController = TextEditingController(
        text: widget.yieldData.areaHarvested?.toStringAsFixed(3) ?? '0.00');
    _volumeController = TextEditingController(
        text: widget.yieldData.volume?.toStringAsFixed(2) ?? '0.00');
    _valueController = TextEditingController(
        text: widget.yieldData.value?.toStringAsFixed(2) ?? '0.00');
    _notesController =
        TextEditingController(text: widget.yieldData.notes ?? '');
    _selectedHarvestDate = widget.yieldData.harvestDate;
  }

  @override
  void dispose() {
    _areaHarvestedController.dispose();
    _volumeController.dispose();
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      await _imageHandler.pickImages(
        context: context,
        maxAllowed: 5,
      );
      setState(() {});
    } catch (e) {
      _showToast('Error picking images: ${e.toString()}', isError: true);
    }
  }

  Future<void> _removeImage(int index, bool isExisting) async {
    setState(() {
      _imageHandler.removeImage(index, isExisting);
    });
  }

  Future<void> _selectHarvestDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedHarvestDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedHarvestDate) {
      setState(() {
        _selectedHarvestDate = picked;
      });
    }
  }

  Future<void> _updateYield(String status) async {
    // Prevent multiple simultaneous operations
    if (_isSaving || _isDeleting || _isAccepting || _isRejecting) {
      // print('Operation already in progress, ignoring...');
      return;
    }

    try {
      // Set the appropriate loading state and current operation
      setState(() {
        if (status == 'Accepted') {
          _isAccepting = true;
          _currentOperation = 'accept';
        } else if (status == 'Rejected') {
          _isRejecting = true;
          _currentOperation = 'reject';
        } else {
          _isSaving = true;
          _currentOperation = 'save';
        }
      });

      // print('Starting ${_currentOperation} operation...');

      final newImageUrls = await _imageHandler.uploadImagesToCloudinary();
      final allImages = [..._imageHandler.existingImages, ...newImageUrls];

      final updatedYield = widget.yieldData.copyWith(
        images: allImages,
        areaHarvested: double.tryParse(_areaHarvestedController.text),
        volume: double.tryParse(_volumeController.text),
        value: double.tryParse(_valueController.text),
        notes: _notesController.text,
        harvestDate: _selectedHarvestDate,
        status: status.isNotEmpty ? status : widget.yieldData.status,
      );

      context.read<YieldBloc>().add(UpdateYield(updatedYield));
    } catch (e) {
      // print('Error updating yield: $e');
      _showToast('Error updating yield: ${e.toString()}', isError: true);
      _resetLoadingStates();
    }
  }

  void _resetLoadingStates() {
    setState(() {
      _isSaving = false;
      _isAccepting = false;
      _isRejecting = false;
      _currentOperation = null;
    });
  }

  void _showToast(String message, {bool isError = false}) {
    toastification.show(
      context: context,
      type: isError ? ToastificationType.error : ToastificationType.success,
      style: ToastificationStyle.flat,
      title: Text(message),
      autoCloseDuration: const Duration(seconds: 3),
      alignment: Alignment.topRight,
      animationDuration: const Duration(milliseconds: 300),
      showProgressBar: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final harvestDate = _selectedHarvestDate != null
        ? DateFormat('dd/MM/yyyy').format(_selectedHarvestDate!)
        : widget.yieldData.harvestDate != null
            ? DateFormat('dd/MM/yyyy').format(widget.yieldData.harvestDate!)
            : 'Not specified';

    return BlocListener<YieldBloc, YieldState>(
      listener: (context, state) {
        // print('BlocListener triggered with state: ${state.runtimeType}');

        if (state is YieldUpdated) {
          // print('YieldUpdated received, resetting loading states');
          _resetLoadingStates();
          _showToast('Yield updated successfully', isError: false);

          // Call the callback with the updated yield data
          if (widget.onYieldUpdated != null) {
            final updatedYield = widget.yieldData.copyWith(
              images: [..._imageHandler.existingImages],
              areaHarvested: double.tryParse(_areaHarvestedController.text),
              volume: double.tryParse(_volumeController.text),
              value: double.tryParse(_valueController.text),
              notes: _notesController.text,
              harvestDate: _selectedHarvestDate,
              status:
                  state.yield.status, // Use the status from the updated yield
            );
            widget.onYieldUpdated!(updatedYield);
          }
        } else if (state is YieldsLoaded) {
          if (state.message?.contains('deleted') == true) {
            // print('Yield deleted successfully');
            setState(() => _isDeleting = false);
            _showToast(state.message!, isError: false);
            Navigator.of(context).pushReplacementNamed('/yields');
          } else {
            // Only reset loading states if this is not a delete operation
            if (!_isDeleting) {
              // print(
              //     'YieldsLoaded received, resetting non-delete loading states');
              setState(() {
                _isSaving = false;
                _isAccepting = false;
                _isRejecting = false;
                _currentOperation = null;
              });
            }
          }
        } else if (state is YieldsError) {
          // print('YieldsError received: ${state.message}');
          _resetLoadingStates();
          setState(() => _isDeleting = false);
          _showToast(state.message, isError: true);
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isMobile = constraints.maxWidth < 600;
            double formWidth = isMobile ? double.infinity : 800;
            double spacing = isMobile ? 12.0 : 16.0;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: formWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildSectionTitle(
                        context.translate('Product Information'), context,
                        icon: Icons.shopping_bag),
                    buildResponsiveRow(
                      children: [
                        buildTextField(
                          context.translate('Product Name'),
                          widget.yieldData.productName ?? 'Not specified',
                          isMobile,
                          enabled: false,
                        ),
                        buildTextField(
                          //  "Product Name",
                          // context.translate('Product Sector').

                          context.translate('Product Sector'),
                          widget.yieldData.sector ?? 'Not specified',
                          isMobile,
                          enabled: false,
                        ),
                      ],
                      spacing: spacing,
                      isMobile: isMobile,
                    ),
                    SizedBox(height: spacing),
                    buildSectionTitle(
                        context.translate('Farm Information'), context,
                        icon: Icons.agriculture),
                    buildResponsiveRow(
                      children: [
                        buildTextField(
                          context.translate('Farmer Name'),
                          widget.yieldData.farmerName ?? 'Not specified',
                          isMobile,
                          enabled: false,
                        ),
                        buildTextField(
                          context.translate('Location'),
                          widget.yieldData.barangay ?? 'Not specified',
                          isMobile,
                          enabled: false,
                        ),
                      ],
                      spacing: spacing,
                      isMobile: isMobile,
                    ),
                    SizedBox(height: spacing),
                    buildResponsiveRow(
                      children: [
                        buildTextField(
                          context.translate('Farm Name'),
                          widget.yieldData.farmName ?? 'Not specified',
                          isMobile,
                          enabled: false,
                        ),
                        buildEditableTextField(
                          controller: _areaHarvestedController,
                          label: context.translate('Area harvested (Ha)'),
                          isMobile: isMobile,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          suffixText: 'ha',
                        ),
                      ],
                      spacing: spacing,
                      isMobile: isMobile,
                    ),
                    SizedBox(height: spacing),
                    buildSectionTitle(
                        context.translate('Yield Information'), context,
                        icon: Icons.assessment),
                    buildResponsiveRow(
                      children: [
                        buildEditableTextField(
                          controller: _volumeController,
                          label: context.translate('Yield Amount'),
                          isMobile: isMobile,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          suffixText: 'kg',
                        ),
                        buildDatePickerField(
                          context.translate('Harvest Date'),
                          isMobile,
                          value: harvestDate,
                          enabled: true,
                          onTap: () => _selectHarvestDate(context),
                        ),
                      ],
                      spacing: spacing,
                      isMobile: isMobile,
                    ),
                    SizedBox(height: spacing),
                    buildResponsiveRow(
                      children: [
                        buildEditableTextField(
                          controller: _valueController,
                          label: context.translate('Value in (Php)'),
                          isMobile: isMobile,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          prefixText: '\₱',
                        ),
                      ],
                      spacing: spacing,
                      isMobile: isMobile,
                    ),
                    SizedBox(height: spacing),
                    buildSectionTitle(
                        context.translate('Documentation'), context,
                        icon: Icons.attach_file),
                    _buildImageUploadSection(isMobile),
                    SizedBox(height: spacing),
                    buildSectionTitle(
                        context.translate('Additional Information'), context,
                        icon: Icons.note),
                    buildEditableTextField(
                      controller: _notesController,
                      label: context.translate('Notes'),
                      isMobile: isMobile,
                      maxLines: 3,
                    ),
                    SizedBox(height: spacing * 1.5),
                    YieldProfileActions(
                      isMobile: isMobile,
                      onAccept: () {
                        _updateYield('Accepted');
                      },
                      onReject: () {
                        _updateYield('Rejected');
                      },
                      onSave: () {
                        _updateYield('');
                      },
                      onDelete: _deleteYield,
                      isLoading: _isSaving,
                      isDeleting: _isDeleting,
                      isAccepting: _isAccepting,
                      isRejecting: _isRejecting,
                      yieldStatus: widget.yieldData.status,
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _deleteYield() async {
    // Prevent multiple simultaneous operations
    if (_isSaving || _isDeleting || _isAccepting || _isRejecting) {
      return;
    }

    final confirmed = await ModalDialog.show(
      context: context,
      title: context.translate('Delete Yield'),
      showTitle: true,
      showTitleDivider: true,
      modalType: ModalType.medium,
      onCancelTap: () => Navigator.of(context).pop(false),
      onSaveTap: () => Navigator.of(context).pop(true),
      child: Center(
        child: Text(
            context.translate('Are you sure you want to delete this record?')),
      ),
      footer: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 120,
                child: ButtonWidget(
                  btnText: context.translate('Cancel'),
                  textColor: FlarelineColors.darkBlackText,
                  onTap: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 120,
                child: ButtonWidget(
                  btnText: context.translate('Delete'),
                  onTap: () => Navigator.of(context).pop(true),
                  type: ButtonType.primary.type,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      try {
        setState(() {
          _isDeleting = true;
          _currentOperation = 'delete';
        });
        print('Starting delete operation...');
        context.read<YieldBloc>().add(DeleteYield(widget.yieldData.id));
      } catch (e) {
        print('Error deleting yield: $e');
        setState(() => _isDeleting = false);
        _showToast('Error deleting yield: ${e.toString()}', isError: true);
      }
    }
  }

  Widget _buildImageUploadSection(bool isMobile) {
    return _imageHandler.buildImageUploadSection(
      context: context,
      isMobile: isMobile,
      onAddImages: _pickImages,
      onRemoveImage: _removeImage,
    );
  }
}

Widget buildEditableTextField({
  required TextEditingController controller,
  required String label,
  required bool isMobile,
  TextInputType? keyboardType,
  String? prefixText,
  String? suffixText,
  int maxLines = 1,
}) {
  return SizedBox(
    width: isMobile ? double.infinity : null,
    child: TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixText: prefixText,
        suffixText: suffixText,
        contentPadding: EdgeInsets.symmetric(
          vertical: isMobile ? 12 : 16,
          horizontal: 12,
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
    ),
  );
}
