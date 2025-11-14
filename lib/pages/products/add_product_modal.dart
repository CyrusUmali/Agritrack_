import 'dart:async';
import 'package:flareline/pages/products/product/product_bloc.dart';
import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flareline_uikit/components/modal/modal_dialog.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' if (dart.library.html) 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'package:toastification/toastification.dart';

class AddProductModal extends StatefulWidget {
  const AddProductModal({Key? key}) : super(key: key);

  static Future<void> show(BuildContext context) async {
    final productBloc = BlocProvider.of<ProductBloc>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final contentKey = GlobalKey<_AddProductModalContentState>();
    bool isLoading = false;

    await ModalDialog.show(
      context: context,
      title: 'Add New Product',
      showTitle: true,
      showTitleDivider: true,
      modalType: screenWidth < 600 ? ModalType.large : ModalType.medium,
      child: BlocProvider.value(
        value: productBloc,
        child: _AddProductModalContent(
          key: contentKey,
          onSubmit: () {},
          onLoadingStateChanged: (loading) {
            isLoading = loading;
          },
        ),
      ),
      footer: _AddProductModalFooter(
        onSubmit: () {
          if (contentKey.currentState != null && !isLoading) {
            contentKey.currentState!._submitProduct();
          }
        },
        onCancel: () => Navigator.of(context).pop(),
        isLoading: isLoading,
      ),
    );
  }

  @override
  State<AddProductModal> createState() => _AddProductModalState();
}

class _AddProductModalState extends State<AddProductModal> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _AddProductModalContent extends StatefulWidget {
  final VoidCallback onSubmit;
  final Function(bool) onLoadingStateChanged;

  const _AddProductModalContent({
    Key? key,
    required this.onSubmit,
    required this.onLoadingStateChanged,
  }) : super(key: key);

  @override
  State<_AddProductModalContent> createState() =>
      _AddProductModalContentState();
}

class _AddProductModalContentState extends State<_AddProductModalContent> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String selectedCategory = 'HVC';
  html.File? _selectedImage;
  String? _imageUrl;
  bool _isUploading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
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
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.flat,
          title: Text('Image upload failed: ${e.toString()}'),
          alignment: Alignment.topRight,
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
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

  void _submitProduct() async {
    // In your modal's submit method
    print('Modal context: ${context.hashCode}');
    print(
        'BLoC available: ${BlocProvider.of<ProductBloc>(context, listen: false).hashCode}');
    final productBloc = context.read<ProductBloc>();
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();

    setState(() {
      _isSubmitting = true;
      widget.onLoadingStateChanged(true);
    });

    // Form validation
    if (name.isEmpty || description.isEmpty) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.flat,
        title: const Text('Please fill all fields'),
        alignment: Alignment.topRight,
        autoCloseDuration: const Duration(seconds: 4),
      );
      setState(() {
        _isSubmitting = false;
        widget.onLoadingStateChanged(false);
      });
      return;
    }

    if (_isUploading) {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        style: ToastificationStyle.flat,
        title: const Text('Please wait for image to upload'),
        alignment: Alignment.topRight,
        autoCloseDuration: const Duration(seconds: 4),
      );
      setState(() {
        _isSubmitting = false;
        widget.onLoadingStateChanged(false);
      });
      return;
    }

    try {
      // Create a completer to wait for the BLoC to complete
      // final completer = Completer<void>();
      // StreamSubscription? subscription;

      // subscription = productBloc.stream.listen((state) {
      //   if (state is ProductsLoaded && state.message != null) {
      //     completer.complete(); // Complete when we get success
      //   } else if (state is ProductsError) {
      //     completer.completeError(state.message); // Error case
      //   }
      // });

      // Dispatch the add product event
      productBloc.add(AddProduct(
        name: name,
        description: description,
        category: selectedCategory,
        imageUrl: _imageUrl,
      ));

      print('selectedCategory');
      print(selectedCategory);

      // Wait for either success or error state
      // await completer.future;
      // subscription.cancel();

      await Future.delayed(const Duration(milliseconds: 500));

      // Only close if still mounted
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.flat,
          title: Text(error.toString()),
          alignment: Alignment.topRight,
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
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
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.all(screenWidth < 600 ? 8.0 : 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Product Name',
              border: const OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                vertical: screenWidth < 600 ? 10.0 : 16.0,
                horizontal: 10.0,
              ),
            ),
          ),
          SizedBox(height: screenWidth < 600 ? 8.0 : 16.0),
          TextFormField(
            controller: descriptionController,
            decoration: InputDecoration(
              labelText: 'Description',
              border: const OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                vertical: screenWidth < 600 ? 10.0 : 16.0,
                horizontal: 10.0,
              ),
            ),
            maxLines: 3,
          ),
          SizedBox(height: screenWidth < 600 ? 8.0 : 16.0),
          DropdownButtonFormField<String>(
            value: selectedCategory,
            decoration: InputDecoration(
              labelText: 'Category',
              border: const OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                vertical: screenWidth < 600 ? 10.0 : 16.0,
                horizontal: 10.0,
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'Rice', child: Text('Rice')),
              DropdownMenuItem(value: 'Corn', child: Text('Corn')),
              DropdownMenuItem(value: 'HVC', child: Text('HVC')),
              DropdownMenuItem(value: 'Livestock', child: Text('Livestock')),
              DropdownMenuItem(value: 'Fishery', child: Text('Fishery')),
              DropdownMenuItem(value: 'Organic', child: Text('Organic')),
            ],
            onChanged: (value) => setState(() {
              if (value != null) selectedCategory = value;
            }),
          ),
          SizedBox(height: screenWidth < 600 ? 16.0 : 24.0),
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
                        errorBuilder: (context, error, stackTrace) => Container(
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
                    'Upload Product Image',
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
    );
  }
}

class _AddProductModalFooter extends StatelessWidget {
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  final bool isLoading;

  const _AddProductModalFooter({
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
                btnText: isLoading ? 'Adding...' : 'Add Product',
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
