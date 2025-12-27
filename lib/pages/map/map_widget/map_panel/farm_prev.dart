import 'package:flareline/pages/map/map_widget/farm_service.dart';
import 'package:flareline/pages/map/map_widget/map_panel/farm_weather/weather_chip.dart'; 
import 'package:flareline/pages/map/map_widget/map_panel/nasa_soil_data.dart';
import 'package:flareline/pages/map/map_widget/polygon_manager.dart'; 
import 'package:flutter/material.dart';
import 'package:flareline/services/lanugage_extension.dart';
import 'package:latlong2/latlong.dart';





class InfoCard extends StatefulWidget {
  final PolygonData polygon;
  final VoidCallback onTap;
  final VoidCallback? onClose;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool showNavigation;
  final FarmService farmService;
  final int currentIndex;
  final int totalCount;
  final double left;
   final double width;
  final String? openWeatherApiKey;
  final bool showWeather;
  final GlobalKey? weatherChipKey;

  const InfoCard({
    super.key,
    required this.polygon,
    required this.onTap,
    this.onClose,
    this.onPrevious,
    required this.farmService,
    this.onNext,
    this.showNavigation = false,
    this.currentIndex = 0,
    this.totalCount = 0,
    this.openWeatherApiKey,
    this.showWeather = true,
    this.weatherChipKey, 
    required this.left , 
     required this.width
  });

  @override
  State<InfoCard> createState() => _InfoCardState();
}





class _InfoCardState extends State<InfoCard> {
  bool _isMinimized = false;
  



  void _toggleMinimize() {
    setState(() {
      _isMinimized = !_isMinimized;
    });
  }

  LatLng _getPolygonCenter() {
    final vertices = widget.polygon.vertices;
    if (vertices.isEmpty) return const LatLng(0, 0);

    double sumLat = 0;
    double sumLng = 0;

    for (var vertex in vertices) {
      sumLat += vertex.latitude;
      sumLng += vertex.longitude;
    }

    return LatLng(
      sumLat / vertices.length,
      sumLng / vertices.length,
    );
  }

  @override
  Widget build(BuildContext context) {
 
      print('left');

      print(widget.left); 

      print('width');
      print(widget.width);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    final isCompact = screenWidth < 400;
    final cardWidth = isCompact
        ? screenWidth - 32
        : (screenWidth < 500 ? screenWidth - 140 : 300.0);

    // Build chips for overlay
    final chipsWidget = _buildChipsOverlay();

    // Main card - only show if not minimized
    Widget? mainCard;
    if (!_isMinimized) {
      mainCard = Card(
        margin: const EdgeInsets.all(0),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: InkWell(
          onTap: widget.onTap,
          child: Container(
            width: cardWidth,
            padding: const EdgeInsets.all(16),
            child: _buildCardContent(theme, colorScheme, context, true),
          ),
        ),
      );
    }

    // Minimized card with chips in the same row
    final minimizedCard = _buildMinimizedCardWithChips(cardWidth, chipsWidget);

    // For non-navigation mode
    if (!widget.showNavigation) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!_isMinimized) chipsWidget,
          if (!_isMinimized) const SizedBox(height: 8),
          _isMinimized ? minimizedCard : mainCard!,
        ],
      );
    }

    // For compact mode with navigation
    if (isCompact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!_isMinimized) chipsWidget,
          if (!_isMinimized) const SizedBox(height: 8),
          _isMinimized ? minimizedCard : mainCard!,
          if (!_isMinimized) const SizedBox(height: 8),
          if (!_isMinimized) _buildCompactNavigation(),
        ],
      );
    }

    // For regular mode with navigation
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (!_isMinimized) chipsWidget,
        if (!_isMinimized) const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isMinimized)
              _buildNavigationButton(
                context: context,
                icon: Icons.chevron_left,
                onPressed: widget.onPrevious,
                enabled: widget.currentIndex > 0,
                compact: false,
              ),
            if (!_isMinimized) const SizedBox(width: 8),
            _isMinimized ? minimizedCard : mainCard!,
            if (!_isMinimized) const SizedBox(width: 8),
            if (!_isMinimized)
              _buildNavigationButton(
                context: context,
                icon: Icons.chevron_right,
                onPressed: widget.onNext,
                enabled: widget.currentIndex < widget.totalCount - 1,
                compact: false,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMinimizedCardWithChips(double cardWidth, Widget chipsWidget) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(0),
      elevation: 2,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Chips on the left

  // Minimize/Expand button
            IconButton(
              icon: Icon(
                _isMinimized ? Icons.expand_less : Icons.expand_more,
                size: 20,
                color: Colors.grey,
              ),
              onPressed: _toggleMinimize,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 20,
            ),
            const SizedBox(width: 4),

            chipsWidget,
            const SizedBox(width: 8),
          
            // Close button (if provided)
            if (widget.onClose != null)
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: 20,
                 color: Colors.grey,
                ),
                onPressed: widget.onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 20,
              ),
        
        
          ],
        ),
      ),
    );
  }

  // Remove the old _buildMinimizedCard method and use this new one instead

  Widget _buildChipsOverlay() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showWeather && widget.openWeatherApiKey != null) ...[
            _buildWeatherChip(),
            const SizedBox(width: 8),
          ],
          _buildSoilChip(),
        ],
      ),
    );
  }

  Widget _buildWeatherChip() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      child: WeatherChip( 
        left:widget.left,
        width:widget.width,
        farmService: widget.farmService,
        key: widget.weatherChipKey ?? ValueKey(widget.polygon.id),
        polygonData:widget.polygon,
        location: _getPolygonCenter(),
        apiKey: widget.openWeatherApiKey!,
        onWeatherTap: () {
          // Only minimize if not already minimized
          if (!_isMinimized) {
            _toggleMinimize();
          }
        },
        showModalOnTap: true,
      ),
    );
  }

  Widget _buildSoilChip() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      child: SoilDataChip(
        key: ValueKey(widget.polygon.id),
        location: _getPolygonCenter(),
        onSoilTap: () {
          // Only minimize if not already minimized
          if (!_isMinimized) {
            _toggleMinimize();
          }
        },
        showModalOnTap: true,
      ),
    );
  }

  Widget _buildCompactNavigation() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildNavigationButton(
          context: context,
          icon: Icons.chevron_left,
          onPressed: widget.onPrevious,
          enabled: widget.currentIndex > 0,
          compact: true,
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            '${widget.currentIndex + 1} / ${widget.totalCount}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const SizedBox(width: 8),
        _buildNavigationButton(
          context: context,
          icon: Icons.chevron_right,
          onPressed: widget.onNext,
          enabled: widget.currentIndex < widget.totalCount - 1,
          compact: true,
        ),
      ],
    );
  }

  Widget _buildCardContent(
    ThemeData theme,
    ColorScheme colorScheme,
    BuildContext context,
    bool includeCounter,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header Row
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: widget.polygon.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.polygon.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (includeCounter && MediaQuery.of(context).size.width >= 400) ...[
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.currentIndex + 1}/${widget.totalCount}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            // Minimize button instead of close button
         
            const SizedBox(width: 4),
            if (widget.onClose != null)
              InkWell(
                onTap: widget.onClose,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.close,
                    size: 20,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
          ],
        ),

        // Description
        if (widget.polygon.description != null &&
            widget.polygon.description!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            widget.polygon.description!,
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
          value:
              widget.polygon.area != null ? '${widget.polygon.area} Ha' : 'N/A',
          theme: theme,
        ),

        if (widget.polygon.parentBarangay != null) ...[
          const SizedBox(height: 8),
          _buildMetadataChip(
            icon: Icons.location_city,
            label: 'Barangay',
            value: widget.polygon.parentBarangay!,
            theme: theme,
          ),
        ],

        // Action Hint
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.translate('Tap to view details'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.expand_more,
                size: 16,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              onPressed: _toggleMinimize,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Minimize',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigationButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback? onPressed,
    required bool enabled,
    required bool compact,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final buttonSize = compact ? 40.0 : 48.0;
    final iconSize = compact ? 20.0 : 24.0;

    return Container(
      decoration: BoxDecoration(
        color: enabled
            ? Theme.of(context).cardTheme.color
            : Theme.of(context).cardTheme.color?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      width: buttonSize,
      height: buttonSize,
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
              size: iconSize,
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
