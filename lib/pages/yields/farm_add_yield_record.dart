 
import 'package:flareline/core/models/product_model.dart'; 
import 'package:flareline/pages/toast/toast_helper.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/modal/modal_dialog.dart';
import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flareline/services/lanugage_extension.dart';
import 'dart:convert';
import 'package:provider/provider.dart';

class AddYieldModalForFarm extends StatefulWidget {
  final Function(
    int cropTypeId,
    double yieldAmount,
    double? areaHa,
    DateTime date,
    String notes,
    List<String> imageUrls,
  ) onYieldAdded;

  const AddYieldModalForFarm({super.key, required this.onYieldAdded});

  static Future<void> show({
    required BuildContext context,
    required List<Product> products,
    required int farmerId,
    required int farmId, 
    double? farmArea,
     bool farmerSpecific = false,
    String? farmSector,
    List<Map<String, double>>? farmVertices,
    required Function(
      int cropTypeId,
      double yieldAmount,
      double? areaHa,
      DateTime date,
      String notes,
      List<String> imageUrls,
    ) onYieldAdded,
  }) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final screenWidth = MediaQuery.of(context).size.width;
    final contentKey = GlobalKey<_AddYieldModalForFarmContentState>();
    bool isLoading = false;

    await ModalDialog.show(
      context: context,
      title: 'Add Yield Record', 
      showTitle: true,
      showTitleDivider: true,
      modalType: screenWidth < 600 ? ModalType.large : ModalType.medium,
      child: _AddYieldModalForFarmContent(
        key: contentKey,
        onLoadingStateChanged: (loading) {
          isLoading = loading;
        },
        onYieldAdded: onYieldAdded,
        products: products,
        userProvider: userProvider,
        farmerId: farmerId,
        farmId: farmId, 
        farmArea: farmArea,
        farmSector: farmSector,
        farmVertices: farmVertices,
      ),
      footer: _AddYieldModalForFarmFooter(
        onSubmit: () {
          if (contentKey.currentState != null && !isLoading) {
            contentKey.currentState!._submitYield();
          }
        },
        onCancel: () => Navigator.of(context).pop(),
        isLoading: isLoading,
      ),
    );
  }

  @override
  State<AddYieldModalForFarm> createState() => _AddYieldModalForFarmState();
}

class _AddYieldModalForFarmState extends State<AddYieldModalForFarm> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _AddYieldModalForFarmContent extends StatefulWidget {
  final Function(bool) onLoadingStateChanged;
  final Function(
    int cropTypeId,
    double yieldAmount,
    double? areaHa,
    DateTime date,
    String notes,
    List<String> imageUrls,
  ) onYieldAdded;
  final List<Product> products;
  final UserProvider userProvider;
  final int farmerId;
  final int farmId; 
  final double? farmArea;
  final String? farmSector;
  final List<Map<String, double>>? farmVertices;

  const _AddYieldModalForFarmContent({
    super.key,
    required this.onLoadingStateChanged,
    required this.onYieldAdded,
    required this.products,
    required this.userProvider,
    required this.farmerId,
    required this.farmId, 
    this.farmArea,
    this.farmSector,
    this.farmVertices,
  });

  @override
  State<_AddYieldModalForFarmContent> createState() => _AddYieldModalForFarmContentState();
}

class _AddYieldModalForFarmContentState extends State<_AddYieldModalForFarmContent> {
  final TextEditingController yieldAmountController = TextEditingController();
  final TextEditingController areaHaController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); 
  DateTime selectedDate = DateTime.now();
  Product? selectedProduct;
  List<XFile> selectedImages = [];
  bool isSubmitting = false;

  bool _cropTypeValidated = false;
  bool _areaHaValidated = false;
  bool _yieldAmountValidated = false;

  final GlobalKey cropTypeFieldKey = GlobalKey();

 

  @override
  void initState() {
    super.initState();
    // Pre-fill area from farm if available
    if (widget.farmArea != null && widget.farmArea! > 0) {
      areaHaController.text = widget.farmArea!.toString();
    }
  }
 

  Future<List<String>> _uploadImagesToCloudinary() async {
    const cloudName = 'dk41ykxsq';
    const uploadPreset = 'my_upload_preset';
    final List<String> imageUrls = [];

    for (final image in selectedImages) {
      try {
        final url = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
        final request = http.MultipartRequest('POST', Uri.parse(url))
          ..fields['upload_preset'] = uploadPreset;

        if (kIsWeb) {
          final fileBytes = await image.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'file',
            fileBytes,
            filename: image.name,
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'file',
            image.path,
          ));
        }

        final response = await request.send();
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);

        if (response.statusCode == 200 && jsonResponse['secure_url'] != null) {
          imageUrls.add(jsonResponse['secure_url']);
        } else {
          throw Exception(
              'Upload failed: ${jsonResponse['error']?['message'] ?? 'Unknown error'}');
        }
      } catch (e) {
        debugPrint('Error uploading image: $e');
        rethrow;
      }
    }

    return imageUrls;
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (images.isNotEmpty) {
        setState(() {
          selectedImages.addAll(images);
          if (selectedImages.length > 5) {
            selectedImages = selectedImages.sublist(0, 5);
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
      rethrow;
    }
  }

  Widget _buildImagePreview() {
    if (selectedImages.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attached Images:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: selectedImages.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: kIsWeb
                        ? Image.network(selectedImages[index].path)
                        : Image.file(File(selectedImages[index].path)),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        setState(() {
                          selectedImages.removeAt(index);
                        });
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
 
  Widget _buildOptionsView<T extends Object>(
    BuildContext context,
    AutocompleteOnSelected<T> onSelected,
    Iterable<T> options,
    GlobalKey fieldKey,
    String Function(T) displayString,
  ) {
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
                final T option = options.elementAt(index);
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
                      displayString(option),
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

  void _submitYield() async {
    setState(() {
      _cropTypeValidated = true;
      _yieldAmountValidated = true;
      _areaHaValidated = true;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSubmitting = true;
      widget.onLoadingStateChanged(true);
    });

    try {
      List<String> imageUrls = [];
      if (selectedImages.isNotEmpty) {
        imageUrls = await _uploadImagesToCloudinary();
      }

      final double yieldAmount =
          double.parse(yieldAmountController.text.trim());
      final double? areaHa = areaHaController.text.trim().isEmpty
          ? null
          : double.tryParse(areaHaController.text.trim());

      // Call the callback without farmerId and farmId
      widget.onYieldAdded(
        selectedProduct!.id,
        yieldAmount,
        areaHa,
        selectedDate,
        notesController.text,
        imageUrls,
      );

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ToastHelper.showErrorToast(
          'Error: ${error.toString()}',
          context,
        );
      }
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
          widget.onLoadingStateChanged(false);
        });
      }
    }
  }

  @override
  void dispose() {
    yieldAmountController.dispose();
    areaHaController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    const double fieldHeight = 56.0;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
        
            SizedBox(height: isSmallScreen ? 8.0 : 16.0),

         
            // Crop Type Autocomplete
            SizedBox(
              height: fieldHeight,
              child: Autocomplete<Product>(
                key: cropTypeFieldKey,
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return widget.products;
                  }
                  return widget.products.where((product) => product.name
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (Product product) {
                  setState(() {
                    selectedProduct = product;
                  });
                },
                displayStringForOption: (product) => product.name,
                optionsViewBuilder: (context, onSelected, options) {
                  return _buildOptionsView<Product>(
                    context,
                    onSelected,
                    options,
                    cropTypeFieldKey,
                    (product) => product.name,
                  );
                },
                fieldViewBuilder: (BuildContext context,
                    TextEditingController textEditingController,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted) {
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'Crop Type *',
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 12),
                      errorStyle: TextStyle(
                        fontSize: 10,
                        color: Colors.red.shade600,
                      ),
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
                        return 'Please select a crop type';
                      }
                      if (!widget.products.any((p) => p.name == value.trim())) {
                        return 'Please select a valid crop type';
                      }
                      return null;
                    },
                    autovalidateMode: _cropTypeValidated
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                  );
                },
              ),
            ),
            SizedBox(height: isSmallScreen ? 8.0 : 16.0),

            // Area Harvested
            SizedBox(
              height: fieldHeight,
              child: TextFormField(
                controller: areaHaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Area harvested (ha) - Optional',
                  border: const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  errorStyle: TextStyle(
                    fontSize: 10,
                    color: Colors.red.shade600,
                  ),
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
                    return null;
                  }

                  final area = double.tryParse(value.trim());
                  if (area == null) {
                    return 'Please enter a valid number';
                  }

                  if (area <= 0) {
                    return 'Area must be greater than 0';
                  }

                  if (area > 10000) {
                    return 'Area seems too large. Please check your input';
                  }

                  if (widget.farmArea != null) {
                    if (area > widget.farmArea!) {
                      return 'Area cannot exceed farm size (${widget.farmArea} ha)';
                    }
                  }

                  return null;
                },
                autovalidateMode: _areaHaValidated
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
              ),
            ),

            SizedBox(height: isSmallScreen ? 8.0 : 16.0),

            // Yield Amount
            SizedBox(
              height: fieldHeight,
              child: TextFormField(
                controller: yieldAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Volume (mt | heads) *',
                  border: const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  errorStyle: TextStyle(
                    fontSize: 10,
                    color: Colors.red.shade600,
                  ),
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
                    return 'Please enter yield amount';
                  }
                  final amount = double.tryParse(value.trim());
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid positive number';
                  }
                  return null;
                },
                autovalidateMode: _yieldAmountValidated
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
              ),
            ),
            SizedBox(height: isSmallScreen ? 8.0 : 16.0),

            // Date Picker
            SizedBox(
              height: fieldHeight,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Date',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 12),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                selectedDate = pickedDate;
                              });
                            }
                          },
                        ),
                      ),
                      controller: TextEditingController(
                        text: "${selectedDate.toLocal()}".split(' ')[0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isSmallScreen ? 8.0 : 16.0),

            // Notes
            TextFormField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              ),
            ),
            SizedBox(height: isSmallScreen ? 8.0 : 16.0),

            // Image Attachment
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ButtonWidget(
                  btnText: 'Attach Images (Max 5)',
                  onTap: selectedImages.length >= 5 ? null : _pickImages,
                ),
                const SizedBox(height: 8),
                Text(
                  '${selectedImages.length}/5 images selected',
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        selectedImages.length >= 5 ? Colors.red : Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                _buildImagePreview(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddYieldModalForFarmFooter extends StatelessWidget {
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  final bool isLoading;

  const _AddYieldModalForFarmFooter({
    required this.onSubmit,
    required this.onCancel,
    this.isLoading = false,
  });

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
                btnText: context.translate('Cancel'),
                textColor: FlarelineColors.darkBlackText,
                onTap: isLoading ? null : onCancel,
              ),
            ),
            SizedBox(width: screenWidth < 600 ? 10 : 20),
            SizedBox(
              width: screenWidth < 600 ? 100 : 120,
              child: ButtonWidget(
                btnText: isLoading
                    ? context.translate('Adding...')
                    : context.translate('Add Record'),
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