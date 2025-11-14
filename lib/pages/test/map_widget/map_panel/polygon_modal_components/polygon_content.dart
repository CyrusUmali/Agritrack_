import 'package:flareline/core/models/farmer_model.dart';
import 'package:flareline/core/models/product_model.dart';
import 'package:flareline/pages/test/map_widget/map_panel/polygon_modal_components/edit_controls.dart';
import 'package:flareline/pages/test/map_widget/map_panel/polygon_modal_components/farm_info_card.dart';
import 'package:flareline/pages/test/map_widget/map_panel/polygon_modal_components/yield_data_table.dart';
import 'package:flareline/pages/test/map_widget/pin_style.dart';
import 'package:flareline/pages/test/map_widget/polygon_manager.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

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
  final Function(int) onDeletePolygon; // Add this
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
    required this.onDeletePolygon, // Add this
    required this.selectedYear,
    required this.theme,
    required this.products,
    required this.farmers,
    this.isLargeScreen = false,
    required this.onSave,
    Key? key,
  }) : super(key: key);

  @override
  State<ModalContent> createState() => ModalContentState();
}

class ModalContentState extends State<ModalContent> {
  late TextEditingController latController;
  late TextEditingController lngController;
  late TextEditingController farmNameController; // Add this
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

    print('polygonid' + widget.polygon.id.toString());
    final center = widget.polygon.center;
    latController = TextEditingController(
      text: center?.latitude.toStringAsFixed(6) ?? '0.0',
    );
    lngController = TextEditingController(
      text: center?.longitude.toStringAsFixed(6) ?? '0.0',
    );

    // Initialize farm name controller
    farmNameController = TextEditingController(text: widget.polygon.name ?? '');

    selectedColor = widget.polygon.color;
    selectedPinStyle = widget.polygon.pinStyle;
    selectedStatus = widget.polygon.status!;
    selectedProducts = widget.polygon.products?.toList() ?? [];
    farmName = widget.polygon.name ?? '';
    farmOwner = widget.polygon.owner ?? '';
    barangay = widget.polygon.parentBarangay ?? '';
    lake = widget.polygon.lake ?? '';
  }

  @override
  void didUpdateWidget(covariant ModalContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.polygon != widget.polygon) {
      final center = widget.polygon.center;
      latController.text = center?.latitude.toStringAsFixed(6) ?? '0.0';
      lngController.text = center?.longitude.toStringAsFixed(6) ?? '0.0';
      selectedColor = widget.polygon.color;
      selectedPinStyle = widget.polygon.pinStyle;
      selectedStatus = widget.polygon.status!;
      selectedProducts = widget.polygon.products?.toList() ?? [];
      // farmName = widget.polygon.name ?? '';
      // Update farm name controller
      if (farmNameController.text != widget.polygon.name) {
        farmNameController.text = widget.polygon.name ?? '';
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
    farmNameController.dispose(); // Dispose the farm name controller
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
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.close,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Row(
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
                          products: widget.products, // Add this
                          farmers: widget.farmers, // Add this
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
                              selectedProducts = updatedPolygon.products ?? [];
                              farmName = updatedPolygon.name ?? '';
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
                          farmNameController:
                              farmNameController, // Pass the controller
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
                            // Add this new callback
                            widget.onDeletePolygon(
                                widget.polygon.id!); // Add ! to assert non-null

                            Navigator.of(context)
                                .pop(); // Close the edit dialog if needed
                          },
                          theme: widget.theme,
                        ),
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    // padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [YieldDataTable(polygon: widget.polygon)],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_isFarmer == false || widget.polygon.farmerId == _farmerId)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: FlarelineColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 48),
                  maximumSize: const Size(400, 48),
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
            ),
        ],
      );
    } else {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FarmInfoCard.build(
              context: context,
              products: widget.products, // Add this
              farmers: widget.farmers, // Add this
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
                  selectedProducts = updatedPolygon.products ?? [];
                  farmName = updatedPolygon.name ?? '';
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
              farmNameController: farmNameController, // Pass the controller
            ),
            // const SizedBox(height: 16),
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
                // Add this new callback
                widget.onDeletePolygon(
                    widget.polygon.id!); // Add ! to assert non-null
                Navigator.of(context).pop(); // Close the edit dialog if needed
              },
              theme: widget.theme,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 100),
              child:
                  YieldDataTable(polygon: widget.polygon, farmerId: _farmerId),
            ),
          ],
        ),
      );
    }
  }
}
