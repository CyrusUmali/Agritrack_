import 'package:flareline/pages/test/map_widget/polygon_manager.dart';
import 'package:flutter/material.dart';
import 'package:flareline/services/lanugage_extension.dart';

class LakeInfoCard extends StatelessWidget {
  final PolygonData lake;
  final List<PolygonData> farmsInLake;
  final VoidCallback onTap;
  final VoidCallback? onClose; // NEW: Add onClose callback

  const LakeInfoCard({
    Key? key,
    required this.lake,
    required this.farmsInLake,
    required this.onTap,
    this.onClose, // NEW: Add to constructor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
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
                      color: lake.color,
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
                      lake.name,
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

              // Farms Count
              const SizedBox(height: 12),
              _buildMetadataChip(
                icon: Icons.agriculture,
                label: 'Fish Cages',
                value: farmsInLake.length.toString(),
                theme: theme,
              ),

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

  Widget _buildMetadataChip({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(),
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
