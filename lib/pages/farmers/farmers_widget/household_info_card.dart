import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import './section_header.dart';
import './detail_field.dart';
import './editable_field.dart';

class HouseholdInfoCard extends StatefulWidget {
  final Map<String, dynamic> farmer;
  final bool isMobile;
  final bool isEditing;
  final ValueChanged<MapEntry<String, String>> onFieldChanged;
  final GlobalKey<FormState>? formKey;

  const HouseholdInfoCard({
    super.key,
    required this.farmer,
    this.isMobile = false,
    required this.isEditing,
    required this.onFieldChanged,
    this.formKey,
  });

  @override
  State<HouseholdInfoCard> createState() => _HouseholdInfoCardState();
}

class _HouseholdInfoCardState extends State<HouseholdInfoCard> {
  late GlobalKey<FormState> _effectiveFormKey;

  @override
  void initState() {
    super.initState();
    _effectiveFormKey = widget.formKey ?? GlobalKey<FormState>();
  }

  String getValue(String key) =>
      widget.farmer[key]?.toString() ?? 'Not Specified';

  Widget _buildNumericField({
    required String label,
    required String value,
    required String fieldKey,
    bool isRequired = false,
  }) {
    return EditableField(
      label: isRequired ? '$label*' : label,
      value: value,
      onChanged: (value) {
        widget.onFieldChanged(MapEntry(fieldKey, value));
        _effectiveFormKey.currentState?.validate();
      },
      keyboardType: TextInputType.number,
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'This field is required';
        }
        if (value != null && value.isNotEmpty) {
          final n = int.tryParse(value);
          if (n == null) {
            return 'Must be a valid number';
          }
          if (n < 0) {
            return 'Cannot be negative';
          }
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      padding: EdgeInsets.all(widget.isMobile ? 12 : 16),
      child: Form(
        key: _effectiveFormKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
                title: 'Household Information', icon: Icons.group),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: widget.isEditing
                      ? EditableField(
                          label: 'Household Head',
                          value: getValue('house_hold_head'),
                          onChanged: (value) => widget.onFieldChanged(
                              MapEntry('house_hold_head', value)),
                        )
                      : DetailField(
                          label: 'Household Head',
                          value: getValue('house_hold_head'),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: widget.isEditing
                      ? EditableField(
                          label: 'Civil Status',
                          value: getValue('civil_status'),
                          onChanged: (value) => widget
                              .onFieldChanged(MapEntry('civil_status', value)),
                        )
                      : DetailField(
                          label: 'Civil Status',
                          value: getValue('civil_status'),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            widget.isEditing
                ? EditableField(
                    label: 'Name of Spouse (if married)',
                    value: getValue('spouse_name'),
                    onChanged: (value) =>
                        widget.onFieldChanged(MapEntry('spouse_name', value)),
                  )
                : DetailField(
                    label: 'Name of Spouse (if married)',
                    value: getValue('spouse_name')),
            const SizedBox(height: 12),
            widget.isEditing
                ? EditableField(
                    label: "Mother's Maiden Name",
                    value: getValue('mother_maiden_name'),
                    onChanged: (value) => widget
                        .onFieldChanged(MapEntry('mother_maiden_name', value)),
                  )
                : DetailField(
                    label: "Mother's Maiden Name",
                    value: getValue('mother_maiden_name')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: widget.isEditing
                      ? EditableField(
                          label: 'Religion',
                          value: getValue('religion'),
                          onChanged: (value) => widget
                              .onFieldChanged(MapEntry('religion', value)),
                        )
                      : DetailField(
                          label: 'Religion', value: getValue('religion')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: widget.isEditing
                      ? _buildNumericField(
                          label: 'No. of Household Members',
                          value: getValue('household_num'),
                          fieldKey: 'household_num',
                          isRequired: true,
                        )
                      : DetailField(
                          label: 'No. of Household Members',
                          value: getValue('household_num')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: widget.isEditing
                      ? _buildNumericField(
                          label: 'No. of Male Members',
                          value: getValue('male_members_num'),
                          fieldKey: 'male_members_num',
                          isRequired: true,
                        )
                      : DetailField(
                          label: 'No. of Male Members',
                          value: getValue('male_members_num')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: widget.isEditing
                      ? _buildNumericField(
                          label: 'No. of Female Members',
                          value: getValue('female_members_num'),
                          fieldKey: 'female_members_num',
                          isRequired: true,
                        )
                      : DetailField(
                          label: 'No. of Female Members',
                          value: getValue('female_members_num')),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
