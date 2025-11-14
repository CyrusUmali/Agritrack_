// ignore_for_file: unnecessary_to_list_in_spreads

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class YieldImageHandler {
  final ImagePicker _picker = ImagePicker();
  List<XFile> selectedImages = [];
  List<String> existingImages = [];

  Future<void> pickImages({
    required BuildContext context,
    required int maxAllowed,
  }) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        final remainingSlots =
            maxAllowed - (existingImages.length + selectedImages.length);
        if (remainingSlots > 0) {
          selectedImages.addAll(images.take(remainingSlots));
        } else {
          Fluttertoast.showToast(
            msg: 'Maximum of $maxAllowed images allowed',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
      throw Exception('Error picking images: ${e.toString()}');
    }
  }

  void removeImage(int index, bool isExisting) {
    if (isExisting) {
      existingImages.removeAt(index);
    } else {
      selectedImages.removeAt(index);
    }
  }

  Future<List<String>> uploadImagesToCloudinary() async {
    const cloudName = 'dk41ykxsq';
    const uploadPreset = 'my_upload_preset';
    final List<String> imageUrls = [];

    if (selectedImages.isEmpty) return imageUrls;

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

  Widget buildImageUploadSection({
    required BuildContext context,
    required bool isMobile,
    required VoidCallback onAddImages,
    required Function(int, bool) onRemoveImage,
  }) {
    final totalImages = existingImages.length + selectedImages.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (totalImages < 5)
          OutlinedButton.icon(
            onPressed: onAddImages,
            icon: const Icon(Icons.add_a_photo),
            label: Text('Add Images (${5 - totalImages} remaining)'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 12 : 16,
                horizontal: 16,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'Uploaded Images (${totalImages}/5)',
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        if (totalImages == 0)
          Container(
            height: isMobile ? 100 : 120,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: Center(
              child: Text("No images uploaded",
                  style: TextStyle(color: Colors.grey.shade600)),
            ),
          )
        else
          SizedBox(
            height: isMobile ? 120 : 150,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ...existingImages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final image = entry.value;
                  return _buildImageItem(
                    context,
                    image,
                    index,
                    true,
                    isMobile,
                    onRemoveImage,
                  );
                }).toList(),
                ...selectedImages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final image = entry.value;
                  return _buildImageItem(
                    context,
                    image.path,
                    index,
                    false,
                    isMobile,
                    onRemoveImage,
                  );
                }).toList(),
              ],
            ),
          ),
      ],
    );
  }

  void showEnlargedImage(
      BuildContext context, String imagePath, bool isExisting) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 3.0,
              child: Center(
                child: isExisting || kIsWeb
                    ? Image.network(imagePath)
                    : Image.file(File(imagePath)),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageItem(
    BuildContext context,
    String imagePath,
    int index,
    bool isExisting,
    bool isMobile,
    Function(int, bool) onRemoveImage,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () => showEnlargedImage(context, imagePath, isExisting),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isExisting || kIsWeb
                  ? Image.network(
                      imagePath,
                      width: isMobile ? 100 : 120,
                      height: isMobile ? 100 : 120,
                      fit: BoxFit.cover,
                    )
                  : Image.file(
                      File(imagePath),
                      width: isMobile ? 100 : 120,
                      height: isMobile ? 100 : 120,
                      fit: BoxFit.cover,
                    ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => onRemoveImage(index, isExisting),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
