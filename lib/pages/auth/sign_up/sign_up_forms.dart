import 'package:flareline/pages/auth/sign_up/sign_up_provider.dart';
import 'package:flareline/pages/sectors/sector_service.dart';
import 'package:flareline/pages/test/map_widget/stored_polygons.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flareline_uikit/components/forms/outborder_text_form_field.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignUpForms {
  // FIXED: Move form keys to static level to persist across rebuilds
  static final _accountFormKey = GlobalKey<FormState>();
  static final _personalFormKey = GlobalKey<FormState>();
  static final _householdFormKey = GlobalKey<FormState>();
  static final _contactFormKey = GlobalKey<FormState>();

  // Helper method to extract display value (removes number prefix)
  static String _getDisplayValue(String value) {
    if (value.contains(':')) {
      return value.split(':')[1];
    }
    return value;
  }

  // Helper method to get full value from display value
  static String? _getFullValue(String displayValue, List<String> options) {
    return options.firstWhere(
      (option) => _getDisplayValue(option) == displayValue,
      orElse: () => displayValue,
    );
  }

  static Widget buildFormContent(
      BuildContext context, SignUpProvider viewModel, bool isMobile) {
    // FIXED: Remove KeyedSubtree as it's causing unnecessary recreations
    switch (viewModel.currentStep) {
      case 0:
        return _buildAccountForm(context, viewModel, isMobile);
      case 1:
        return _buildPersonalForm(context, viewModel, isMobile);
      case 2:
        return _buildHouseholdForm(context, viewModel, isMobile);
      case 3:
        return _buildContactForm(context, viewModel, isMobile);
      default:
        return Container();
    }
  }

  static Widget _buildAccountForm(
      BuildContext context, SignUpProvider viewModel, bool isMobile) {
    // FIXED: Use static form key instead of creating new one
    return Form(
      key: _accountFormKey,
      child: Column(
        children: [
          OutBorderTextFormField(
            labelText: "Email",
            hintText: "Enter your email",
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }

              final email = value.trim();

              // Practical regex for common email formats
              final emailRegex = RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$',
              );

              if (!emailRegex.hasMatch(email)) {
                return 'Enter a valid email address';
              }

              return null;
            },
            maxLength: 100,
            controller: viewModel.emailController,
          ),
          const SizedBox(height: 16),
          OutBorderTextFormField(
            obscureText: true,
            labelText: "Password",
            hintText: "Enter your password",
            keyboardType: TextInputType.visiblePassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
            maxLength: 50,
            controller: viewModel.passwordController,
          ),
          const SizedBox(height: 16),
          OutBorderTextFormField(
            obscureText: true,
            labelText: "Confirm Password",
            hintText: "Re-enter your password",
            keyboardType: TextInputType.visiblePassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != viewModel.passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            maxLength: 50,
            controller: viewModel.rePasswordController,
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment:
                isMobile ? MainAxisAlignment.center : MainAxisAlignment.end,
            children: [
              SizedBox(
                width: isMobile ? 150 : 400,
                height: 50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ButtonWidget(
                    type: ButtonType.primary.type,
                    btnText: "Next ",
                    onTap: () {
                      if (_accountFormKey.currentState!.validate()) {
                        viewModel.nextStep();
                      }
                    },
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  static Widget _buildPersonalForm(
      BuildContext context, SignUpProvider viewModel, bool isMobile) {
    // FIXED: Use static form key
    return Form(
      key: _personalFormKey,
      child: Column(
        children: [
          if (isMobile) ...[
            Text(
              "Personal Information",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
          ],
          OutBorderTextFormField(
            labelText: "First Name",
            hintText: "Enter your first name",
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'First name is required';
              }
              return null;
            },
            maxLength: 50,
            controller: viewModel.firstNameController,
          ),
          const SizedBox(height: 16),
          OutBorderTextFormField(
            labelText: "Middle Name",
            hintText: "Enter your middle name",
            maxLength: 50,
            controller: viewModel.middleNameController,
          ),
          const SizedBox(height: 16),
          OutBorderTextFormField(
            labelText: "Last Name",
            hintText: "Enter your last name",
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Last name is required';
              }
              return null;
            },
            maxLength: 50,
            controller: viewModel.lastNameController,
          ),
          const SizedBox(height: 16),
          OutBorderTextFormField(
            labelText: "Name Extension (e.g. Jr, Sr)",
            hintText: "Enter name extension if applicable",
            maxLength: 10,
            controller: viewModel.extensionController,
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            label: "Sex",
            value: viewModel.sex,
            items: ['Male', 'Female', 'Other'],
            onChanged: (value) => viewModel.sex = value,
            isRequired: true,
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            label: "Civil Status",
            value: viewModel.civilStatus,
            items: ['Single', 'Married', 'Widowed', 'Separated', 'Divorced'],
            onChanged: (value) => viewModel.civilStatus = value,
          ),
          const SizedBox(height: 16),
          OutBorderTextFormField(
            labelText: "Spouse Name (if married)",
            hintText: "Enter spouse name if applicable",
            maxLength: 100,
            controller: viewModel.spouseNameController,
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ButtonWidget(
                    type: ButtonType.primary.type,
                    btnText: "Back",
                    onTap: viewModel.previousStep,
                  ),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: ButtonWidget(
                    type: ButtonType.primary.type,
                    btnText: "Next",
                    onTap: () {
                      if (_personalFormKey.currentState!.validate()) {
                        viewModel.nextStep();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  static Widget _buildHouseholdForm(
      BuildContext context, SignUpProvider viewModel, bool isMobile) {
    // FIXED: Use static form key
    return Form(
      key: _householdFormKey,
      child: Column(
        children: [
          if (isMobile) ...[
            Text(
              "Household Information",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
          ],
          OutBorderTextFormField(
            labelText: "Household Head",
            hintText: "Enter name of household head",
            maxLength: 100,
            controller: viewModel.householdHeadController,
          ),
          const SizedBox(height: 16),
          OutBorderTextFormField(
            labelText: "Number of Household Members",
            hintText: "Enter total number",
            keyboardType: TextInputType.number,
            maxLength: 3,
            controller: viewModel.householdNumController,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutBorderTextFormField(
                  labelText: "Male Members",
                  hintText: "Number of males",
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  controller: viewModel.maleMembersController,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: OutBorderTextFormField(
                  labelText: "Female Members",
                  hintText: "Number of females",
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  controller: viewModel.femaleMembersController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutBorderTextFormField(
            labelText: "Mother's Maiden Name",
            hintText: "Enter your mother's maiden name",
            maxLength: 100,
            controller: viewModel.motherMaidenNameController,
          ),
          const SizedBox(height: 16),
          OutBorderTextFormField(
            labelText: "Religion",
            hintText: "Enter your religion",
            maxLength: 50,
            controller: viewModel.religionController,
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ButtonWidget(
                    type: ButtonType.primary.type,
                    btnText: "Back",
                    onTap: viewModel.previousStep,
                  ),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: ButtonWidget(
                    type: ButtonType.primary.type,
                    btnText: "Next",
                    onTap: () {
                      if (_householdFormKey.currentState!.validate()) {
                        viewModel.nextStep();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  static Widget _buildContactForm(
      BuildContext context, SignUpProvider viewModel, bool isMobile) {
    // FIXED: Use static form key
    final List<String> barangayNames =
        barangays.map((b) => b['name'] as String).toList();

    final associationOptions = viewModel.associationOptions;

    if (viewModel.isLoadingAssociations) {
      return Center(child: CircularProgressIndicator());
    }

    final List<String> sectorOptions = [
      '1:Rice',
      '2:Corn',
      '3:HVC',
      '4:Livestock',
      '5:Fishery',
      '6:Organic',
    ];

    // Get display values for associations and sectors
    final List<String> associationDisplayOptions =
        associationOptions.map((opt) => _getDisplayValue(opt)).toList();
    final List<String> sectorDisplayOptions =
        sectorOptions.map((opt) => _getDisplayValue(opt)).toList();

    return Form(
      key: _contactFormKey,
      child: Column(
        children: [
          if (isMobile) ...[
            Text(
              "Contact Information",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
          ],
          // Fixed Autocomplete field
          _buildDropdownAutocomplete(
            label: "Barangay",
            hintText: "Select your barangay",
            options: barangayNames,
            controller: viewModel.barangayController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Barangay is required';
              }
              if (!barangayNames.contains(value)) {
                return 'Please select a valid barangay';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          _buildDropdownAutocompleteWithMapping(
            label: "Association",
            hintText: "Select Association",
            displayOptions: associationDisplayOptions,
            fullOptions: associationOptions,
            controller: viewModel.associationController,
            validator: (value) {
              if (value != null &&
                  value.isNotEmpty &&
                  !associationOptions.contains(value)) {
                return 'Please select a valid Association';
              }
              return null;
            },
          ),

          // FIXED: Only show error widget when there's actually an error
          if (viewModel.associationsLoadError != null) ...[
            const SizedBox(height: 16),
            _buildAssociationErrorRetryWidget(context, viewModel),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 16),

          _buildDropdownFieldWithMapping(
            label: "Sector",
            value: viewModel.sectorController.text.isNotEmpty
                ? viewModel.sectorController.text
                : null,
            fullOptions: sectorOptions,
            displayOptions: sectorDisplayOptions,
            onChanged: (value) {
              viewModel.sectorController.text = value ?? '';
            },
            isRequired: true,
          ),
          const SizedBox(height: 16),
          OutBorderTextFormField(
            labelText: "Address",
            hintText: "Enter your complete address",
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Address is required';
              }
              return null;
            },
            maxLength: 200,
            controller: viewModel.addressController,
          ),
          const SizedBox(height: 16),
          OutBorderTextFormField(
            labelText: "Phone Number",
            hintText: "Enter your phone number",
            keyboardType: TextInputType.phone,
            maxLength: 20,
            controller: viewModel.phoneController,
          ),
          const SizedBox(height: 24),
          Text(
            "Emergency Contact Information",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          OutBorderTextFormField(
            labelText: "Person to Notify",
            hintText: "Enter full name",
            maxLength: 100,
            controller: viewModel.personToNotifyController,
          ),
          const SizedBox(height: 16),
          OutBorderTextFormField(
            labelText: "Contact Number",
            hintText: "Enter contact number",
            keyboardType: TextInputType.phone,
            maxLength: 20,
            controller: viewModel.ptnContactController,
          ),
          const SizedBox(height: 16),
          OutBorderTextFormField(
            labelText: "Relationship",
            hintText: "Enter relationship (e.g. Spouse, Child)",
            maxLength: 50,
            controller: viewModel.ptnRelationshipController,
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ButtonWidget(
                    type: ButtonType.primary.type,
                    btnText: "Back",
                    onTap: viewModel.previousStep,
                  ),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: ButtonWidget(
                    type: ButtonType.primary.type,
                    btnText: "Submit Registration",
                    onTap: () {
                      if (_contactFormKey.currentState!.validate()) {
                        viewModel.nextStep();
                        viewModel.signUp(context);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Add this method to handle association loading errors
  static Widget _buildAssociationErrorRetryWidget(
      BuildContext context, SignUpProvider viewModel) {
    return LayoutBuilder(builder: (context, constraints) {
      final isDesktop = constraints.maxWidth > 1000;

      return Container(
        width: isDesktop ? 130 : double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              'Failed to load associations',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            ElevatedButton(
              onPressed: () {
                final sectorService =
                    RepositoryProvider.of<SectorService>(context);
                viewModel.loadAssociations(sectorService);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
              ),
              child: Text(
                'Retry',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      );
    });
  }

  static Widget _buildDropdownAutocomplete({
    required String label,
    required String hintText,
    required List<String> options,
    required TextEditingController controller,
    required String? Function(String?) validator,
    double maxHeight = 200.0,
    double maxWidth = 400.0,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w100,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        // Use RawAutocomplete for better control
        RawAutocomplete<String>(
          textEditingController: controller,
          focusNode: FocusNode(), // Provide explicit focus node
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return options;
            }
            return options.where((String option) {
              return option
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase());
            });
          },
          onSelected: (String selection) {
            controller.text = selection;
          },
          fieldViewBuilder: (
            BuildContext context,
            TextEditingController fieldTextEditingController,
            FocusNode fieldFocusNode,
            VoidCallback onFieldSubmitted,
          ) {
            // Sync controllers only when needed
            if (controller.text != fieldTextEditingController.text &&
                fieldTextEditingController.text.isEmpty) {
              fieldTextEditingController.text = controller.text;
            }

            return TextFormField(
              controller: fieldTextEditingController,
              focusNode: fieldFocusNode,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w100,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w100,
                ),
                // Apply OutBorderTextFormField border styling
                border: const OutlineInputBorder(
                  borderSide:
                      BorderSide(color: FlarelineColors.border, width: 1),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide:
                      BorderSide(color: FlarelineColors.border, width: 1),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide:
                      BorderSide(color: FlarelineColors.primary, width: 1),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.redAccent, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.redAccent, width: 1),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                suffixIcon: Icon(Icons.arrow_drop_down),
                errorStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w100,
                  color: Colors.redAccent,
                ),
                isDense: true,
              ),
              validator: validator,
              onChanged: (value) {
                // Update the main controller when typing
                if (controller.text != value) {
                  controller.text = value;
                }
              },
            );
          },
          optionsViewBuilder: (
            BuildContext context,
            AutocompleteOnSelected<String> onSelected,
            Iterable<String> options,
          ) {
            return Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: maxWidth,
                child: Material(
                  elevation: 4.0,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: maxHeight,
                      maxWidth: maxWidth,
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final String option = options.elementAt(index);
                        return InkWell(
                          onTap: () {
                            onSelected(option);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w100,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // New autocomplete with display/full value mapping
  static Widget _buildDropdownAutocompleteWithMapping({
    required String label,
    required String hintText,
    required List<String> displayOptions,
    required List<String> fullOptions,
    required TextEditingController controller,
    required String? Function(String?) validator,
    double maxHeight = 200.0,
    double maxWidth = 400.0,
  }) {
    // Create a display controller for showing text without numbers
    final displayController = TextEditingController(
      text: controller.text.isNotEmpty ? _getDisplayValue(controller.text) : '',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w100,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        RawAutocomplete<String>(
          textEditingController: displayController,
          focusNode: FocusNode(),
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return displayOptions;
            }
            return displayOptions.where((String option) {
              return option
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase());
            });
          },
          onSelected: (String displaySelection) {
            // Find the full value and store it
            final fullValue = _getFullValue(displaySelection, fullOptions);
            controller.text = fullValue ?? displaySelection;
            displayController.text = displaySelection;
          },
          fieldViewBuilder: (
            BuildContext context,
            TextEditingController fieldTextEditingController,
            FocusNode fieldFocusNode,
            VoidCallback onFieldSubmitted,
          ) {
            return TextFormField(
              controller: fieldTextEditingController,
              focusNode: fieldFocusNode,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w100,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w100,
                ),
                border: const OutlineInputBorder(
                  borderSide:
                      BorderSide(color: FlarelineColors.border, width: 1),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide:
                      BorderSide(color: FlarelineColors.border, width: 1),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide:
                      BorderSide(color: FlarelineColors.primary, width: 1),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.redAccent, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.redAccent, width: 1),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                suffixIcon: Icon(Icons.arrow_drop_down),
                errorStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w100,
                  color: Colors.redAccent,
                ),
                isDense: true,
              ),
              validator: (value) {
                // Validate using the full value
                return validator(controller.text);
              },
              onChanged: (value) {
                displayController.text = value;
              },
            );
          },
          optionsViewBuilder: (
            BuildContext context,
            AutocompleteOnSelected<String> onSelected,
            Iterable<String> options,
          ) {
            return Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: maxWidth,
                child: Material(
                  elevation: 4.0,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: maxHeight,
                      maxWidth: maxWidth,
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final String option = options.elementAt(index);
                        return InkWell(
                          onTap: () {
                            onSelected(option);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w100,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // New dropdown with display/full value mapping
  static Widget _buildDropdownFieldWithMapping({
    required String label,
    required String? value,
    required List<String> fullOptions,
    required List<String> displayOptions,
    required Function(String?) onChanged,
    bool isRequired = false,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: FlarelineColors.border, width: 1),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: FlarelineColors.border, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: FlarelineColors.primary, width: 1),
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        errorStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w100,
          color: Colors.redAccent,
        ),
        isDense: true,
      ),
      items: fullOptions.asMap().entries.map((entry) {
        final fullValue = entry.value;
        final displayValue = displayOptions[entry.key];
        return DropdownMenuItem<String>(
          value: fullValue,
          child: Text(displayValue),
        );
      }).toList(),
      onChanged: onChanged,
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Please select $label';
              }
              return null;
            }
          : null,
      isExpanded: true,
    );
  }

  static Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    bool isRequired = false,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        // Apply OutBorderTextFormField border styling
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: FlarelineColors.border, width: 1),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: FlarelineColors.border, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: FlarelineColors.primary, width: 1),
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        errorStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w100,
          color: Colors.redAccent,
        ),
        isDense: true,
      ),
      items: items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: onChanged,
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Please select $label';
              }
              return null;
            }
          : null,
      isExpanded: true,
    );
  }
}
