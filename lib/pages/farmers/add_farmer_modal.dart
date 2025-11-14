import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/modal/modal_dialog.dart';
import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' if (dart.library.html) 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'dart:convert';
 
import 'package:flareline/pages/test/map_widget/stored_polygons.dart';

class AddFarmerModal extends StatefulWidget {
  final Function(FarmerData) onFarmerAdded;

  const AddFarmerModal({Key? key, required this.onFarmerAdded})
      : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required Function(FarmerData) onFarmerAdded,
  }) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentKey = GlobalKey<_AddFarmerModalContentState>();
    bool isLoading = false; 

    await ModalDialog.show(
      context: context,
      title: 'Add New Farmer',
      showTitle: true,
      showTitleDivider: true,
      modalType: screenWidth < 600 ? ModalType.large : ModalType.medium,
      child: _AddFarmerModalContent(
        key: contentKey,
        onLoadingStateChanged: (loading) {
          isLoading = loading;
        },
        onFarmerAdded: onFarmerAdded,
      ),
      footer: _AddFarmerModalFooter(
        onSubmit: () {
          if (contentKey.currentState != null && !isLoading) {
            contentKey.currentState!._submitFarmer();
          }
        },
        onCancel: () => Navigator.of(context).pop(),
        isLoading: isLoading,
      ),
    );
  }

  @override
  State<AddFarmerModal> createState() => _AddFarmerModalState();
}

class _AddFarmerModalState extends State<AddFarmerModal> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class FarmerData {
  final String name;
  final String email;
  final String phone;
  final String barangay;
  final String sector;
  final String? imageUrl;

  FarmerData({
    required this.name,
    required this.email,
    required this.phone,
    required this.barangay,
    required this.sector,
    this.imageUrl,
  });
}

class _AddFarmerModalContent extends StatefulWidget {
  final Function(bool) onLoadingStateChanged;
  final Function(FarmerData) onFarmerAdded;

  const _AddFarmerModalContent({
    Key? key,
    required this.onLoadingStateChanged,
    required this.onFarmerAdded,
  }) : super(key: key);

  @override
  State<_AddFarmerModalContent> createState() => _AddFarmerModalContentState();
}

class _AddFarmerModalContentState extends State<_AddFarmerModalContent> {
  late List<String> barangayNames;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController barangayController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String selectedSector = 'HVC';
  html.File? _selectedImage;
  String? _imageUrl;
  bool _isUploading = false;
  bool _isSubmitting = false;

  // Track which fields have been validated
  bool _nameValidated = false;
  bool _emailValidated = false;
  bool _phoneValidated = false;
  bool _barangayValidated = false;

  final List<String> sectors = [
    'Rice',
    'Livestock',
    'Fishery',
    'HVC',
    'Organic',
    'Corn',
  ];

  final GlobalKey barangayFieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    barangayNames = barangays.map((b) => b['name'] as String).toList();
    widget.onLoadingStateChanged(false);
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _isUploading = true;
        });

        final imageUrl = await uploadImageToCloudinary(pickedFile);

        setState(() {
          _imageUrl = imageUrl;
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() => _isUploading = false);
      rethrow;
    }
  }

  Future<String?> uploadImageToCloudinary(XFile file) async {
    const cloudName = 'dk41ykxsq';
    const uploadPreset = 'my_upload_preset';
    final url = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

    try {
      final request = http.MultipartRequest('POST', Uri.parse(url))
        ..fields['upload_preset'] = uploadPreset;

      if (kIsWeb) {
        final fileBytes = await file.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: file.name,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
        ));
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200 && jsonResponse['secure_url'] != null) {
        return jsonResponse['secure_url'];
      } else {
        throw Exception(
            'Upload failed: ${jsonResponse['error']?['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }

  void _submitFarmer() async {
    // Mark all fields as validated
    setState(() {
      _nameValidated = true;
      _emailValidated = true;
      _phoneValidated = true;
      _barangayValidated = true;
    });

    if (!_formKey.currentState!.validate()) {
      // Validation failed, don't proceed
      return;
    }

    setState(() {
      _isSubmitting = true;
      widget.onLoadingStateChanged(true);
    });

    if (_isUploading) {
      setState(() {
        _isSubmitting = false;
        widget.onLoadingStateChanged(false);
      });
      throw Exception('Please wait for image to upload');
    }

    try {
      // Create farmer data object
      final farmerData = FarmerData(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        barangay: barangayController.text.trim(),
        sector: selectedSector,
        imageUrl: _imageUrl,
      );

      // Call the callback
      widget.onFarmerAdded(farmerData);

      // Close modal after short delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          widget.onLoadingStateChanged(false);
        });
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    barangayController.dispose();
    super.dispose();
  }

  Widget _buildOptionsView(
      BuildContext context,
      AutocompleteOnSelected<String> onSelected,
      Iterable<String> options,
      GlobalKey fieldKey) {
    final RenderBox? fieldRenderBox =
        fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final double fieldWidth = fieldRenderBox?.size.width ?? 250;

    return SizedBox(
      width: fieldWidth,
      child: Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4.0,
           color: Theme.of(context).cardTheme.color,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: fieldWidth,
              maxHeight: 200,
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
                  child: Container(
                    width: fieldWidth,
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      option,
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
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fieldHeight = screenWidth < 600 ? 48.0 : 56.0;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth < 600 ? 8.0 : 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Name Field
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Full Name *',
                border: const OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  vertical: screenWidth < 600 ? 10.0 : 16.0,
                  horizontal: 10.0,
                ),
                errorStyle: const TextStyle(fontSize: 12),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.red.shade400,
                    width: 1.5,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.red.shade400,
                    width: 1.5,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the farmer\'s name';
                }
                return null;
              },
              onChanged: (value) {
                if (_nameValidated) {
                  _formKey.currentState!.validate();
                }
              },
              autovalidateMode: _nameValidated
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
            ),
            SizedBox(height: screenWidth < 600 ? 8.0 : 16.0),

            // Email Field
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: const OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  vertical: screenWidth < 600 ? 10.0 : 16.0,
                  horizontal: 10.0,
                ),
                errorStyle: const TextStyle(fontSize: 12),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.red.shade400,
                    width: 1.5,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.red.shade400,
                    width: 1.5,
                  ),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value.trim())) {
                    return 'Please enter a valid email address';
                  }
                }
                return null;
              },
              onChanged: (value) {
                if (_emailValidated) {
                  _formKey.currentState!.validate();
                }
              },
              autovalidateMode: _emailValidated
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
            ),
            SizedBox(height: screenWidth < 600 ? 8.0 : 16.0),

            // Phone Field
            TextFormField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: const OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  vertical: screenWidth < 600 ? 10.0 : 16.0,
                  horizontal: 10.0,
                ),
                errorStyle: const TextStyle(fontSize: 12),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.red.shade400,
                    width: 1.5,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.red.shade400,
                    width: 1.5,
                  ),
                ),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  if (value.trim().length < 10) {
                    return 'Phone number must be at least 10 digits';
                  }
                }
                return null;
              },
              onChanged: (value) {
                if (_phoneValidated) {
                  _formKey.currentState!.validate();
                }
              },
              autovalidateMode: _phoneValidated
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
            ),
            SizedBox(height: screenWidth < 600 ? 8.0 : 16.0),
 
            SizedBox(
              height: fieldHeight,
              child: Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
        return barangayNames;
      }
                  return barangayNames.where((String option) {
                    return option
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String value) {
                  barangayController.text = value;
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return _buildOptionsView(
                      context, onSelected, options, barangayFieldKey);
                },
                fieldViewBuilder: (BuildContext context,
                    TextEditingController textEditingController,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted) {
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'Barangay *',
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 12),
                      errorStyle: const TextStyle(fontSize: 12),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.red.shade400,
                          width: 1.5,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.red.shade400,
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please select a barangay';
                      }
                      if (!barangayNames.contains(value.trim())) {
                        return 'Please select a valid barangay';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      barangayController.text = value;
                      if (_barangayValidated) {
                        _formKey.currentState!.validate();
                      }
                    },
                    autovalidateMode: _barangayValidated
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                  );
                },
              ),
            ),
           
           
            SizedBox(height: screenWidth < 600 ? 8.0 : 16.0),

            // Sector Dropdown
            DropdownButtonFormField<String>(
              value: selectedSector,
              decoration: InputDecoration(
                labelText: 'Sector *',
                border: const OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  vertical: screenWidth < 600 ? 10.0 : 16.0,
                  horizontal: 10.0,
                ),
              ),
              dropdownColor: Theme.of(context).cardTheme.color,
              items: sectors.map((String sector) {
                return DropdownMenuItem<String>(
                  value: sector,
                  child: Text(sector),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    selectedSector = value;
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a sector';
                }
                return null;
              },
            ),
            SizedBox(height: screenWidth < 600 ? 16.0 : 24.0),

            // Image Upload Section
            if (_isUploading)
              SizedBox(
                height: 100,
                width: 100,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_imageUrl != null)
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Image.network(
                          _imageUrl!,
                          height: 150,
                          width: 150,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return SizedBox(
                              height: 150,
                              width: 150,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            height: 150,
                            width: 150,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.error,
                                size: 50, color: Colors.red),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: _pickAndUploadImage,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _pickAndUploadImage,
                    child: const Text('Change Image'),
                  ),
                ],
              )
            else
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.cloud_upload,
                        size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    const Text(
                      'Upload Farmer Photo (Optional)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'JPEG, PNG or WEBP (Max 5MB)',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _pickAndUploadImage,
                        child: const Text('Select Image'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddFarmerModalFooter extends StatelessWidget {
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  final bool isLoading;

  const _AddFarmerModalFooter({
    Key? key,
    required this.onSubmit,
    required this.onCancel,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth < 600 ? 10.0 : 20.0,
        vertical: 10.0,
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: screenWidth < 600 ? 100 : 120,
              child: ButtonWidget(
                btnText: 'Cancel',
                textColor: FlarelineColors.darkBlackText,
                onTap: isLoading ? null : onCancel,
              ),
            ),
            SizedBox(width: screenWidth < 600 ? 10 : 20),
            SizedBox(
              width: screenWidth < 600 ? 100 : 120,
              child: ButtonWidget(
                btnText: isLoading ? 'Adding...' : 'Add Farmer',
                onTap: isLoading ? null : onSubmit,
                type: ButtonType.primary.type,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
