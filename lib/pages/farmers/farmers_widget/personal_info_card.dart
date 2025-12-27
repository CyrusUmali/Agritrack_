import 'package:flareline/core/models/assocs_model.dart';
import 'package:flareline/pages/widget/combo_box.dart';
import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import './section_header.dart';
import './detail_field.dart';
import './editable_field.dart';

class PersonalInfoCard extends StatefulWidget {
  final Map<String, dynamic> farmer;
  final bool isMobile;
  final bool isEditing;
  final bool isFarmer;
  final ValueChanged<MapEntry<String, String>> onFieldChanged;
  final GlobalKey<FormState>? formKey;
  final List<String> barangayNames;
  final List<Association> assocs;

  const PersonalInfoCard({
    super.key,
    required this.farmer,
    required this.isFarmer,
    this.isMobile = false,
    required this.isEditing,
    required this.onFieldChanged,
    this.formKey,
    required this.barangayNames,
    required this.assocs,
  });

  @override
  State<PersonalInfoCard> createState() => _PersonalInfoCardState();
}

class _PersonalInfoCardState extends State<PersonalInfoCard> {
  late GlobalKey<FormState> _effectiveFormKey;
  final List<String> _sectors = ['Rice', 'Livestock', 'Fishery', 'Corn', 'HVC'];
  List<String> _assocOptions = [];
  String? _initialAssocValue; // To store the initial display value
  String? _selectedAssocValue; // To store the current selected value

  @override
  void initState() {
    super.initState();
    _effectiveFormKey = widget.formKey ?? GlobalKey<FormState>();

    // Format options with "id: name"
    _assocOptions =
        widget.assocs.map((assoc) => '${assoc.id}: ${assoc.name}').toList();

    final associationValue = widget.farmer['association'];
    if (associationValue != null && associationValue.toString().isNotEmpty) {
      final parts = associationValue.toString().split(': ');
      // Use the name part if available, otherwise use the whole value
      _initialAssocValue = parts.length > 1 ? parts[1] : parts[0];
      _selectedAssocValue = associationValue.toString();
    } else {
      _initialAssocValue = '';
      _selectedAssocValue = '';
    }
  }

  @override
  void didUpdateWidget(covariant PersonalInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.assocs != oldWidget.assocs) {
      setState(() {
        _assocOptions =
            widget.assocs.map((assoc) => '${assoc.id}: ${assoc.name}').toList();
      });
    }
  }

  String getValue(String key) {
    final value = widget.farmer[key]?.toString();
    return (value == null || value.isEmpty) ? '' : value;
  }

  Widget _buildComboBoxField({
    required String label,
    required String value,
    required List<String> options,
    required Function(String) onChanged,
    bool isRequired = false,
    double? comboBoxHeight, // Optional height for the ComboBox
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label${isRequired ? '' : ''}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        buildComboBox(
          context: context,
          hint: 'Select $label',
          options: options,
          selectedValue: value,
          onSelected: (newValue) {
            onChanged(newValue);
                    },
          width: 200,
          height: comboBoxHeight, // Pass the optional height to the ComboBox
        ),
      ],
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required String value,
    required Function(String) onChanged,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label${isRequired ? '' : ''}',
          style: const TextStyle(
            fontSize: 14, // Match EditableField label size
          ),
        ),
        const SizedBox(height: 8), // Match EditableField spacing
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: value != '' && value.isNotEmpty
                  ? DateTime.tryParse(value) ?? DateTime.now()
                  : DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              final formattedDate = picked.toIso8601String().split('T')[0];
              onChanged(formattedDate);
            }
          },
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(
              minHeight: 28, // Match EditableField height
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10), // Match EditableField padding
            decoration: BoxDecoration(
              border: Border.all(
                  color: Colors.grey[300]!), // Keep original border color
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value == '' || value.isEmpty ? 'Select Date' : value,
                    style: TextStyle(
                      fontSize: 14, // Match EditableField text size
                      color: value == '' || value.isEmpty
                          ? Colors.grey[600] // Keep original placeholder color
                          : Colors.black87, // Keep original text color
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today,
                    size: 16, color: Colors.grey), // Keep original icon
              ],
            ),
          ),
        ),
        const SizedBox(
            height: 4), // Space for error area (matching EditableField)
      ],
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
                title: 'Personal Information', icon: Icons.person),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: widget.isEditing
                      ? EditableField(
                          label: 'Surname',
                          value: getValue('surname'),
                          onChanged: (value) {
                            widget.onFieldChanged(MapEntry('surname', value));
                            _effectiveFormKey.currentState?.validate();
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Surname is required';
                            }
                            if (value.length > 50) {
                              return 'Maximum 50 characters allowed';
                            }
                            return null;
                          },
                        )
                      : DetailField(
                          label: 'Surname',
                          value: getValue('surname'),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: widget.isEditing
                      ? EditableField(
                          label: 'First Name',
                          value: getValue('firstname'),
                          onChanged: (value) {
                            widget.onFieldChanged(MapEntry('firstname', value));
                            _effectiveFormKey.currentState?.validate();
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'First name is required';
                            }
                            if (value.length > 50) {
                              return 'Maximum 50 characters allowed';
                            }
                            return null;
                          },
                        )
                      : DetailField(
                          label: 'First Name',
                          value: getValue('firstname'),
                        ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Mobile layout adjustment: Email as single item, Birthday and Contact in a row
            if (widget.isMobile) ...[


                      // Middle Name, Extension, Gender
              Row(
                children: [
                  
                  Expanded(
                    flex: 1,
                    child: widget.isEditing
                        ? EditableField(
                            label: 'Extension',
                            value: getValue('extension'),
                            onChanged: (value) {
                              widget
                                  .onFieldChanged(MapEntry('extension', value));
                            },
                          )
                        : DetailField(
                            label: 'Extension',
                            value: getValue('extension'),
                          ),
                  ),
                  const SizedBox(width: 12),


                  

                 Expanded(
                    flex: 1,
                    child: widget.isEditing
                        ? EditableField(
                            label: 'Middle Name',
                            value: getValue('middlename'),
                            onChanged: (value) {
                              widget.onFieldChanged(
                                  MapEntry('middlename', value));
                            },
                            validator: (value) {
                              if (value != null && value.length > 50) {
                                return 'Maximum 50 characters allowed';
                              }
                              return null;
                            },
                          )
                        : DetailField(
                            label: 'Middle Name',
                            value: getValue('middlename'),
                          ),
                  ),
                
          


                
                ],
              ),


 
                 
                 widget.isEditing
                        ? EditableField(
                            label: 'Sex',
                            value: getValue('sex'),
                            onChanged: (value) {
                              widget.onFieldChanged(MapEntry('sex', value));
                            },
                          )
                        : DetailField(
                            label: 'Sex',
                            value: getValue('sex'),
                          ),
            
                

 

              // Email as full width on mobile
              widget.isEditing
                  ? EditableField(
                      label: 'Email',
                      value: getValue('email'),
                      onChanged: (value) {
                        widget.onFieldChanged(MapEntry('email', value));
                      },
                    )
                  : DetailField(
                      label: 'Email',
                      value: getValue('email'),
                    ),
            

              // Birthday and Contact in a row on mobile
              Row(
                children: [
                  Expanded(
                    child: widget.isEditing
                        ? _buildDatePickerField(
                            label: 'Birthday',
                            value: getValue('birthday'),
                            onChanged: (value) {
                              widget
                                  .onFieldChanged(MapEntry('birthday', value));
                            },
                          )
                        : DetailField(
                            label: 'Birthday',
                            value: getValue('birthday'),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: widget.isEditing
                        ? EditableField(
                            label: 'Contact',
                            value: getValue('phone'),
                            onChanged: (value) {
                              widget.onFieldChanged(MapEntry('phone', value));
                              _effectiveFormKey.currentState?.validate();
                            },
                            validator: (value) {
                              if (value != null && value.length > 50) {
                                return 'Maximum 50 characters allowed';
                              }
                              return null;
                            },
                          )
                        : DetailField(
                            label: 'Contact',
                            value: getValue('phone'),
                          ),
                  ),
                ],
              ),
            ] else ...[
              // Original desktop layout

              // Middle Name, Extension, Gender
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: widget.isEditing
                        ? EditableField(
                            label: 'Middle Name',
                            value: getValue('middlename'),
                            onChanged: (value) {
                              widget.onFieldChanged(
                                  MapEntry('middlename', value));
                            },
                            validator: (value) {
                              if (value != null && value.length > 50) {
                                return 'Maximum 50 characters allowed';
                              }
                              return null;
                            },
                          )
                        : DetailField(
                            label: 'Middle Name',
                            value: getValue('middlename'),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: widget.isEditing
                        ? EditableField(
                            label: 'Extension',
                            value: getValue('extension'),
                            onChanged: (value) {
                              widget
                                  .onFieldChanged(MapEntry('extension', value));
                            },
                          )
                        : DetailField(
                            label: 'Extension',
                            value: getValue('extension'),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: widget.isEditing
                        ? EditableField(
                            label: 'Sex',
                            value: getValue('sex'),
                            onChanged: (value) {
                              widget.onFieldChanged(MapEntry('sex', value));
                            },
                          )
                        : DetailField(
                            label: 'Sex',
                            value: getValue('sex'),
                          ),
                  ),
                ],
              ),
 

              Row(
                children: [
                  Expanded(
                    child: DetailField(
                      label: 'Email',
                      value: getValue('email'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: widget.isEditing
                        ? _buildDatePickerField(
                            label: 'Birthday',
                            value: getValue('birthday'),
                            onChanged: (value) {
                              widget
                                  .onFieldChanged(MapEntry('birthday', value));
                            },
                          )
                        : DetailField(
                            label: 'Birthday',
                            value: getValue('birthday'),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: widget.isEditing
                        ? EditableField(
                            label: 'Contact',
                            value: getValue('phone'),
                            onChanged: (value) {
                              widget.onFieldChanged(MapEntry('phone', value));
                              _effectiveFormKey.currentState?.validate();
                            },
                            validator: (value) {
                              if (value != null && value.length > 50) {
                                return 'Maximum 50 characters allowed';
                              }
                              return null;
                            },
                          )
                        : DetailField(
                            label: 'Contact',
                            value: getValue('phone'),
                          ),
                  ),
                ],
              ),
            ],
 

            Row(
              children: [
                Expanded(
                  child: widget.isEditing
                      ? _buildComboBoxField(
                          comboBoxHeight: 38,
                          label: 'Barangay',
                          value: getValue('barangay'),
                          options: widget.barangayNames,
                          onChanged: (value) {
                            widget.onFieldChanged(MapEntry('barangay', value));
                          },
                          isRequired: true,
                        )
                      : DetailField(
                          label: 'Barangay',
                          value: getValue('barangay'),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: widget.isEditing
                      ? _buildComboBoxField(
                          label: 'Sector',
                          value: getValue('sector'),
                          options: _sectors,
                          comboBoxHeight: 38,
                          onChanged: (value) {
                            widget.onFieldChanged(MapEntry('sector', value));
                          },
                          isRequired: true,
                        )
                      : DetailField(
                          label: 'Sector',
                          value: getValue('sector'),
                        ),
                ),
              ],
            ),
 

            Row(
              children: [
                Expanded(
                  child: widget.isEditing
                      ? _buildComboBoxField(
                          label: 'Association',
                          comboBoxHeight: 38,
                          value: _selectedAssocValue ?? '',
                          options: _assocOptions,
                          onChanged: (value) {
                            setState(() {
                              _selectedAssocValue = value;
                            });
                            widget
                                .onFieldChanged(MapEntry('association', value));
                            if (value != '') {
                              final id = value.split(':').first.trim();
                              widget.onFieldChanged(
                                  MapEntry('associationId', id));
                            }
                          },
                        )
                      : DetailField(
                          label: 'Association',
                          value: _initialAssocValue ?? '',
                        ),
                ),
                // Show Account Status for everyone, but only editable for non-farmers
                const SizedBox(width: 12),
                Expanded(
                  child: widget.isEditing && !widget.isFarmer
                      ? _buildComboBoxField(
                          comboBoxHeight: 38,
                          label: 'Account Status',
                          value: getValue('accountStatus'),
                          options: const [
                            'Active',
                            'Pending',
                            'Inactive',
                          ],
                          onChanged: (value) {
                            widget.onFieldChanged(
                                MapEntry('accountStatus', value));
                          },
                        )
                      : DetailField(
                          label: 'Account Status',
                          value: getValue('accountStatus'),
                        ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
