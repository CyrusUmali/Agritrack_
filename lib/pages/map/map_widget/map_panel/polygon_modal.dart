import 'package:flareline/core/models/farmer_model.dart';
import 'package:flareline/core/models/product_model.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/pages/farms/farm_widgets/recent_records.dart';
import 'package:flareline/pages/map/map_widget/map_panel/polygon_modal_components/polygon_content.dart';
import 'package:flareline/pages/toast/toast_helper.dart'; 
import 'package:flareline/providers/user_provider.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:toastification/toastification.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:provider/provider.dart';
import 'package:flareline/pages/map/map_widget/pin_style.dart';
import 'package:flareline/pages/map/map_widget/polygon_manager.dart';
import 'package:flareline/services/lanugage_extension.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/pages/yields/yield_bloc/yield_bloc.dart'; // Import YieldBloc
import 'package:iconify_flutter_plus/iconify_flutter_plus.dart';
import 'package:iconify_flutter_plus/icons/mdi.dart';

enum ModalLayout { centerDialog, sidePanel }
enum ContentType { modalContent, recentRecord } // New enum for content types

// Add this ValueNotifier class at the top level
class YieldUpdateNotifier {
  static final ValueNotifier<int> _farmIdNotifier = ValueNotifier<int>(-1);
  
  static ValueNotifier<int> get farmIdNotifier => _farmIdNotifier;
  
  static void notifyFarmUpdate(int farmId) {
    _farmIdNotifier.value = farmId;
  }
  
  static void reset() {
    _farmIdNotifier.value = -1;
  }
}

class PolygonModal {
  static ModalLayout modalLayout = ModalLayout.centerDialog;
  static ContentType contentType = ContentType.modalContent; // Default to ModalContent
  
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

     contentType = ContentType.modalContent;
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
      if (modalLayout == ModalLayout.sidePanel) {
        await _showSidePanelModal(
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
        await _showCenterDialogModal(
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
          onUpdateLake: onUpdateLake,
          onSave: () {
            polygon.updateFrom(polygonCopy);
            onSave();
          },
          onDeletePolygon: onDeletePolygon,
          selectedYear: selectedYear,
          onYearChanged: onYearChanged,
          theme: theme,
        );
      }
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
        onUpdateLake: onUpdateLake,
        onSave: () {
          polygon.updateFrom(polygonCopy);
          onSave();
        },
        onDeletePolygon: onDeletePolygon,
        selectedYear: selectedYear,
        onYearChanged: onYearChanged,
        theme: theme,
      );
    }
  }

  static Future<void> _showCenterDialogModal({
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
  barrierDismissible: false,
  builder: (context) {
    return BlocProvider(
      create: (context) => YieldBloc(
        yieldRepository: context.read<YieldBloc>().yieldRepository,
      )..add(GetYieldByFarmId(polygon.id!)),
      child: BlocListener<YieldBloc, YieldState>(
        listener: (context, state) {
          if (state is YieldsLoaded && state.message != null) {
            toastification.show(
              context: context,
              type: ToastificationType.success,
              style: ToastificationStyle.flat,
              title: Text(state.message!),
              alignment: Alignment.topRight,
              showProgressBar: false,
              autoCloseDuration: const Duration(seconds: 3),
            );
          } else if (state is YieldsError) {
            ToastHelper.showErrorToast(state.message, context, maxLines: 3);
          }
        },
   
          child: AlertDialog(
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
              child: _LargeScreenModalWrapper(
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
                onDeletePolygon: onDeletePolygon,
                selectedYear: selectedYear,
                theme: theme,
                isLargeScreen: true,
                onSave: () {
                  onSave();
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
     ) );
      },
    );
  }

  static Future<void> _showSidePanelModal({
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
  barrierDismissible: false,
  builder: (context) {
    return BlocProvider(
      create: (context) => YieldBloc(
        yieldRepository: context.read<YieldBloc>().yieldRepository,
      )..add(GetYieldByFarmId(polygon.id!)),
      child: BlocListener<YieldBloc, YieldState>(
        listener: (context, state) {
          if (state is YieldsLoaded && state.message != null) {
            toastification.show(
              context: context,
              type: ToastificationType.success,
              style: ToastificationStyle.flat,
              title: Text(state.message!),
              alignment: Alignment.topRight,
              showProgressBar: false,
              autoCloseDuration: const Duration(seconds: 3),
            );
          } else if (state is YieldsError) {
            ToastHelper.showErrorToast(state.message, context, maxLines: 3);
          }
        },

  

          child: Dialog(
            alignment: Alignment.centerRight,
            insetPadding: const EdgeInsets.only(right: 0, top: 0, bottom: 0),
            child: Container(
              width: 400,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? GlobalColors.darkerCardColor
                    : Theme.of(context).cardTheme.color,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(-5, 0),
                  ),
                ],
              ),
              child: _LargeScreenModalWrapper(
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
                onDeletePolygon: onDeletePolygon,
                selectedYear: selectedYear,
                theme: theme,
                isLargeScreen: true,
                onSave: () {
                  onSave();
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        ) );
      },
    );
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
  required VoidCallback onSave,
  required Function(int) onDeletePolygon,
  required String selectedYear,
  required Function(String) onYearChanged,
  required ThemeData theme,
  required List<Farmer> farmers,
  required List<Product> products,
}) async {
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  final isFarmer = userProvider.isFarmer;
  final farmerId = userProvider.farmer?.id.toString();

  await WoltModalSheet.show(
    context: context,
    pageListBuilder: (modalContext) => [
      WoltModalSheetPage(
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
        child: BlocProvider(
          create: (context) => YieldBloc(
            yieldRepository: context.read<YieldBloc>().yieldRepository,
          )..add(GetYieldByFarmId(polygon.id!)),
          child: BlocListener<YieldBloc, YieldState>(
            listener: (context, state) {
              if (state is YieldsLoaded && state.message != null) {
                // Show toast for success message
                toastification.show(
                  context: context,
                  type: ToastificationType.success,
                  style: ToastificationStyle.flat,
                  title: Text(state.message!),
                  alignment: Alignment.topRight,
                  showProgressBar: false,
                  autoCloseDuration: const Duration(seconds: 3),
                );
              } else if (state is YieldsError) {
                // Show error toast
                ToastHelper.showErrorToast(state.message, context, maxLines: 3);
              }
            },
            child: Container(
              color: Theme.of(context).cardTheme.color,
              child: ModalContentWithToggle(
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
                onDeletePolygon: onDeletePolygon,
                selectedYear: selectedYear,
                theme: theme,
                onSave: () {},
                isLargeScreen: false,
              ),
            ),
          ),
        ),
        stickyActionBar: (isFarmer == true &&
                polygon.farmerId.toString() != farmerId.toString())
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



}

// Large screen wrapper that includes header with layout toggle and close button
class _LargeScreenModalWrapper extends StatefulWidget {
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

  const _LargeScreenModalWrapper({
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
  });

  @override
  State<_LargeScreenModalWrapper> createState() => _LargeScreenModalWrapperState();
}

class _LargeScreenModalWrapperState extends State<_LargeScreenModalWrapper> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header row with controls
        _buildHeaderRow(context),
        // Content
        Expanded(
          child: ModalContentWithToggle(
            polygon: widget.polygon,
            products: widget.products,
            farmers: widget.farmers,
            onUpdateCenter: widget.onUpdateCenter,
            onUpdatePinStyle: widget.onUpdatePinStyle,
            onUpdateStatus: widget.onUpdateStatus,
            onUpdateColor: widget.onUpdateColor,
            onUpdateProducts: widget.onUpdateProducts,
            onUpdateFarmName: widget.onUpdateFarmName,
            onUpdateFarmOwner: widget.onUpdateFarmOwner,
            onUpdateBarangay: widget.onUpdateBarangay,
            onUpdateLake: widget.onUpdateLake,
            onDeletePolygon: widget.onDeletePolygon,
            selectedYear: widget.selectedYear,
            theme: widget.theme,
            onSave: widget.onSave,
            isLargeScreen: widget.isLargeScreen,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isFarmer = userProvider.isFarmer;
    final farmerId = userProvider.farmer?.id;
    final shouldShowToggleAndContent = !isFarmer ||
        (isFarmer && widget.polygon.farmerId == farmerId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: widget.theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Spacer to push the toggle to center when no content toggle is shown
          if (!shouldShowToggleAndContent) const Spacer(),
          
          // Content Type Toggle (centered when shown)
          if (shouldShowToggleAndContent)
            Expanded(
              child: Center(
                child: _buildContentTypeToggle(),
              ),
            )
          else
            const SizedBox(width: 48), // Placeholder for layout toggle spacing
            
          // Layout toggle and close button container (top right)
          _buildLayoutToggleAndCloseContainer(context),
        ],
      ),
    );
  }


  Widget _buildContentTypeToggle() {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
        color: theme.brightness == Brightness.dark
            ? theme.primaryColor.withOpacity(0.1)
            : Colors.grey.shade50,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildContentTypeToggleButton(
            icon: Icons.info_outline,
            label: 'Details',
            isSelected: PolygonModal.contentType == ContentType.modalContent,
            onTap: () {
              setState(() {
                PolygonModal.contentType = ContentType.modalContent;
              });
            },
            theme: theme,
          ),
          Container(
            width: 1,
            height: 32,
            color: theme.dividerColor,
          ),
          _buildContentTypeToggleButton(
            icon: Icons.list,
            label: 'Records',
            isSelected: PolygonModal.contentType == ContentType.recentRecord,
            onTap: () {
              setState(() {
                PolygonModal.contentType = ContentType.recentRecord;
              });
            },
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildContentTypeToggleButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected
                ? theme.primaryColor.withOpacity(0.2)
                : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? theme.primaryColor
                    : theme.iconTheme.color?.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? theme.primaryColor
                      : theme.iconTheme.color?.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildLayoutToggleAndCloseContainer(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? FlarelineColors.background
                : Colors.grey.shade200,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(45),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Layout toggle button
            Tooltip(
              message: PolygonModal.modalLayout == ModalLayout.centerDialog
                  ? 'Switch to Side Panel'
                  : 'Switch to Center Dialog',
              child: InkWell(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(45),
                  bottomLeft: Radius.circular(45),
                ),
                hoverColor: Colors.grey.withOpacity(0.1),
                onTap: _toggleModalLayout,
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: PolygonModal.modalLayout == ModalLayout.centerDialog
                      ? Iconify(
                          Mdi.dock_right,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? FlarelineColors.background
                              : Colors.grey.shade700,
                        )
                      : Iconify(
                          Mdi.arrow_collapse_all,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? FlarelineColors.background
                              : Colors.grey.shade700,
                        ),
                ),
              ),
            ),
            
            // Vertical divider
            Container(
              height: 24,
              width: 1,
              color: Theme.of(context).brightness == Brightness.dark
                  ? FlarelineColors.background.withOpacity(0.5)
                  : Colors.grey.shade300,
            ),
            
            // Close button
            Tooltip(
              message: 'Close',
              child: InkWell(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(45),
                  bottomRight: Radius.circular(45),
                ),
                hoverColor: Colors.grey.withOpacity(0.1),
                onTap: () => Navigator.of(context).pop(),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Iconify(
                    Mdi.close,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? FlarelineColors.background
                        : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  void _toggleModalLayout() {
    setState(() {
      PolygonModal.modalLayout = PolygonModal.modalLayout == ModalLayout.centerDialog
          ? ModalLayout.sidePanel
          : ModalLayout.centerDialog;
    });
    _reopenModal();
  }

  void _reopenModal() {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PolygonModal.show(
        context: context,
        polygon: widget.polygon,
        onUpdateCenter: widget.onUpdateCenter,
        onUpdatePinStyle: widget.onUpdatePinStyle,
        onUpdateStatus: widget.onUpdateStatus,
        onUpdateColor: widget.onUpdateColor,
        onUpdateProducts: widget.onUpdateProducts,
        onUpdateFarmName: widget.onUpdateFarmName,
        onUpdateFarmOwner: widget.onUpdateFarmOwner,
        onUpdateBarangay: widget.onUpdateBarangay,
        onUpdateLake: widget.onUpdateLake,
        onSave: widget.onSave,
        onDeletePolygon: widget.onDeletePolygon,
        selectedYear: widget.selectedYear,
        onYearChanged: (_) {},
        products: widget.products,
        farmers: widget.farmers,
      );
    });
  }
}

 


 class ModalContentWithToggle extends StatefulWidget {
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

  const ModalContentWithToggle({
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
  State<ModalContentWithToggle> createState() => _ModalContentWithToggleState();
}

class _ModalContentWithToggleState extends State<ModalContentWithToggle> {
  @override
  void initState() {
    super.initState();
    // Listen to the ValueNotifier for yield updates
    YieldUpdateNotifier.farmIdNotifier.addListener(_handleYieldUpdate);
  }

  @override
  void dispose() {
    // Remove listener when widget is disposed
    YieldUpdateNotifier.farmIdNotifier.removeListener(_handleYieldUpdate);
    super.dispose();
  }

  void _handleYieldUpdate() {
    // When farmIdNotifier changes, check if it's for this farm
    final updatedFarmId = YieldUpdateNotifier.farmIdNotifier.value;
    if (updatedFarmId == widget.polygon.id && PolygonModal.contentType == ContentType.recentRecord) {
      // Reload yields for this farm
      context.read<YieldBloc>().add(GetYieldByFarmId(widget.polygon.id!));
      // Reset the notifier
      YieldUpdateNotifier.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    // For large screens, just show the content
    if (widget.isLargeScreen) {
      return _buildContent();
    }
    
    // For mobile, use SingleChildScrollView with proper structure
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMobileContentTypeToggle(),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildMobileContentTypeToggle() {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isFarmer = userProvider.isFarmer;
    final farmerId = userProvider.farmer?.id;
    
    // Only show toggle if user is not a farmer or owns the farm
    final shouldShowToggle = !isFarmer ||
        (isFarmer && widget.polygon.farmerId == farmerId);
    
    if (!shouldShowToggle) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: _buildContentTypeToggle(theme),
      ),
    );
  }



Widget _buildContentTypeToggle(ThemeData theme) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: theme.brightness == Brightness.dark
          ? Colors.grey.shade800
          : Colors.grey.shade200,
    ),
    padding: const EdgeInsets.all(4),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildContentTypeSegment(
          icon: Icons.info_outline,
          label: 'Details',
          isSelected: PolygonModal.contentType == ContentType.modalContent,
          onTap: () => setState(() => PolygonModal.contentType = ContentType.modalContent),
          theme: theme,
        ),
        const SizedBox(width: 4),
        _buildContentTypeSegment(
          icon: Icons.list,
          label: 'Records',
          isSelected: PolygonModal.contentType == ContentType.recentRecord,
          onTap: () => setState(() => PolygonModal.contentType = ContentType.recentRecord),
          theme: theme,
        ),
      ],
    ),
  );
}

Widget _buildContentTypeSegment({
  required IconData icon,
  required String label,
  required bool isSelected,
  required VoidCallback onTap,
  required ThemeData theme,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isSelected
            ? theme.cardColor
            : Colors.transparent,
        boxShadow: isSelected ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: isSelected ? theme.primaryColor : theme.iconTheme.color?.withOpacity(0.7)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? theme.textTheme.bodyLarge?.color : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    ),
  );
}


 
  Widget _buildContent() {
    switch (PolygonModal.contentType) {
      case ContentType.modalContent:
        return ModalContent(
          polygon: widget.polygon,
          products: widget.products,
          farmers: widget.farmers,
          onUpdateCenter: widget.onUpdateCenter,
          onUpdatePinStyle: widget.onUpdatePinStyle,
          onUpdateStatus: widget.onUpdateStatus,
          onUpdateColor: widget.onUpdateColor,
          onUpdateProducts: widget.onUpdateProducts,
          onUpdateFarmName: widget.onUpdateFarmName,
          onUpdateFarmOwner: widget.onUpdateFarmOwner,
          onUpdateBarangay: widget.onUpdateBarangay,
          onUpdateLake: widget.onUpdateLake,
          onDeletePolygon: widget.onDeletePolygon,
          selectedYear: widget.selectedYear,
          theme: widget.theme,
          isLargeScreen: widget.isLargeScreen,
          onSave: widget.onSave,
        );
      case ContentType.recentRecord:
        return BlocBuilder<YieldBloc, YieldState>(
          builder: (context, yieldState) {
            if (yieldState is YieldsLoading) {
              return SizedBox(
                height: 200, // Provide a fixed height for loading
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            
            if (yieldState is YieldsError) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Text('Error loading yields: ${yieldState.message}'),
                ),
              );
            }
            
            if (yieldState is YieldsLoaded) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: RecentRecord(
                  yields: yieldState.yields,
                  farmId: widget.polygon.id!,
                  farmerId: widget.polygon.farmerId ?? 0,
                ),
              );
            }
            
            return SizedBox(
              height: 200,
              child: const Center(child: Text('No yield data available')),
            );
          },
        );
    }
  }



}