import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import './section_header.dart';
import './detail_field.dart';
import './editable_field.dart';

class EmergencyContactsCard extends StatefulWidget {
  final Map<String, dynamic> farmer;
  final bool isMobile;
  final bool isEditing;
  final ValueChanged<MapEntry<String, String>> onFieldChanged;
  final GlobalKey<FormState>? formKey;

  const EmergencyContactsCard({
    super.key,
    required this.farmer,
    this.isMobile = false,
    required this.isEditing,
    required this.onFieldChanged,
    this.formKey,
  });

  @override
  State<EmergencyContactsCard> createState() => _EmergencyContactsCardState();
}

class _EmergencyContactsCardState extends State<EmergencyContactsCard> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    String getValue(String key) {
      final value = widget.farmer[key]?.toString();
      return (value == null || value.isEmpty) ? 'Not specified' : value;
    }

    return CommonCard(
      padding: EdgeInsets.all(widget.isMobile ? 12 : 16),
      child: Form(
        key: widget.formKey ?? _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
                title: 'Emergency Contacts', icon: Icons.emergency),
            const SizedBox(height: 16),

            // Person to Notify and Contact Number
            Row(
              children: [
                Expanded(
                  child: widget.isEditing
                      ? EditableField(
                          label: 'Person to Notify*',
                          value: getValue('person_to_notify'),
                          onChanged: (value) => widget.onFieldChanged(
                              MapEntry('person_to_notify', value)),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Person to notify is required';
                            }
                            if (value.length > 100) {
                              return 'Maximum 100 characters allowed';
                            }
                            return null;
                          },
                        )
                      : DetailField(
                          label: 'Person to Notify',
                          value: getValue('person_to_notify'),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: widget.isEditing
                      ? EditableField(
                          label: 'Contact Number*',
                          value: getValue('ptn_contact'),
                          onChanged: (value) => widget
                              .onFieldChanged(MapEntry('ptn_contact', value)),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Contact number is required';
                            }
                            if (!RegExp(r'^[0-9+]{8,15}$').hasMatch(value)) {
                              return 'Enter a valid phone number';
                            }
                            return null;
                          },
                        )
                      : DetailField(
                          label: 'Contact Number',
                          value: getValue('ptn_contact'),
                        ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Relationship
            widget.isEditing
                ? EditableField(
                    label: 'Relationship*',
                    value: getValue('ptn_relationship'),
                    onChanged: (value) => widget
                        .onFieldChanged(MapEntry('ptn_relationship', value)),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Relationship is required';
                      }
                      if (value.length > 50) {
                        return 'Maximum 50 characters allowed';
                      }
                      return null;
                    },
                  )
                : DetailField(
                    label: 'Relationship',
                    value: getValue('ptn_relationship'),
                  ),
          ],
        ),
      ),
    );
  }
}
