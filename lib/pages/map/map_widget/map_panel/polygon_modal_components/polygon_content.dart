import 'package:flareline/core/models/farmer_model.dart';
import 'package:flareline/core/models/product_model.dart';
import 'package:flareline/pages/map/map_widget/map_panel/polygon_modal.dart';
import 'package:flareline/pages/map/map_widget/map_panel/polygon_modal_components/edit_controls.dart';
import 'package:flareline/pages/map/map_widget/map_panel/polygon_modal_components/farm_info_card.dart';
import 'package:flareline/pages/map/map_widget/map_panel/polygon_modal_components/yield_data_table.dart';
import 'package:flareline/pages/map/map_widget/pin_style.dart';
import 'package:flareline/pages/map/map_widget/polygon_manager.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flutter/material.dart'; 
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class ModalContent extends StatefulWidget {
  final PolygonData polygon;
  final Function(LatLng) onUpdateCenter;
  final Function(PinStyle) onUpdatePinStyle;
  final Function(String) onUpdateStatus;
  final Function(Color) onUpdateColor;
  final Function(List<String>) onUpdateProducts;
  final Function(String) onUpdateFarmName;
  final Function(String) onUpdateFarmOwner;
  final Function(String) onUpdateBarangay;
  final Function(String) onUpdateLake;
  final Function(int) onDeletePolygon;
  final String selectedYear;
  final ThemeData theme;
  final bool isLargeScreen;
  final VoidCallback onSave;
  final List<Product> products;
  final List<Farmer> farmers;

  const ModalContent({
    required this.polygon,
    required this.onUpdateCenter,
    required this.onUpdatePinStyle,
    required this.onUpdateStatus,
    required this.onUpdateColor,
    required this.onUpdateProducts,
    required this.onUpdateFarmName,
    required this.onUpdateFarmOwner,
    required this.onUpdateBarangay,
    required this.onUpdateLake,
    required this.onDeletePolygon,
    required this.selectedYear,
    required this.theme,
    required this.products,
    required this.farmers,
    this.isLargeScreen = false,
    required this.onSave,
    super.key,
  });

  @override
  State<ModalContent> createState() => ModalContentState();
}

class ModalContentState extends State<ModalContent> {
  late TextEditingController latController;
  late TextEditingController lngController;
  late TextEditingController farmNameController;
  late Color selectedColor;
  late PinStyle selectedPinStyle;
  late String selectedStatus;
  late List<String> selectedProducts;
  late String farmName;
  late String farmOwner;
  late String barangay;
  late String lake;

  @override
  void initState() {
    super.initState();

    final center = widget.polygon.center;
    latController = TextEditingController(
      text: center.latitude.toStringAsFixed(6),
    );
    lngController = TextEditingController(
      text: center.longitude.toStringAsFixed(6),
    );

    farmNameController = TextEditingController(text: widget.polygon.name
    );

    selectedColor = widget.polygon.color;
    selectedPinStyle = widget.polygon.pinStyle;
    selectedStatus = widget.polygon.status!;
    selectedProducts = widget.polygon.products.toList();
    farmName = widget.polygon.name;
    farmOwner = widget.polygon.owner ?? '';
    barangay = widget.polygon.parentBarangay ?? '';
    lake = widget.polygon.lake ?? '';
  }

  @override
  void didUpdateWidget(covariant ModalContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.polygon != widget.polygon) {
      final center = widget.polygon.center;
      latController.text = center.latitude.toStringAsFixed(6);
      lngController.text = center.longitude.toStringAsFixed(6);
      selectedColor = widget.polygon.color;
      selectedPinStyle = widget.polygon.pinStyle;
      selectedStatus = widget.polygon.status!;
      selectedProducts = widget.polygon.products.toList();

      if (farmNameController.text != widget.polygon.name) {
        farmNameController.text = widget.polygon.name;
      }
      farmOwner = widget.polygon.owner ?? '';
      barangay = widget.polygon.parentBarangay ?? '';
      lake = widget.polygon.lake ?? '';
    }
  }

  @override
  void dispose() {
    latController.dispose();
    lngController.dispose();
    farmNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final _isFarmer = userProvider.isFarmer;
    final _farmerId = userProvider.farmer?.id;

    if (widget.polygon.vertices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.isLargeScreen) {
      // For large screens (desktop/tablet)
      return _buildLargeScreenLayout(context, _isFarmer, _farmerId);
    } else {
      // For small screens (mobile)
      return _buildSmallScreenLayout(context, _isFarmer, _farmerId);
    }
  }



Widget _buildLargeScreenLayout(
    BuildContext context, bool? _isFarmer, int? _farmerId) {
  final isSidePanel = PolygonModal.modalLayout == ModalLayout.sidePanel;

  // Create a common button widget to avoid code duplication
  Widget _buildSaveButton() {
    if (_isFarmer == false || widget.polygon.farmerId == _farmerId) {
      return Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: FlarelineColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: widget.onSave,
          child: const Text(
            'Save Changes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  if (isSidePanel) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FarmInfoCard.build(
                  context: context,
                  products: widget.products,
                  farmers: widget.farmers,
                  polygon: widget.polygon.copyWith(
                    products: selectedProducts,
                    name: farmName,
                    owner: farmOwner,
                    parentBarangay: barangay,
                    lake: lake,
                  ),
                  theme: widget.theme,
                  onBarangayChanged: (newBarangay) {
                    setState(() => barangay = newBarangay);
                    widget.onUpdateBarangay(newBarangay);
                  },
                  onLakeChanged: (newLake) {
                    setState(() => lake = newLake);
                    widget.onUpdateLake(newLake);
                  },
                  onFarmOwnerChanged: (newOwner) {
                    setState(() => farmOwner = newOwner);
                    widget.onUpdateFarmOwner(newOwner);
                  },
                  onFarmNameChanged: (newName) {
                    setState(() => farmName = newName);
                    widget.onUpdateFarmName(newName);
                  },
                  onFarmUpdated: (updatedPolygon) {
                    setState(() {
                      selectedProducts = updatedPolygon.products;
                      farmName = updatedPolygon.name;
                      farmOwner = updatedPolygon.owner ?? '';
                      barangay = updatedPolygon.parentBarangay ?? '';
                      lake = updatedPolygon.lake ?? '';
                    });
                    widget.onUpdateProducts(selectedProducts);
                    widget.onUpdateFarmName(farmName);
                    widget.onUpdateFarmOwner(farmOwner);
                    widget.onUpdateBarangay(barangay);
                    widget.onUpdateLake(lake);
                  },
                  farmNameController: farmNameController,
                ),
                const SizedBox(height: 24),
                EditControls.build(
                  context: context,
                  polygon: widget.polygon,
                  selectedPinStyle: selectedPinStyle,
                  selectedStatus: selectedStatus,
                  selectedColor: selectedColor,
                  onColorChanged: (color) {
                    setState(() => selectedColor = color);
                    widget.onUpdateColor(color);
                  },
                  onPinStyleChanged: (style) {
                    setState(() => selectedPinStyle = style);
                    widget.onUpdatePinStyle(style);
                  },
                  onStatusChanged: (status) {
                    setState(() => selectedStatus = status);
                    widget.onUpdateStatus(status);
                  },
                  onDelete: () {
                    widget.onDeletePolygon(widget.polygon.id!);
                    Navigator.of(context).pop();
                  },
                  theme: widget.theme,
                ),
                // Save button in side panel
                _buildSaveButton(),
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: YieldDataTable(
                    polygon: widget.polygon,
                    modalLayout: PolygonModal.modalLayout,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  } else {
    // Horizontal layout for center dialog
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FarmInfoCard.build(
                  context: context,
                  products: widget.products,
                  farmers: widget.farmers,
                  polygon: widget.polygon.copyWith(
                    products: selectedProducts,
                    name: farmName,
                    owner: farmOwner,
                    parentBarangay: barangay,
                    lake: lake,
                  ),
                  theme: widget.theme,
                  onBarangayChanged: (newBarangay) {
                    setState(() => barangay = newBarangay);
                    widget.onUpdateBarangay(newBarangay);
                  },
                  onLakeChanged: (newLake) {
                    setState(() => lake = newLake);
                    widget.onUpdateLake(newLake);
                  },
                  onFarmOwnerChanged: (newOwner) {
                    setState(() => farmOwner = newOwner);
                    widget.onUpdateFarmOwner(newOwner);
                  },
                  onFarmNameChanged: (newName) {
                    setState(() => farmName = newName);
                    widget.onUpdateFarmName(newName);
                  },
                  onFarmUpdated: (updatedPolygon) {
                    setState(() {
                      selectedProducts = updatedPolygon.products;
                      farmName = updatedPolygon.name;
                      farmOwner = updatedPolygon.owner ?? '';
                      barangay = updatedPolygon.parentBarangay ?? '';
                      lake = updatedPolygon.lake ?? '';
                    });
                    widget.onUpdateProducts(selectedProducts);
                    widget.onUpdateFarmName(farmName);
                    widget.onUpdateFarmOwner(farmOwner);
                    widget.onUpdateBarangay(barangay);
                    widget.onUpdateLake(lake);
                  },
                  farmNameController: farmNameController,
                ),
                const SizedBox(height: 24),
                EditControls.build(
                  context: context,
                  polygon: widget.polygon,
                  selectedPinStyle: selectedPinStyle,
                  selectedStatus: selectedStatus,
                  selectedColor: selectedColor,
                  onColorChanged: (color) {
                    setState(() => selectedColor = color);
                    widget.onUpdateColor(color);
                  },
                  onPinStyleChanged: (style) {
                    setState(() => selectedPinStyle = style);
                    widget.onUpdatePinStyle(style);
                  },
                  onStatusChanged: (status) {
                    setState(() => selectedStatus = status);
                    widget.onUpdateStatus(status);
                  },
                  onDelete: () {
                    widget.onDeletePolygon(widget.polygon.id!);
                    Navigator.of(context).pop();
                  },
                  theme: widget.theme,
                ),
                // Save button added below EditControls in center dialog
                _buildSaveButton(),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            child: Column(
              children: [
                YieldDataTable(
                  polygon: widget.polygon,
                  modalLayout: PolygonModal.modalLayout,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Widget _buildSmallScreenLayout(
    BuildContext context, bool? _isFarmer, int? _farmerId) {

      print('iisfarmer');
      print(_isFarmer);
  // Mobile layout
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FarmInfoCard.build(
          context: context,
          products: widget.products,
          farmers: widget.farmers,
          polygon: widget.polygon.copyWith(
            products: selectedProducts,
            name: farmName,
            owner: farmOwner,
            parentBarangay: barangay,
            lake: lake,
          ),
          theme: widget.theme,
          onBarangayChanged: (newBarangay) {
            setState(() => barangay = newBarangay);
            widget.onUpdateBarangay(newBarangay);
          },
          onLakeChanged: (newLake) {
            setState(() => lake = newLake);
            widget.onUpdateLake(newLake);
          },
          onFarmOwnerChanged: (newOwner) {
            setState(() => farmOwner = newOwner);
            widget.onUpdateFarmOwner(newOwner);
          },
          onFarmNameChanged: (newName) {
            setState(() => farmName = newName);
            widget.onUpdateFarmName(newName);
          },
          onFarmUpdated: (updatedPolygon) {
            setState(() {
              selectedProducts = updatedPolygon.products;
              farmName = updatedPolygon.name;
              farmOwner = updatedPolygon.owner ?? '';
              barangay = updatedPolygon.parentBarangay ?? '';
              lake = updatedPolygon.lake ?? '';
            });
            widget.onUpdateProducts(selectedProducts);
            widget.onUpdateFarmName(farmName);
            widget.onUpdateFarmOwner(farmOwner);
            widget.onUpdateBarangay(barangay);
            widget.onUpdateLake(lake);
          },
          farmNameController: farmNameController,
        ),
        EditControls.build(
          context: context,
          polygon: widget.polygon,
          selectedPinStyle: selectedPinStyle,
          selectedStatus: selectedStatus,
          selectedColor: selectedColor,
          onColorChanged: (color) {
            setState(() => selectedColor = color);
            widget.onUpdateColor(color);
          },
          onPinStyleChanged: (style) {
            setState(() => selectedPinStyle = style);
            widget.onUpdatePinStyle(style);
          },
          onStatusChanged: (status) {
            setState(() => selectedStatus = status);
            widget.onUpdateStatus(status);
          },
          onDelete: () {
            widget.onDeletePolygon(widget.polygon.id!);
            Navigator.of(context).pop();
          },
          theme: widget.theme,
        ),
    
      
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 100),
          child: YieldDataTable(
            polygon: widget.polygon,
            farmerId: _farmerId,
          ),
        ),
      ],
    ),
  );
}




}