import 'package:flareline/core/models/farmer_model.dart';
import 'package:flareline/core/models/farms_model.dart';
import 'package:flareline/core/models/product_model.dart';
import 'package:flareline/pages/farms/farm_widgets/farm_map_card.dart';
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

class AddYieldModal extends StatefulWidget {
  final Function(
    int cropTypeId,
    int farmerId,
    int farmId,
    double yieldAmount,
    double? areaHa,
    DateTime date,
    String status,
    String notes,
    List<String> imageUrls,
  ) onYieldAdded;

  const AddYieldModal({Key? key, required this.onYieldAdded}) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required List<Product> products,
    required List<Farm> farms,
    required List<Farmer> farmers,
    required Function(
      int cropTypeId,
      int farmerId,
      int farmId,
      double yieldAmount,
      double? areaHa,
      DateTime date,
      String notes,
      List<String> imageUrls,
    ) onYieldAdded,
  }) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final screenWidth = MediaQuery.of(context).size.width;
    final contentKey = GlobalKey<_AddYieldModalContentState>();
    bool isLoading = false;

    await ModalDialog.show(
      context: context,
      title: context.translate('Add Record'),
      showTitle: true,
      showTitleDivider: true,
      modalType: screenWidth < 600 ? ModalType.large : ModalType.medium,
      child: _AddYieldModalContent(
        key: contentKey,
        onLoadingStateChanged: (loading) {
          isLoading = loading;
        },
        onYieldAdded: onYieldAdded,
        products: products,
        farms: farms,
        farmers: farmers,
        userProvider: userProvider,
      ),
      footer: _AddYieldModalFooter(
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
  State<AddYieldModal> createState() => _AddYieldModalState();
}

class _AddYieldModalState extends State<AddYieldModal> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _AddYieldModalContent extends StatefulWidget {
  final Function(bool) onLoadingStateChanged;
  final Function(
    int cropTypeId,
    int farmerId,
    int farmId,
    double yieldAmount,
    double? areaHa,
    DateTime date,
    String notes,
    List<String> imageUrls,
  ) onYieldAdded;
  final List<Product> products;
  final List<Farm> farms;
  final List<Farmer> farmers;
  final UserProvider userProvider;

  const _AddYieldModalContent({
    Key? key,
    required this.onLoadingStateChanged,
    required this.onYieldAdded,
    required this.products,
    required this.farmers,
    required this.farms,
    required this.userProvider,
  }) : super(key: key);

  @override
  State<_AddYieldModalContent> createState() => _AddYieldModalContentState();
}

class _AddYieldModalContentState extends State<_AddYieldModalContent> {
  final TextEditingController yieldAmountController = TextEditingController();
  final TextEditingController areaHaController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  TextEditingController farmAreaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isMapMinimized = false; // Add this line
  DateTime selectedDate = DateTime.now();
  Product? selectedProduct;
  Farmer? selectedFarmer;
  Farm? selectedFarm;
  List<XFile> selectedImages = [];
  bool _isSubmitting = false;

  bool _cropTypeValidated = false;
  bool _farmerValidated = false;
  bool _farmAreaValidated = false;
  bool _areaHaValidated = false;
  bool _yieldAmountValidated = false;

  late Farmer? _currentFarmer;
  late bool _isFarmer;

  final GlobalKey cropTypeFieldKey = GlobalKey();
  final GlobalKey farmerFieldKey = GlobalKey();
  final GlobalKey farmAreaFieldKey = GlobalKey();

  void _toggleMapVisibility() {
    setState(() {
      _isMapMinimized = !_isMapMinimized;
    });
  }

  @override
  void initState() {
    super.initState();
    _isFarmer = widget.userProvider.isFarmer;
    _currentFarmer = widget.userProvider.farmer;

    if (_isFarmer && _currentFarmer != null) {
      selectedFarmer = _currentFarmer;
      final farmsForFarmer = widget.farms
          .where((farm) => farm.owner == _currentFarmer!.name)
          .toList();
      if (farmsForFarmer.isNotEmpty) {
        selectedFarm = farmsForFarmer.first;
        farmAreaController.text = selectedFarm!.name;
        _setAreaHarvestedFromFarm(selectedFarm!);
      }
    }
  }

  void _setAreaHarvestedFromFarm(Farm farm) {
    if (farm.hectare != null && farm.hectare! > 0) {
      areaHaController.text = farm.hectare.toString();
    }
  }

  // Convert Farm model to Map for FarmMapCard
  Map<String, dynamic> _farmToMap(Farm farm) {
    return {
      'id': farm.id,
      'name': farm.name,
      'owner': farm.owner,
      'hectare': farm.hectare,
      'sector': farm.sector, // Add sector if available in your Farm model
      'vertices': farm.vertices, // Assuming your Farm model has vertices
      // Add other properties as needed
    };
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

  Widget _buildFarmMapSection() {
    if (selectedFarm == null) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Farm Location:',
              style: TextStyle(fontSize: 13),
            ),
            IconButton(
              icon: Icon(
                _isMapMinimized ? Icons.expand_more : Icons.expand_less,
                size: 20,
              ),
              onPressed: _toggleMapVisibility,
              tooltip: _isMapMinimized ? 'Show Map' : 'Hide Map',
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isMapMinimized ? 0 : (isSmallScreen ? 250 : 300),
          width: double.infinity,
          child: _isMapMinimized
              ? null
              : FarmMapCard(
                  key: ValueKey(selectedFarm!.id), // Add this line
                  farm: _farmToMap(selectedFarm!),
                  isMobile: isSmallScreen,
                ),
        ),
        SizedBox(height: isSmallScreen ? 8.0 : 16.0),
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
      _farmerValidated = true;
      _farmAreaValidated = true;
      _yieldAmountValidated = true;
      _areaHaValidated = true;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
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

      print('areaHa-------');
      print(areaHa);
      widget.onYieldAdded(
        selectedProduct!.id,
        selectedFarmer!.id,
        selectedFarm!.id,
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
          _isSubmitting = false;
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
    farmAreaController.dispose();
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
                        color: Colors.red
                            .shade600, // Add your desired error text color here
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

            _isFarmer
                ? SizedBox(
                    height: fieldHeight,
                    child: TextFormField(
                      initialValue: _currentFarmer?.name ?? '',
                      decoration: const InputDecoration(
                        labelText: 'Farmer',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      ),
                      readOnly: true,
                    ),
                  )
                : SizedBox(
                    height: fieldHeight,
                    child: Autocomplete<Farmer>(
                      key: farmerFieldKey,
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return widget.farmers;
                        }
                        return widget.farmers.where((farmer) => farmer.name
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()));
                      },
                      onSelected: (Farmer farmer) {
                        setState(() {
                          selectedFarmer = farmer;
                          selectedFarm = null;
                          farmAreaController.text = '';
                          areaHaController.text = '';
                        });
                      },
                      displayStringForOption: (farmer) => farmer.name,
                      optionsViewBuilder: (context, onSelected, options) {
                        return _buildOptionsView<Farmer>(
                          context,
                          onSelected,
                          options,
                          farmerFieldKey,
                          (farmer) => farmer.name,
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
                            labelText: 'Farmer *',
                            border: const OutlineInputBorder(),
                            suffixIcon: const Icon(Icons.arrow_drop_down),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 12),
                            errorStyle: TextStyle(
                              fontSize: 10,
                              color: Colors.red
                                  .shade600, // Add your desired error text color here
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
                              return 'Please select a farmer';
                            }
                            if (!widget.farmers
                                .any((f) => f.name == value.trim())) {
                              return 'Please select a valid farmer';
                            }
                            return null;
                          },
                          autovalidateMode: _farmerValidated
                              ? AutovalidateMode.onUserInteraction
                              : AutovalidateMode.disabled,
                        );
                      },
                    ),
                  ),

            SizedBox(height: isSmallScreen ? 8.0 : 16.0),

            // Farm Area Autocomplete
            SizedBox(
              height: fieldHeight,
              child: Autocomplete<Farm>(
                key: farmAreaFieldKey,
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (selectedFarmer == null) {
                    return const Iterable<Farm>.empty();
                  }
                  final farmsForFarmer = widget.farms
                      .where((farm) => farm.owner == selectedFarmer!.name);
                  if (textEditingValue.text.isEmpty) {
                    return farmsForFarmer;
                  }
                  return farmsForFarmer.where((farm) => farm.name
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (Farm farm) {
                  setState(() {
                    selectedFarm = farm;
                    _setAreaHarvestedFromFarm(farm);
                  });
                },
                displayStringForOption: (farm) => farm.name,
                optionsViewBuilder: (context, onSelected, options) {
                  return _buildOptionsView<Farm>(
                    context,
                    onSelected,
                    options,
                    farmAreaFieldKey,
                    (farm) => farm.name,
                  );
                },
                fieldViewBuilder: (BuildContext context,
                    TextEditingController textEditingController,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted) {
                  farmAreaController = textEditingController;
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'Farm Area *',
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                      hintText: selectedFarmer == null
                          ? 'Select a farmer first'
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 12),
                      errorStyle: TextStyle(
                        fontSize: 10,
                        color: Colors.red
                            .shade600, // Add your desired error text color here
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
                    readOnly: selectedFarmer == null,
                    validator: (value) {
                      if (selectedFarmer == null) {
                        return 'Please select a farmer first';
                      }
                      if (value == null || value.trim().isEmpty) {
                        return 'Please select a farm area';
                      }
                      if (!widget.farms.any((f) =>
                          f.name == value.trim() &&
                          f.owner == selectedFarmer!.name)) {
                        return 'Please select a valid farm area';
                      }
                      return null;
                    },
                    autovalidateMode: _farmAreaValidated
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                  );
                },
              ),
            ),
            SizedBox(height: isSmallScreen ? 8.0 : 16.0),

            // Farm Map Section - Added here
            _buildFarmMapSection(),

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
                    color: Colors
                        .red.shade600, // Add your desired error text color here
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

                  if (selectedFarm != null && selectedFarm!.hectare != null) {
                    if (area > selectedFarm!.hectare!) {
                      return 'Area cannot exceed farm size (${selectedFarm!.hectare} ha)';
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
                    color: Colors
                        .red.shade600, // Add your desired error text color here
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

class _AddYieldModalFooter extends StatelessWidget {
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  final bool isLoading;

  const _AddYieldModalFooter({
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
