import 'package:flareline/pages/map/map_widget/map_panel/polygon_modal.dart';
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

class YieldProfileForm2 extends StatefulWidget {
  final Yield yieldData;
  final Function(Yield)? onYieldUpdated;

  const YieldProfileForm2({
    super.key,
    required this.yieldData,
    this.onYieldUpdated,
  });

  @override
  State<YieldProfileForm2> createState() => _YieldProfileFormState();
}

class _YieldProfileFormState extends State<YieldProfileForm2> {
  final YieldImageHandler _imageHandler = YieldImageHandler();
  late TextEditingController _areaHarvestedController;
  late TextEditingController _volumeController;
  late TextEditingController _valueController;
  late TextEditingController _notesController;
  bool toastShown = false;

  DateTime? _selectedHarvestDate;

  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isAccepting = false;
  bool _isRejecting = false;

  @override
  void initState() {
    super.initState();
    toastShown = false;
    _imageHandler.existingImages = widget.yieldData.images
            .where((img) => img != null)
            .cast<String>()
            .toList();
    _areaHarvestedController = TextEditingController(
        text: widget.yieldData.areaHarvested?.toStringAsFixed(3) ?? '0.00');
    _volumeController = TextEditingController(
        text: widget.yieldData.volume.toStringAsFixed(2));
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
    if (_isSaving || _isDeleting || _isAccepting || _isRejecting) {
      return;
    }

    try {
      setState(() {
        if (status == 'Accepted') {
          _isAccepting = true;
        } else if (status == 'Rejected') {
          _isRejecting = true;
        } else {
          _isSaving = true;
        }
      });

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
      _showToast('Error updating yield: ${e.toString()}', isError: true);
      _resetLoadingStates();
    }
  }

  void _resetLoadingStates() {
    setState(() {
      _isSaving = false;
      _isAccepting = false;
      _isRejecting = false;
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



  // @override
  Widget build(BuildContext context) {
  final harvestDate = _selectedHarvestDate != null
      ? DateFormat('dd/MM/yyyy').format(_selectedHarvestDate!)
      : widget.yieldData.harvestDate != null
          ? DateFormat('dd/MM/yyyy').format(widget.yieldData.harvestDate)
          : 'Not specified';

  return BlocListener<YieldBloc, YieldState>(
    listener: (context, state) {
      if (state is YieldUpdated) {
        toastShown = true;
        _resetLoadingStates();
        _showToast('Yield updated successfully', isError: false);


        YieldUpdateNotifier.notifyFarmUpdate(widget.yieldData.farmId);

        if (widget.onYieldUpdated != null) {
          final updatedYield = widget.yieldData.copyWith(
            images: [..._imageHandler.existingImages],
            areaHarvested: double.tryParse(_areaHarvestedController.text),
            volume: double.tryParse(_volumeController.text),
            value: double.tryParse(_valueController.text),
            notes: _notesController.text,
            harvestDate: _selectedHarvestDate,
            status: state.yield.status,
          );
          widget.onYieldUpdated!(updatedYield);
        }

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              toastShown = false;
            });
          }
        });
      } else if (state is YieldsLoaded) {
        if (state.message?.contains('deleted') == true) {
          setState(() => _isDeleting = false);
          _showToast(state.message!, isError: false);
          
          // Add this line: Notify that the farm's yields have been updated
          YieldUpdateNotifier.notifyFarmUpdate(widget.yieldData.farmId);
          
          // Close the yield form
          Navigator.of(context).pop();
        } else {
          if (!_isDeleting) {
            setState(() {
              _isSaving = false;
              _isAccepting = false;
              _isRejecting = false;
            });
          }
        }
      } else if (state is YieldsError) {
        _resetLoadingStates();
        setState(() => _isDeleting = false);
        _showToast(state.message, isError: true);
      }
    },
    child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isMobile = constraints.maxWidth < 768;
            
            if (isMobile) {
              // Mobile layout (single column)
              return _buildMobileLayout(context, harvestDate);
            } else {
              // Desktop layout (two columns)
              return _buildDesktopLayout(context, harvestDate);
            }
          },
        ),
      ),
    );
  }




  Widget _buildMobileLayout(BuildContext context, String harvestDate) {
    return SingleChildScrollView(
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
                true,
                enabled: false,
              ),
              buildTextField(
                context.translate('Product Sector'),
                widget.yieldData.sector ?? 'Not specified',
                true,
                enabled: false,
              ),
            ],
            spacing: 12.0,
            isMobile: true,
          ),
          const SizedBox(height: 12),
          buildSectionTitle(
              context.translate('Farm Information'), context,
              icon: Icons.agriculture),
          buildResponsiveRow(
            children: [
              buildTextField(
                context.translate('Farmer Name'),
                widget.yieldData.farmerName ?? 'Not specified',
                true,
                enabled: false,
              ),
              buildTextField(
                context.translate('Location'),
                widget.yieldData.barangay ?? 'Not specified',
                true,
                enabled: false,
              ),
            ],
            spacing: 12.0,
            isMobile: true,
          ),
          const SizedBox(height: 12),
          buildResponsiveRow(
            children: [
              buildTextField(
                context.translate('Farm Name'),
                widget.yieldData.farmName ?? 'Not specified',
                true,
                enabled: false,
              ),
              buildEditableTextField(
                controller: _areaHarvestedController,
                label: context.translate('Area harvested (Ha)'),
                isMobile: true,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                suffixText: 'ha',
              ),
            ],
            spacing: 12.0,
            isMobile: true,
          ),
          const SizedBox(height: 12),
          buildSectionTitle(
              context.translate('Yield Information'), context,
              icon: Icons.assessment),
          buildResponsiveRow(
            children: [
              buildEditableTextField(
                controller: _volumeController,
                label: context.translate('Yield Amount'),
                isMobile: true,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                suffixText: 'kg',
              ),
              buildDatePickerField(
                context.translate('Harvest Date'),
                true,
                value: harvestDate,
                enabled: true,
                onTap: () => _selectHarvestDate(context),
              ),
            ],
            spacing: 12.0,
            isMobile: true,
          ),
          const SizedBox(height: 12),
          buildResponsiveRow(
            children: [
              buildEditableTextField(
                controller: _valueController,
                label: context.translate('Value in (Php)'),
                isMobile: true,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                prefixText: '\₱',
              ),
            ],
            spacing: 12.0,
            isMobile: true,
          ),
          const SizedBox(height: 12),
          buildSectionTitle(
              context.translate('Documentation'), context,
              icon: Icons.attach_file),
          _buildImageUploadSection(true),
          const SizedBox(height: 12),
          buildSectionTitle(
              context.translate('Additional Information'), context,
              icon: Icons.note),
          buildEditableTextField(
            controller: _notesController,
            label: context.translate('Notes'),
            isMobile: true,
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          YieldProfileActions(
            isMobile: true,
            onAccept: () => _updateYield('Accepted'),
            onReject: () => _updateYield('Rejected'),
            onSave: () => _updateYield(''),
            onDelete: _deleteYield,
            isLoading: _isSaving,
            isDeleting: _isDeleting,
            isAccepting: _isAccepting,
            isRejecting: _isRejecting,
            yieldStatus: widget.yieldData.status,
          )
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, String harvestDate) {
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: Product, Farm, and Yield Information
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.only(right: 16),
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
                        false,
                        enabled: false,
                      ),
                      buildTextField(
                        context.translate('Product Sector'),
                        widget.yieldData.sector ?? 'Not specified',
                        false,
                        enabled: false,
                      ),
                    ],
                    spacing: 16.0,
                    isMobile: false,
                  ),
                  const SizedBox(height: 16),
                  buildSectionTitle(
                      context.translate('Farm Information'), context,
                      icon: Icons.agriculture),
                  buildResponsiveRow(
                    children: [
                      buildTextField(
                        context.translate('Farmer Name'),
                        widget.yieldData.farmerName ?? 'Not specified',
                        false,
                        enabled: false,
                      ),
                      buildTextField(
                        context.translate('Location'),
                        widget.yieldData.barangay ?? 'Not specified',
                        false,
                        enabled: false,
                      ),
                    ],
                    spacing: 16.0,
                    isMobile: false,
                  ),
                  const SizedBox(height: 16),
                  buildResponsiveRow(
                    children: [
                      buildTextField(
                        context.translate('Farm Name'),
                        widget.yieldData.farmName ?? 'Not specified',
                        false,
                        enabled: false,
                      ),
                      buildEditableTextField(
                        controller: _areaHarvestedController,
                        label: context.translate('Area harvested (Ha)'),
                        isMobile: false,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        suffixText: 'ha',
                      ),
                    ],
                    spacing: 16.0,
                    isMobile: false,
                  ),
                  const SizedBox(height: 16),
                  buildSectionTitle(
                      context.translate('Yield Information'), context,
                      icon: Icons.assessment),
                  buildResponsiveRow(
                    children: [
                      buildEditableTextField(
                        controller: _volumeController,
                        label: context.translate('Yield Amount'),
                        isMobile: false,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        suffixText: 'kg',
                      ),
                      buildDatePickerField(
                        context.translate('Harvest Date'),
                        false,
                        value: harvestDate,
                        enabled: true,
                        onTap: () => _selectHarvestDate(context),
                      ),
                    ],
                    spacing: 16.0,
                    isMobile: false,
                  ),
                  const SizedBox(height: 16),
                  buildResponsiveRow(
                    children: [
                      buildEditableTextField(
                        controller: _valueController,
                        label: context.translate('Value in (Php)'),
                        isMobile: false,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        prefixText: '\₱',
                      ),
                    ],
                    spacing: 16.0,
                    isMobile: false,
                  ),
                ],
              ),
            ),
          ),

          // Right Column: Documentation, Notes, and Actions
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSectionTitle(
                    context.translate('Documentation'), context,
                    icon: Icons.attach_file),
                _buildImageUploadSection(false),
                const SizedBox(height: 16),
                buildSectionTitle(
                    context.translate('Additional Information'), context,
                    icon: Icons.note),
                buildEditableTextField(
                  controller: _notesController,
                  label: context.translate('Notes'),
                  isMobile: false,
                  maxLines: 6, // More lines for desktop
                ),
                const SizedBox(height: 24),
                YieldProfileActions(
                  isMobile: false,
                  onAccept: () => _updateYield('Accepted'),
                  onReject: () => _updateYield('Rejected'),
                  onSave: () => _updateYield(''),
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
        ],
      ),
    );
  }




Future<void> _deleteYield() async {
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
      }); 
      context.read<YieldBloc>().add(DeleteYield(
        id: widget.yieldData.id,
        isFarmSpecific: true, 
        farmId: widget.yieldData.farmId, 
        farmerId: widget.yieldData.farmerId
      ));
    } catch (e) {
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
                border: OutlineInputBorder(
      borderSide: BorderSide(color:  Colors.grey.shade300, width: 1),
    
    ),
    enabledBorder: OutlineInputBorder( // Add this
      borderSide: BorderSide(color:  Colors.grey.shade300, width: 1),
    
    ), 
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