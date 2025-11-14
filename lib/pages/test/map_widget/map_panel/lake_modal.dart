import 'package:flareline/pages/test/map_widget/map_panel/polygon_modal_components/barangay_yield_data_table.dart';
import 'package:flareline/pages/test/map_widget/map_panel/polygon_modal_components/lake_yield_data_table.dart';
import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:flareline/services/lanugage_extension.dart';
import '../polygon_manager.dart';
import 'barangay_info_card.dart';
import 'farms_list.dart';

class LakeModal {
  static Future<void> show({
    required BuildContext context,
    required PolygonData lake,
    required List<PolygonData> farms,
    required PolygonManager polygonManager,
  }) async {
    final theme = Theme.of(context);
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    if (isLargeScreen) {
      await _showLargeScreenModal(
        context: context,
        lake: lake,
        farms: farms,
        theme: theme,
        polygonManager: polygonManager,
      );
    } else {
      await _showSmallScreenModal(
        context: context,
        lake: lake,
        farms: farms,
        theme: theme,
        polygonManager: polygonManager,
      );
    }
  }

  static Future<void> _showSmallScreenModal({
    required BuildContext context,
    required PolygonData lake,
    required List<PolygonData> farms,
    required ThemeData theme,
    required PolygonManager polygonManager,
  }) async {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    await WoltModalSheet.show(
      context: context,
      pageListBuilder: (modalContext) => [
        WoltModalSheetPage(
          backgroundColor: Theme.of(context).cardTheme.color,
          hasSabGradient: false,
          isTopBarLayerAlwaysVisible: true,
          trailingNavBarWidget: Container(
            color: Theme.of(context).cardTheme.color,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.close,
                  ),
                  onPressed: () => Navigator.of(modalContext).pop(),
                ),
              ],
            ),
          ),
          child: Container(
            color: Theme.of(context).cardTheme.color,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _LakeContent(
                lake: lake,
                farms: farms,
                theme: theme,
                polygonManager: polygonManager,
                modalContext: modalContext,
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
    required PolygonData lake,
    required List<PolygonData> farms,
    required ThemeData theme,
    required PolygonManager polygonManager,
  }) async {
    return showDialog(
      context: context,
      builder: (dialogContext) {
        final dialogTheme =
            Theme.of(dialogContext); // Get theme from dialog context

        return AlertDialog(
          insetPadding: const EdgeInsets.all(20),
          contentPadding: EdgeInsets.zero,
          backgroundColor: dialogTheme.cardTheme.color,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: SizedBox(
            width: MediaQuery.of(dialogContext).size.width * 0.8,
            height: MediaQuery.of(dialogContext).size.height * 0.8,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${context.translate('Barangay Details')}: ${lake.name}',

                        // 'Barangay Details: ${lake.name}',
                        style: dialogTheme.textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _LakeContent(
                      lake: lake,
                      farms: farms,
                      theme: dialogTheme, // Use dialog theme here
                      polygonManager: polygonManager,
                      modalContext: dialogContext,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LakeContent extends StatefulWidget {
  final PolygonData lake;
  final List<PolygonData> farms;
  final ThemeData theme;
  final PolygonManager polygonManager;
  final BuildContext modalContext;

  const _LakeContent({
    required this.lake,
    required this.farms,
    required this.theme,
    required this.polygonManager,
    required this.modalContext,
  });

  @override
  State<_LakeContent> createState() => _LakeContentState();
}

class _LakeContentState extends State<_LakeContent> {
  bool _showFarmsList = false; // true for farms list, false for yield data

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barangay info card
        BarangayInfoCard.build(
          barangay: widget.lake,
          farms: widget.farms,
          theme: widget.theme,
          context: context,
        ),

        const SizedBox(height: 16),

        // Barangay statistics
        // BarangayStats.build(
        //   lake: widget.lake,
        //   farms: widget.farms,
        //   theme: widget.theme,
        // ),

        const SizedBox(height: 16),

        // Toggle buttons
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.theme.colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showFarmsList = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _showFarmsList
                          ? widget.theme.colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.agriculture,
                          size: 20,
                          color: _showFarmsList
                              ? Colors.white
                              : widget.theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.translate('Farms List'),
                          style: widget.theme.textTheme.titleSmall?.copyWith(
                            color: _showFarmsList
                                ? Colors.white
                                : widget.theme.colorScheme.onSurfaceVariant,
                            fontWeight: _showFarmsList
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showFarmsList = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: !_showFarmsList
                          ? widget.theme.colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart,
                          size: 20,
                          color: !_showFarmsList
                              ? Colors.white
                              : widget.theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.translate('Yield Data'),
                          style: widget.theme.textTheme.titleSmall?.copyWith(
                            color: !_showFarmsList
                                ? Colors.white
                                : widget.theme.colorScheme.onSurfaceVariant,
                            fontWeight: !_showFarmsList
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Content based on toggle
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: animation.drive(
                  Tween(begin: const Offset(0.0, 0.1), end: Offset.zero),
                ),
                child: child,
              ),
            );
          },
          child: _showFarmsList
              ? FarmsList.build(
                  key: const ValueKey('farms_list'),
                  barangay: widget.lake,
                  farms: widget.farms,
                  theme: widget.theme,
                  polygonManager: widget.polygonManager,
                  modalContext: widget.modalContext,
                )
              : LakeYieldDataTable(
                  key: const ValueKey('yield_data'),
                  lake: widget.lake.name,
                ),
        ),
      ],
    );
  }
}
