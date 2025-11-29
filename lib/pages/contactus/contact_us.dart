import 'package:flareline/pages/toast/toast_helper.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flareline/services/lanugage_extension.dart';
import 'package:flutter/material.dart'; 
import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flareline_uikit/components/forms/outborder_text_form_field.dart';
import 'package:flareline/pages/layout.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class ContactUsPage extends LayoutWidget {
  ContactUsPage({super.key});
  
  final TextEditingController _emailController = TextEditingController(); 
  final TextEditingController _problemController = TextEditingController();
  bool _isEmailPrefilled = false;
  final List<XFile> _attachedImages = [];
  final ImagePicker _imagePicker = ImagePicker();
   bool _isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 400;
  }

  @override
  String breakTabTitle(BuildContext context) {
    return 'Contact Support';
  }

  
    @override
  EdgeInsetsGeometry? get customPadding => const EdgeInsets.all(9);

  @override
  Widget contentDesktopWidget(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _mainFormWidget(context)),
        const SizedBox(width: 24),
        Expanded(flex: 2, child: _supportInfoWidget(context)),
      ],
    );
  }

  @override
  Widget contentMobileWidget(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _mainFormWidget(context),
        const SizedBox(height: 20),
        _supportInfoWidget(context),
      ],
    );
  }


Widget _mainFormWidget(BuildContext context) {
  // Prefill email on widget build (only once)
  if (!_isEmailPrefilled) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.farmer?.email != null && userProvider.farmer!.email!.isNotEmpty) {
      _emailController.text = userProvider.farmer!.email!;
    }
    _isEmailPrefilled = true;
  }

  // Create a GlobalKey for the form
  final _formKey = GlobalKey<FormState>();

  return CommonCard(
    child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey, // Add this key
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.support_agent,
                    color: Colors.blue.shade700,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.translate('Report a Technical Issue'),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        context.translate('Having trouble with the platform? Let us know and well help you resolve it.'),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Email Field
            OutBorderTextFormField(
              controller: _emailController,
              labelText: context.translate('Your Email *'),
              hintText: context.translate('email@example.com'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.translate('Please enter your email address');
                }
                if (!_isValidEmail(value)) {
                  return context.translate('Please enter a valid email address');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Problem Description
            OutBorderTextFormField(
              controller: _problemController,
              labelText: context.translate('Describe the Issue *'),
              hintText: context.translate('contactus_hint_problem_description'),
              maxLines: 8,
               errorLeft: 12,
            errorRight: 12,
            errorBottom: -15,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.translate('Please describe the issue you\'re experiencing');
                }
                if (value.length < 10) {
                  return context.translate('Please provide more details (at least 10 characters)');
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Image Attachments Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).cardTheme.color
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade700
                      : Colors.grey.shade300,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.attach_file, 
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.blue.shade400
                            : Colors.blue.shade700, 
                        size: 20
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.translate('Attachments (Optional)'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      const Spacer(),
                      Visibility(
                        visible: !_isSmallScreen(context),
                        child: TextButton.icon(
                          onPressed: () => _pickImages(context),
                          icon: Icon(
                            Icons.add_photo_alternate, 
                            size: 18,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.blue.shade400
                                : Colors.blue.shade700,
                          ),
                          label: Text(
                            context.translate('Add Images'),
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.blue.shade400
                                  : Colors.blue.shade700,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            backgroundColor: Theme.of(context).brightness == Brightness.dark
                                ? Colors.blue.shade900.withOpacity(0.3)
                                : Colors.blue.shade50,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_attachedImages.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _attachedImages.asMap().entries.map((entry) {
                        return _buildImagePreview(entry.key, entry.value, context);
                      }).toList(),
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        context.translate('No images attached. Add screenshots to help us understand the issue better.'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ButtonWidget(
                btnText: context.translate("Submit Issue Report"),
                type: ButtonType.primary.type,
                onTap: () => _handleSubmit(context, _formKey), // Pass the form key
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Footer Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.translate("Our technical support team will review your issue and respond as soon as possible. For urgent system-wide issues, please call our hotline."),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


  Widget _supportInfoWidget(BuildContext context) {
    return Column(
      children: [
        // Quick Contact Info Card
        CommonCard(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.phone_in_talk,
                        color: Colors.red.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      context.translate("Need Urgent Help?"),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ), 
                const Divider(height: 24),
                _infoRow(Icons.email, "Email Support", "agritrack@gmail.com"),
                const Divider(height: 24),
                _infoRow(Icons.schedule, "Support Hours", "Mon-Fri: 8AM - 6PM"),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Tips Card
        CommonCard(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tips_and_updates, color: Colors.purple.shade700, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      context.translate("Helpful Tips"),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _tipItem(context.translate("Include screenshots if possible")),
                _tipItem(context.translate("Describe the exact steps you took")),
                _tipItem(context.translate("Mention your device and browser")), 
                _tipItem(context.translate("Note the time when issue occurred")),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.blue.shade700),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.purple.shade700,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

 
 

 Widget _buildImagePreview(int index, XFile image, BuildContext context) {
  final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  return Container(
    width: 100,
    height: 100,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isDarkMode 
          ? Colors.grey.shade700 
          : Colors.grey.shade300,
      ),
      color: isDarkMode 
        ? Colors.grey.shade800 
        : Colors.transparent,
    ),
    child: Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: kIsWeb
              ? Image.network(
                  image.path,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: isDarkMode 
                        ? Colors.grey.shade700 
                        : Colors.grey.shade200,
                      child: Icon(
                        Icons.broken_image,
                        color: isDarkMode 
                          ? Colors.grey.shade500 
                          : Colors.grey.shade400,
                        size: 32,
                      ),
                    );
                  },
                )
              : Image.file(
                  File(image.path),
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: isDarkMode 
                        ? Colors.grey.shade700 
                        : Colors.grey.shade200,
                      child: Icon(
                        Icons.broken_image,
                        color: isDarkMode 
                          ? Colors.grey.shade500 
                          : Colors.grey.shade400,
                        size: 32,
                      ),
                    );
                  },
                ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index, context),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDarkMode 
                  ? Colors.red.shade800 
                  : Colors.red.shade600,
                shape: BoxShape.circle,
                boxShadow: [
                  if (isDarkMode)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}


  Future<void> _pickImages(BuildContext context) async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      
      if (images.isNotEmpty) {
        if (_attachedImages.length + images.length > 5) {
          ToastHelper.showErrorToast(
            context.translate('You can attach a maximum of 5 images'),
            context,
          );
          return;
        }
        
        _attachedImages.addAll(images);
        (context as Element).markNeedsBuild();
        
     
      }
    } catch (e) {
      ToastHelper.showErrorToast(
        context.translate('Failed to pick images: ${e.toString()}'),
        context,
      );
    }
  }

  void _removeImage(int index, BuildContext context) {
    _attachedImages.removeAt(index);
    (context as Element).markNeedsBuild();
    
    ToastHelper.showSuccessToast(
      context.translate('Image removed'),
      context,
    );
  }

void _handleSubmit(BuildContext context, GlobalKey<FormState> formKey) async {
  // Validate the form first
  if (!formKey.currentState!.validate()) {
    // Validation failed - error messages are already shown by the validators
    return;
  }

  try {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final farmerName = userProvider.farmer?.name ?? 'Unknown User';
    
    // Build attachment info
    String attachmentInfo = '';
    if (_attachedImages.isNotEmpty) {
      attachmentInfo = '\n\nAttached Images (${_attachedImages.length}):\n';
      for (int i = 0; i < _attachedImages.length; i++) {
        attachmentInfo += '${i + 1}. ${_attachedImages[i].name}\n';
      }
      attachmentInfo += '\nNote: Images cannot be sent via mailto link. Please attach them manually when sending the email.';
    }
    
    // Compose email
    final String subject = Uri.encodeComponent('Technical Support Request - AgriTrack');
    final String body = Uri.encodeComponent(
      'Support Request Details:\n\n'
      'From: $farmerName\n'
      'Email: ${_emailController.text}\n' 
      'Issue Description:\n'
      '${_problemController.text}'
      '$attachmentInfo\n\n'
      '---\n'
      'Submitted via AgriTrack Contact Form'
    );
    
    final Uri emailUri = Uri.parse('mailto:umalic65@gmail.com?subject=$subject&body=$body');
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
      
      String successMessage = _attachedImages.isNotEmpty
          ? context.translate('Email client opened. Please manually attach the ${_attachedImages.length} image(s) before sending.')
          : context.translate('Email client opened. Please send the email to complete your request.');
      
      ToastHelper.showSuccessToast(
        successMessage,
        context,
      );
      
      _clearForm();
    } else {
      throw Exception('Could not open email client');
    }
  } catch (e) {
    ToastHelper.showErrorToast(
      context.translate('Failed to open email client: ${e.toString()}'),
      context,
    );
  }
}

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  void _clearForm() { 
    _problemController.clear();
    _attachedImages.clear();
    // Keep email prefilled for convenience
  }
}