import 'package:flutter/material.dart';
import 'pin_style.dart';

class LegendPanel extends StatelessWidget {
  const LegendPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
         color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legend',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
          ),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(context).dividerColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),

          /// Dynamically generated legend items from PinStyle
          ...PinStyle.values.map(
            (style) => LegendItem(
              color: getPinColor(style),
              iconWidget: getPinIcon(style),
              label: _formatPinStyleName(style),
            ),
          ),

          const SizedBox(height: 16),

          /// Barangay
          const LegendItem(
            color: Color.fromARGB(255, 74, 72, 72),
            iconWidget: Icon(
              Icons.account_balance,
              color: Colors.white,
              size: 20,
            ),
            label: "Barangay",
          ),

          /// Area Limit
          const LegendItem(
            color: Color.fromARGB(255, 255, 17, 0),
            iconWidget: Icon(
              Icons.square_foot,
              color: Colors.white,
              size: 20,
            ),
            label: "Area Limit",
          ),

          /// Lake
          const LegendItem(
            color: Color.fromARGB(255, 59, 107, 145),
            iconWidget: Icon(
              Icons.water_drop_outlined,
              color: Colors.white,
              size: 20,
            ),
            label: "Lake",
          ),
        ],
      ),
    );
  }

  /// Pretty-print PinStyle names
  String _formatPinStyleName(PinStyle pinStyle) {
    String name = pinStyle.toString().split('.').last;

    switch (name.toLowerCase()) {
      case 'hvc':
        return 'High Value Crops';
      default:
        return name;
    }
  }
}

///////////////////////////////////////////////////////////////////////////////
/// REUSABLE LEGEND ITEM WIDGET (accepts Widget iconWidget)
///////////////////////////////////////////////////////////////////////////////
class LegendItem extends StatelessWidget {
  final Color color;
  final Widget iconWidget;
  final String label;

  const LegendItem({
    super.key,
    required this.color,
    required this.iconWidget,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: iconWidget,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
