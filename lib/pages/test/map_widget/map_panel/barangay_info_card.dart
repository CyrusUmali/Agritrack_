import 'package:flutter/material.dart';
import '../polygon_manager.dart';

class BarangayInfoCard {
  static Widget build({
    required BuildContext context,
    required PolygonData barangay,
    required List<PolygonData> farms,
    required ThemeData theme,
    bool elevated = true,
  }) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1024;
    final isDesktop = size.width >= 1024;

    // Calculate statistics
    final totalArea = farms.fold<double>(0, (sum, farm) => sum + (farm.area ?? 0));
    final farmCount = farms.length;
    final farmerCount = farms.map((f) => f.farmerId).toSet().length;

    return Card(
      // margin: EdgeInsets.symmetric(
      //   horizontal: isMobile ? 16 : (isTablet ? 12 : 8),
      //   vertical: isMobile ? 8 : (isTablet ? 6 : 4),
      // ),
      elevation: elevated ? (isMobile ? 3 : 2) : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 12 : 10),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(isMobile ? 12 : 10),
        onTap: () {},
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : (isTablet ? 14 : 12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
         
              SizedBox(height: isMobile ? 12 : (isTablet ? 10 : 8)),

          
              // Stats Grid - responsive layout
              _buildStatsGrid(
                context, 
                theme, 
                isMobile, 
                isTablet, 
                isDesktop,
                totalArea: totalArea,
                farmCount: farmCount,
                farmerCount: farmerCount,
              ),

            
      
            ],
          ),
        ),
      ),
    );
  }
 
  static Widget _buildStatsGrid(
    BuildContext context,
    ThemeData theme,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
    {
      required double totalArea,
      required int farmCount,
      required int farmerCount,
    }
  ) {
    final crossAxisCount = isMobile ? 2 : 3;
    final childAspectRatio = isMobile ? 2.0 : (isTablet ? 2.8 : 6.5);

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: childAspectRatio,
      mainAxisSpacing: isMobile ? 8 : (isTablet ? 6 : 4),
      crossAxisSpacing: isMobile ? 8 : (isTablet ? 6 : 4),
      children: [
        _buildStatItem(
          icon: Icons.landscape,
          label: 'Total Area',
          value: '${totalArea.toStringAsFixed(2)} ha',
          theme: theme,
          isMobile: isMobile,
          isTablet: isTablet,
          isDesktop: isDesktop,
        ),
        _buildStatItem(
          icon: Icons.home_work_outlined,
          label: 'Farms',
          value: farmCount.toString(),
          theme: theme,
          isMobile: isMobile,
          isTablet: isTablet,
          isDesktop: isDesktop,
        ),
        _buildStatItem(
          icon: Icons.people_outline,
          label: 'Farmers',
          value: farmerCount.toString(),
          theme: theme,
          isMobile: isMobile,
          isTablet: isTablet,
          isDesktop: isDesktop,
        ),
      ],
    );
  }

 

  static Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    return Tooltip(
      message: '$label: $value',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isMobile ? 18 : (isTablet ? 16 : 14),
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          SizedBox(width: isMobile ? 8 : (isTablet ? 6 : 4)),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style:
                      _getLabelTextStyle(theme, isMobile, isTablet, isDesktop),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style:
                      _getValueTextStyle(theme, isMobile, isTablet, isDesktop),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }





  
  static TextStyle? _getValueTextStyle(
    ThemeData theme,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    if (isMobile) {
      return theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500,
      );
    } else {
      return theme.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: isTablet ? 13 : 12,
      );
    }
  }

  static TextStyle? _getLabelTextStyle(
    ThemeData theme,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    if (isMobile) {
      return theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.6),
      );
    } else {
      return theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.6),
        fontSize: isTablet ? 12 : 11,
      );
    }
  }


 


} 