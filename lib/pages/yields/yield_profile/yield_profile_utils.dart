import 'package:flutter/material.dart';

Widget buildSectionTitle(String title, BuildContext context, {IconData? icon}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
        ),
      ],
    ),
  );
}

Widget buildResponsiveRow({
  required List<Widget> children,
  required double spacing,
  required bool isMobile,
  CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
  int? flex,
}) {
  if (isMobile) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: children
          .map((child) => Padding(
                padding: EdgeInsets.only(bottom: spacing),
                child: child,
              ))
          .toList(),
    );
  }

  return Row(
    crossAxisAlignment: crossAxisAlignment,
    children: children
        .map((child) => Expanded(
              flex: flex ?? 1,
              child: Padding(
                padding: EdgeInsets.only(right: spacing),
                child: child,
              ),
            ))
        .toList(),
  );
}

Widget buildTextField(
  String label,
  String hint,
  bool isMobile, {
  TextInputType? keyboardType,
  String? suffixText,
  String? prefixText,
  bool enabled = true,
}) {
  return TextField(
    enabled: enabled,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: EdgeInsets.symmetric(
        vertical: isMobile ? 14 : 16,
        horizontal: 12,
      ),
      prefixText: prefixText,
      suffixText: suffixText,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      fillColor: enabled ? null : Colors.grey.shade100,
    ),
  );
}

Widget buildDatePickerField(String label, bool isMobile,
    {String? value,
    bool enabled = true,
    required Future<void> Function() onTap}) {
  return TextField(
    enabled: enabled,
    controller: TextEditingController(text: value),
    decoration: InputDecoration(
      labelText: label,
      hintText: 'DD/MM/YYYY',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: EdgeInsets.symmetric(
        vertical: isMobile ? 14 : 16,
        horizontal: 12,
      ),
      suffixIcon: Icon(Icons.calendar_today, size: 20),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      fillColor: enabled ? null : Colors.grey.shade100,
    ),
    readOnly: true,
    onTap: enabled
        ? () {
            // Show date picker
          }
        : null,
  );
}

Widget buildNotesField(String value, bool isMobile, {bool enabled = true}) {
  return TextField(
    enabled: enabled,
    controller: TextEditingController(text: value),
    maxLines: isMobile ? 3 : 5,
    decoration: InputDecoration(
      labelText: "Notes & Comments",
      hintText: "Enter any additional information about the yield...",
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      fillColor: enabled ? null : Colors.grey.shade100,
    ),
  );
}

Widget buildStatusIndicator(String status, BuildContext context) {
  Color statusColor;
  switch (status.toLowerCase()) {
    case 'accepted':
      statusColor = Colors.green;
      break;
    case 'rejected':
      statusColor = Colors.red;
      break;
    case 'pending':
    default:
      statusColor = Colors.orange;
  }

  return Row(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: statusColor),
        ),
        child: Text(
          status.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    ],
  );
}
