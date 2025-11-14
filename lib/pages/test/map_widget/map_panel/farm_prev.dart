import 'package:flareline/pages/test/map_widget/polygon_manager.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flutter/material.dart';
import 'package:flareline/services/lanugage_extension.dart';

class InfoCard extends StatelessWidget {
  final PolygonData polygon;
  final VoidCallback onTap;
  final VoidCallback? onClose; // NEW: Add onClose callback
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool showNavigation;
  final int currentIndex;
  final int totalCount;

  const InfoCard({
    Key? key,
    required this.polygon,
    required this.onTap,
    this.onClose, // NEW: Add to constructor
    this.onPrevious,
    this.onNext,
    this.showNavigation = false,
    this.currentIndex = 0,
    this.totalCount = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // If no navigation is needed, return the original design
    if (!showNavigation) {
      return Card(
        margin: const EdgeInsets.all(0),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Row
                Row(
                  children: [
                    // Color Indicator
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: polygon.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title
                    Expanded(
                      child: Text(
                        polygon.name ?? 'Unnamed Area',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Close button instead of chevron
                    if (onClose != null)
                      InkWell(
                        onTap: onClose,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                  ],
                ),

                // Description (if available)
                if (polygon.description != null &&
                    polygon.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    polygon.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Metadata Section
                const SizedBox(height: 12),
                _buildMetadataChip(
                  icon: Icons.landscape,
                  label: 'Area',
                  value: polygon.area != null ? '${polygon.area} Ha' : 'N/A',
                  theme: theme,
                ),

                if (polygon.parentBarangay != null) ...[
                  const SizedBox(height: 8),
                  _buildMetadataChip(
                    icon: Icons.location_city,
                    label: 'Barangay',
                    value: polygon.parentBarangay!,
                    theme: theme,
                  ),
                ],

                // Action Hint
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    context.translate('Tap to view details'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Return original design with navigation buttons when needed
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Previous button
        _buildNavigationButton(
          context: context,
          icon: Icons.chevron_left,
          onPressed: onPrevious,
          enabled: currentIndex > 0,
        ),
        const SizedBox(width: 8),

        // Original InfoCard with navigation counter
        Card(
          margin: const EdgeInsets.all(0),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Row with navigation counter
                  Row(
                    children: [
                      // Color Indicator
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: polygon.color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Title
                      Expanded(
                        child: Text(
                          polygon.name ?? 'Unnamed Area',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Navigation counter
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${currentIndex + 1}/$totalCount',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      // Close button instead of chevron
                      if (onClose != null)
                        InkWell(
                          onTap: onClose,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.close,
                              size: 20,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        )
                      else
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                    ],
                  ),

                  // Description (if available)
                  if (polygon.description != null &&
                      polygon.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      polygon.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.8),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Metadata Section
                  const SizedBox(height: 12),
                  _buildMetadataChip(
                    icon: Icons.landscape,
                    label: 'Area',
                    value: polygon.area != null ? '${polygon.area} Ha' : 'N/A',
                    theme: theme,
                  ),

                  if (polygon.parentBarangay != null) ...[
                    const SizedBox(height: 8),
                    _buildMetadataChip(
                      icon: Icons.location_city,
                      label: 'Barangay',
                      value: polygon.parentBarangay!,
                      theme: theme,
                    ),
                  ],

                  // Action Hint
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      context.translate('Tap to view details'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),
        // Next button
        _buildNavigationButton(
          context: context,
          icon: Icons.chevron_right,
          onPressed: onNext,
          enabled: currentIndex < totalCount - 1,
        ),
      ],
    );
  }

  Widget _buildNavigationButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback? onPressed,
    required bool enabled,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CommonCard(
      margin: const EdgeInsets.all(0),
      borderRadius: 12.0,
      color: enabled
          ? Theme.of(context).cardTheme.color
          : Theme.of(context).cardTheme.color?.withOpacity(0.5),
      width: 48,
      height: 48,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.0),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(12.0),
          child: Center(
            child: Icon(
              icon,
              color: enabled
                  ? colorScheme.onSurface.withOpacity(0.8)
                  : colorScheme.outline.withOpacity(0.5),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataChip({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
