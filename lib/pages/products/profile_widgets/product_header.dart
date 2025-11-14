import 'package:flareline/pages/products/profile_widgets/prod_ui_components.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/core/models/product_model.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flareline/pages/products/product/product_bloc.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' if (dart.library.html) 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class ProductHeader extends StatefulWidget {
  final Product item;
  final Function(Product)? onProductUpdated;

  const ProductHeader({
    super.key,
    required this.item,
    this.onProductUpdated,
  });

  @override
  State<ProductHeader> createState() => _ProductHeaderState();
}

class _ProductHeaderState extends State<ProductHeader>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late String _selectedSector;
  bool _isEditing = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Cloudinary related state
  html.File? _selectedImage;
  String? _newImageUrl;
  bool _isUploading = false;

  // Cloudinary configuration
  static const _cloudName = 'dk41ykxsq';
  static const _uploadPreset = 'my_upload_preset';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _descriptionController =
        TextEditingController(text: widget.item.description);
    _selectedSector = widget.item.sector;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        // Reset values when canceling edit
        _nameController.text = widget.item.name;
        _descriptionController.text = widget.item.description ?? '';
        _selectedSector = widget.item.sector;
        _newImageUrl = null;
        _isUploading = false;
      }
    });
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _isUploading = true;
        });

        final imageUrl = await _uploadImageToCloudinary(pickedFile);

        setState(() {
          _newImageUrl = imageUrl;
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() => _isUploading = false);
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

  Future<String?> _uploadImageToCloudinary(XFile file) async {
    final url = 'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

    try {
      final request = http.MultipartRequest('POST', Uri.parse(url))
        ..fields['upload_preset'] = _uploadPreset;

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

  void _submitChanges() {
    if (_nameController.text.trim().isEmpty) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.flat,
        title: const Text('Product name cannot be empty'),
        description: const Text('Please enter a valid product name'),
        alignment: Alignment.topRight,
        autoCloseDuration: const Duration(seconds: 4),
        showProgressBar: true,
      );
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
      return;
    }

    setState(() => _isLoading = true);

    // Create the updated product object
    final updatedProduct = Product(
      id: widget.item.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      sector: _selectedSector,
      imageUrl: _newImageUrl ?? widget.item.imageUrl,
    );

    context.read<ProductBloc>().add(
          EditProduct(
            id: widget.item.id!,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _selectedSector,
            imageUrl: _newImageUrl ?? widget.item.imageUrl,
          ),
        );

    // Call the callback if it exists
    if (widget.onProductUpdated != null) {
      widget.onProductUpdated!(updatedProduct);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isFarmer = userProvider.isFarmer;

    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state is ProductsLoaded && state.message != null) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.flat,
            title: Text(state.message!),
            alignment: Alignment.topRight,
            autoCloseDuration: const Duration(seconds: 4),
            showProgressBar: true,
          );
          setState(() {
            _isEditing = false;
            _isLoading = false;
            _newImageUrl = null;
          });
          _animationController.reverse();
        } else if (state is ProductsError) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            style: ToastificationStyle.flat,
            title: Text(state.message),
            alignment: Alignment.topRight,
            autoCloseDuration: const Duration(seconds: 4),
            showProgressBar: true,
          );
          setState(() => _isLoading = false);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(160),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: CommonCard(
          child: Container(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductHeaderUI.buildHeader(theme, colorScheme, _isEditing),
                  const SizedBox(height: 24),
                  ProductHeaderUI.buildContent(
                      context,
                      theme,
                      colorScheme,
                      widget.item,
                      _isEditing,
                      _isUploading,
                      _newImageUrl,
                      _nameController,
                      _descriptionController,
                      _selectedSector,
                      _pickAndUploadImage,
                      _getSectorIcon),
                  const SizedBox(height: 24),
                  if (!isFarmer)
                    ProductHeaderUI.buildEditControls(
                      colorScheme,
                      theme, // Add theme parameter
                      widget.item, // Add item parameter
                      _isEditing,
                      _isLoading,
                      _toggleEditing,
                      _submitChanges,
                      _getSectorIcon,
                      context, // Add getSectorIcon parameter
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getSectorIcon(String sector) {
    switch (sector) {
      case 'Rice':
        return Icons.rice_bowl_outlined;
      case 'Corn':
        return Icons.agriculture_outlined;
      case 'HVC':
        return Icons.local_florist_outlined;
      case 'Livestock':
        return Icons.pets_outlined;
      case 'Fishery':
        return Icons.set_meal_outlined;
      case 'Organic':
        return Icons.eco_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}
