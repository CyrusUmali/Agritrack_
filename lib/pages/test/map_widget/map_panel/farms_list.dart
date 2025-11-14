import 'package:flareline/pages/test/map_widget/pin_style.dart';
import 'package:flutter/material.dart';
import '../polygon_manager.dart';

class FarmsList {
  static Widget build({
    required PolygonData barangay,
    required List<PolygonData> farms,
    required ThemeData theme,
    required PolygonManager polygonManager,
    required BuildContext modalContext,
    required ValueKey<String> key,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Farms in ${barangay.name}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                if (farms.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${farms.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (farms.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No farms found',
                    style: TextStyle(
                      color: Colors.grey.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Try adjusting your filters',
                    style: TextStyle(
                      color: Colors.grey.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: farms.length,
              itemBuilder: (context, index) {
                final farm = farms[index];
                final originalIndex = polygonManager.polygons.indexOf(farm);
                final exceedsLimit =
                    polygonManager.polygonExceedsAreaLimit(farm);

                // Build polygon preview with warning indicator
                Widget buildPolygonPreview(PolygonData polygon) {
                  final exceedsLimit =
                      polygonManager.polygonExceedsAreaLimit(polygon);
                  final color = getPinColor(polygon.pinStyle);

                  return Stack(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          color: color.withOpacity(0.3),
                          border: Border.all(
                            color: exceedsLimit ? Colors.red : color,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: getPinIcon(polygon.pinStyle),
                        ),
                      ),
                      if (exceedsLimit)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: Icon(
                              Icons.square_foot,
                              color: Colors.white,
                              size: 8,
                            ),
                          ),
                        ),
                    ],
                  );
                }

                return Container(
                  margin: EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    leading: buildPolygonPreview(farm),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            farm.name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: exceedsLimit ? Colors.red : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (farm.area != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${farm.area!.toStringAsFixed(1)} ha',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (farm.owner != null)
                          Text(
                            'Owner: ${farm.owner}',
                            style: TextStyle(fontSize: 12),
                          ),
                        if (farm.products != null && farm.products!.isNotEmpty)
                          Text(
                            'Products: ${farm.products!.join(', ')}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (exceedsLimit)
                          Row(
                            children: [
                              Icon(Icons.square_foot,
                                  size: 12, color: Colors.red),
                              SizedBox(width: 4),
                              Text(
                                'Area exceeds limit',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    tileColor: polygonManager.selectedPolygonIndex ==
                            originalIndex
                        ? theme.colorScheme.primary.withOpacity(0.2)
                        : (exceedsLimit ? Colors.red.withOpacity(0.05) : null),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () {
                      final overlayContext =
                          Navigator.of(context, rootNavigator: true).context;
                      polygonManager.selectPolygon(
                        originalIndex,
                        context: overlayContext,
                      );
                      Navigator.of(modalContext).pop();
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
