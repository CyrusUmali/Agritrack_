import 'package:flareline/pages/toast/toast_helper.dart';
import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flareline/pages/layout.dart';
import 'package:flutter/services.dart';

class FarmerRegistrationPage extends LayoutWidget {
  final Map<String, dynamic> farmerData;

  const FarmerRegistrationPage({super.key, required this.farmerData});

  @override
  String breakTabTitle(BuildContext context) {
    return 'Farmer Registration';
  }

  @override
  Widget contentDesktopWidget(BuildContext context) {
    return FarmerRegistrationDesktop(farmer: farmerData);
  }

  @override
  Widget contentMobileWidget(BuildContext context) {
    return FarmerRegistrationMobile(farmer: farmerData);
  }
}

class FarmerRegistrationDesktop extends StatefulWidget {
  final Map<String, dynamic> farmer;

  const FarmerRegistrationDesktop({super.key, required this.farmer});

  @override
  State<FarmerRegistrationDesktop> createState() =>
      _FarmerRegistrationDesktopState();
}

class _FarmerRegistrationDesktopState extends State<FarmerRegistrationDesktop> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Personal Info Controllers
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _extensionNameController =
      TextEditingController();
  String? _sex;
  final TextEditingController _houseNoController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _purokController = TextEditingController();
  final TextEditingController _barangayController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _birthPlaceController = TextEditingController();
  final TextEditingController _religionController = TextEditingController();
  String? _civilStatus;
  final TextEditingController _spouseNameController = TextEditingController();

  // Farm Profile Controllers
  final TextEditingController _farmDescController = TextEditingController();
  final TextEditingController _farmLocationController = TextEditingController();
  final TextEditingController _farmAreaController = TextEditingController();

  final List<String> _sexOptions = ['Male', 'Female', 'Other'];
  final List<String> _civilStatusOptions = [
    'Single',
    'Married',
    'Widowed',
    'Separated'
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with existing data if available
    _surnameController.text = widget.farmer['surname'] ?? '';
    _firstNameController.text = widget.farmer['firstName'] ?? '';
    // Initialize other fields similarly...
  }

  @override
  void dispose() {
    // Dispose all controllers
    _surnameController.dispose();
    _firstNameController.dispose();
    // Dispose other controllers...
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // TODO: Implement actual submission logic
      await Future.delayed(const Duration(seconds: 2));

      ToastHelper.showSuccessToast(
          'Registration submitted successfully!', context);
    } catch (e) {
      ToastHelper.showErrorToast('Error: $e', context);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.year}-${picked.month}-${picked.day}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header Card (same style as before)
              CommonCard(
                margin: EdgeInsets.zero,
                child: Stack(
                  children: [
                    SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: Image.asset(
                        'assets/cover/cover-01.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      bottom: 60,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: CircleAvatar(
                          radius: 72,
                          backgroundColor:
                              Theme.of(context).colorScheme.surfaceVariant,
                          child: ClipOval(
                            child: Image.asset(
                              'assets/user/user-01.png',
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          'New Farmer Registration',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                        ),
                      ),
                    ),
                    // Positioned(
                    //   top: 16,
                    //   right: 16,
                    //   child: FilledButton.tonal(
                    //     onPressed: _isSubmitting ? null : _submitForm,
                    //     child: const Row(
                    //       mainAxisSize: MainAxisSize.min,
                    //       children: [
                    //         Icon(Icons.save),
                    //         SizedBox(width: 8),
                    //         Text('Submit Registration'),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Personal Information Section
              CommonCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Name Fields
                      Row(
                        children: [
                          Expanded(
                              child: _buildTextFormField(
                                  'Surname*', _surnameController)),
                          const SizedBox(width: 16),
                          Expanded(
                              child: _buildTextFormField(
                                  'First Name*', _firstNameController)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                              child: _buildTextFormField(
                                  'Middle Name', _middleNameController)),
                          const SizedBox(width: 16),
                          Expanded(
                              child: _buildTextFormField(
                                  'Extension Name', _extensionNameController)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Sex Dropdown
                      DropdownButtonFormField<String>(
                        value: _sex,
                        decoration: const InputDecoration(
                          labelText: 'Sex*',
                          border: OutlineInputBorder(),
                        ),
                        items: _sexOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _sex = newValue;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Required field' : null,
                      ),
                      const SizedBox(height: 24),

                      // Address Section
                      Text(
                        'Address',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      _buildTextFormField(
                          'House/Lot/Bldg No*', _houseNoController),
                      _buildTextFormField('Street', _streetController),
                      _buildTextFormField('Purok', _purokController),
                      Row(
                        children: [
                          Expanded(
                              child: _buildTextFormField(
                                  'Barangay*', _barangayController)),
                          const SizedBox(width: 16),
                          Expanded(
                              child: _buildTextFormField(
                                  'City/Municipality*', _cityController)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                              child: _buildTextFormField(
                                  'Province*', _provinceController)),
                          const SizedBox(width: 16),
                          Expanded(
                              child: _buildTextFormField(
                                  'Region*', _regionController)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Contact & Birth Info
                      Text(
                        'Contact & Birth Information',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      _buildTextFormField(
                        'Mobile Number*',
                        _mobileController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _dobController,
                              decoration: const InputDecoration(
                                labelText: 'Date of Birth*',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              readOnly: true,
                              onTap: () => _selectDate(context),
                              validator: (value) => value?.isEmpty ?? true
                                  ? 'Required field'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                              child: _buildTextFormField(
                                  'Place of Birth*', _birthPlaceController)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Religion & Civil Status
                      Text(
                        'Religion & Civil Status',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                              child: _buildTextFormField(
                                  'Religion', _religionController)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _civilStatus,
                              decoration: const InputDecoration(
                                labelText: 'Civil Status',
                                border: OutlineInputBorder(),
                              ),
                              items: _civilStatusOptions.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  _civilStatus = newValue;
                                  if (newValue != 'Married') {
                                    _spouseNameController.clear();
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_civilStatus == 'Married')
                        _buildTextFormField(
                            'Name of Spouse', _spouseNameController),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Farm Profile Section
              CommonCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Farm Profile',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Farm Land Description',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _farmDescController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Farm Location',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      _buildTextFormField('Location', _farmLocationController),
                      const SizedBox(height: 16),
                      _buildTextFormField(
                        'Farm Area (in hectares)',
                        _farmAreaController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'))
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              Center(
                child: FilledButton.icon(
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white, // White spinner
                          ),
                        )
                      : const Icon(Icons.save,
                          color: Colors.white), // White icon
                  label: const Text(
                    'Accept Registration',
                    style: TextStyle(color: Colors.white), // White text
                  ),
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    foregroundColor:
                        Colors.white, // This makes icon and text white
                    backgroundColor: Colors.green, // Example background color
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: (value) {
        if (label.endsWith('*') && (value == null || value.isEmpty)) {
          return 'Required field';
        }
        return null;
      },
    );
  }
}

class FarmerRegistrationMobile extends StatefulWidget {
  final Map<String, dynamic> farmer;

  const FarmerRegistrationMobile({super.key, required this.farmer});

  @override
  State<FarmerRegistrationMobile> createState() =>
      _FarmerRegistrationMobileState();
}

class _FarmerRegistrationMobileState extends State<FarmerRegistrationMobile> {
  // Similar state and controllers as desktop version

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Mobile version of the header
            CommonCard(
              margin: EdgeInsets.zero,
              child: Stack(
                children: [
                  SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: Image.asset(
                      'assets/cover/cover-01.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceVariant,
                        child: ClipOval(
                          child: Image.asset(
                            'assets/user/user-01.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        'New Farmer Registration',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: FilledButton.tonal(
                      onPressed: () {}, // Add save functionality
                      child: const Icon(Icons.save),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mobile version of form fields
            // Similar structure but with single column layout
            // Implement similar to desktop but adjusted for mobile
          ],
        ),
      ),
    );
  }
}
