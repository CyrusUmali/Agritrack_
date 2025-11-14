// Show sector filter popup
import 'package:flutter/material.dart';

void showSectorFilter(BuildContext context) {
  final RenderBox button = context.findRenderObject() as RenderBox;
  final RenderBox overlay =
      Overlay.of(context).context.findRenderObject() as RenderBox;
  final RelativeRect position = RelativeRect.fromRect(
    Rect.fromPoints(
      button.localToGlobal(Offset.zero, ancestor: overlay),
      button.localToGlobal(button.size.bottomRight(Offset.zero),
          ancestor: overlay),
    ),
    Offset.zero & overlay.size,
  );

  showMenu(
    context: context,
    position: position,
    items: [
      'Agriculture',
      'Fishery',
      'Livestock',
      'Rice',
      'High Value Crop',
      'Organic',
      'All Sectors',
    ].map((sector) {
      return PopupMenuItem(
        value: sector,
        child: Text(sector),
      );
    }).toList(),
  ).then((value) {
    if (value != null) {
      // Handle sector filter selection
      print('Selected sector: $value');
    }
  });
}
