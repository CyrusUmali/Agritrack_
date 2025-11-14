import 'package:flareline/core/models/farmer_model.dart';
import 'package:flareline/core/models/product_model.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/pages/test/map_widget/map_panel/polygon_modal_components/polygon_content.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:provider/provider.dart';
import '../pin_style.dart';
import '../polygon_manager.dart';

import 'package:flareline/services/lanugage_extension.dart';

class PolygonModal {
  static Future<void> show({
    required BuildContext context,
    required PolygonData polygon,
    required Function(LatLng) onUpdateCenter,
    required Function(PinStyle) onUpdatePinStyle,
    required Function(String) onUpdateStatus,
    required Function(Color) onUpdateColor,
    required Function(List<String>) onUpdateProducts,
    required Function(String) onUpdateFarmName,
    required Function(String) onUpdateFarmOwner,
    required Function(String) onUpdateBarangay,
    required Function(String) onUpdateLake,
    required VoidCallback onSave,
    required Function(int) onDeletePolygon,
    String selectedYear = '2024',
    required Function(String) onYearChanged,
    required List<Product> products,
    required List<Farmer> farmers,
  }) async {
    final theme = Theme.of(context);
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    final polygonCopy = polygon.copyWith();

    // Local update callbacks
    void updateCopyCenter(LatLng center) => polygonCopy.center = center;
    void updateCopyPinStyle(PinStyle style) => polygonCopy.pinStyle = style;
    void updateCopyStatus(String status) => polygonCopy.status = status;
    void updateCopyColor(Color color) => polygonCopy.color = color;
    void updateCopyProducts(List<String> products) =>
        polygonCopy.products = products;
    void updateCopyFarmName(String name) => polygonCopy.name = name;
    void updateCopyFarmOwner(String owner) => polygonCopy.owner = owner;
    void updateCopyBarangay(String barangay) =>
        polygonCopy.parentBarangay = barangay;

    void updateCopyLake(String lake) => polygonCopy.lake = lake;

    if (isLargeScreen) {
      await _showLargeScreenModal(
        context: context,
        polygon: polygonCopy,
        farmers: farmers,
        products: products,
        onUpdateCenter: updateCopyCenter,
        onUpdatePinStyle: updateCopyPinStyle,
        onUpdateStatus: updateCopyStatus,
        onUpdateColor: updateCopyColor,
        onUpdateProducts: updateCopyProducts,
        onUpdateFarmName: updateCopyFarmName,
        onUpdateFarmOwner: updateCopyFarmOwner,
        onUpdateBarangay: updateCopyBarangay,
        onUpdateLake: updateCopyLake,
        onSave: () {
          polygon.updateFrom(polygonCopy);
          onSave();
        },
        onDeletePolygon: onDeletePolygon,
        selectedYear: selectedYear,
        onYearChanged: onYearChanged,
        theme: theme,
      );
    } else {
      await _showSmallScreenModal(
        context: context,
        polygon: polygonCopy,
        farmers: farmers,
        products: products,
        onUpdateCenter: updateCopyCenter,
        onUpdatePinStyle: updateCopyPinStyle,
        onUpdateStatus: updateCopyStatus,
        onUpdateColor: updateCopyColor,
        onUpdateProducts: updateCopyProducts,
        onUpdateFarmName: updateCopyFarmName,
        onUpdateFarmOwner: updateCopyFarmOwner,
        onUpdateBarangay: updateCopyBarangay,
        onUpdateLake: updateCopyLake,
        onSave: () {
          polygon.updateFrom(polygonCopy);
          onSave();
        },
        onDeletePolygon: onDeletePolygon, // Pass it through
        selectedYear: selectedYear,
        onYearChanged: onYearChanged,
        theme: theme,
      );
    }
  }

  static Future<void> _showSmallScreenModal({
    required BuildContext context,
    required PolygonData polygon,
    required Function(LatLng) onUpdateCenter,
    required Function(PinStyle) onUpdatePinStyle,
    required Function(String) onUpdateStatus,
    required Function(Color) onUpdateColor,
    required Function(List<String>) onUpdateProducts,
    required Function(String) onUpdateFarmName,
    required Function(String) onUpdateFarmOwner,
    required Function(String) onUpdateBarangay,
    required Function(String) onUpdateLake,
    required Function(int) onDeletePolygon,
    required VoidCallback onSave,
    required String selectedYear,
    required Function(String) onYearChanged,
    required ThemeData theme,
    required List<Farmer> farmers,
    required List<Product> products,
  }) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final _isFarmer = userProvider.isFarmer;
    final _farmerId = userProvider.farmer?.id?.toString();

    // print('_isFarmer');
    // print(_isFarmer);

    await WoltModalSheet.show(
      context: context,
      pageListBuilder: (modalContext) => [
        WoltModalSheetPage(
          // backgroundColor: Theme.of(context).cardTheme.color,
          hasSabGradient: false,
          isTopBarLayerAlwaysVisible: true,
          trailingNavBarWidget: Container(
            color: Theme.of(context).cardTheme.color,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(modalContext).pop(),
                ),
              ],
            ),
          ),
          child: Container(
            color: Theme.of(context).cardTheme.color,
            child: ModalContent(
              polygon: polygon,
              products: products,
              farmers: farmers,
              onUpdateCenter: onUpdateCenter,
              onUpdatePinStyle: onUpdatePinStyle,
              onUpdateStatus: onUpdateStatus,
              onUpdateColor: onUpdateColor,
              onUpdateProducts: onUpdateProducts,
              onUpdateFarmName: onUpdateFarmName,
              onUpdateFarmOwner: onUpdateFarmOwner,
              onUpdateBarangay: onUpdateBarangay,
              onUpdateLake: onUpdateLake,
              selectedYear: selectedYear,
              theme: theme,
              onSave: () {},
              onDeletePolygon: onDeletePolygon,
            ),
          ),
          stickyActionBar: (_isFarmer == true &&
                  polygon.farmerId.toString() != _farmerId.toString())
              ? null
              : Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      )
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlarelineColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: () {
                      onSave();
                      Navigator.of(modalContext).pop();
                    },
                    child: Text(
                      context.translate('Save Changes'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
        )
      ],
      modalTypeBuilder: (context) => const WoltBottomSheetType(),
      onModalDismissedWithBarrierTap: () => Navigator.of(context).pop(),
    );
  }

  static Future<void> _showLargeScreenModal({
    required BuildContext context,
    required PolygonData polygon,
    required Function(LatLng) onUpdateCenter,
    required Function(PinStyle) onUpdatePinStyle,
    required Function(String) onUpdateStatus,
    required Function(Color) onUpdateColor,
    required Function(List<String>) onUpdateProducts,
    required Function(String) onUpdateFarmName,
    required Function(String) onUpdateFarmOwner,
    required Function(String) onUpdateBarangay,
    required Function(String) onUpdateLake,
    required VoidCallback onSave,
    required Function(int) onDeletePolygon,
    required String selectedYear,
    required Function(String) onYearChanged,
    required ThemeData theme,
    required List<Farmer> farmers,
    required List<Product> products,
  }) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.all(20),
          contentPadding: EdgeInsets.zero,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? GlobalColors.darkerCardColor
              : Theme.of(context).cardTheme.color,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            child: ModalContent(
              polygon: polygon,
              products: products,
              farmers: farmers,
              onUpdateCenter: onUpdateCenter,
              onUpdatePinStyle: onUpdatePinStyle,
              onUpdateStatus: onUpdateStatus,
              onUpdateColor: onUpdateColor,
              onUpdateProducts: onUpdateProducts,
              onUpdateFarmName: onUpdateFarmName,
              onUpdateFarmOwner: onUpdateFarmOwner,
              onUpdateBarangay: onUpdateBarangay,
              onUpdateLake: onUpdateLake,
              selectedYear: selectedYear,
              theme: theme,
              isLargeScreen: true,
              onSave: () {
                onSave();
                Navigator.of(context).pop();
              },
              onDeletePolygon: onDeletePolygon,
            ),
          ),
        );
      },
    );
  }
}
