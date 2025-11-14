import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/modal/modal_dialog.dart';
import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';

class AddUserModal extends StatefulWidget {
  final Function(UserData) onUserAdded;

  const AddUserModal({Key? key, required this.onUserAdded}) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required String role,
    required Function(UserData) onUserAdded,
  }) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentKey = GlobalKey<_AddUserModalContentState>();
    bool isLoading = false;

    await ModalDialog.show(
      context: context,
      title: 'Add New User',
      showTitle: true,
      showTitleDivider: true,
      modalType: screenWidth < 600 ? ModalType.small : ModalType.medium,
      child: _AddUserModalContent(
        key: contentKey,
        role: role,
        onLoadingStateChanged: (loading) {
          isLoading = loading;
        },
        onUserAdded: onUserAdded,
      ),
      footer: _AddUserModalFooter(
        onSubmit: () {
          if (contentKey.currentState != null && !isLoading) {
            contentKey.currentState!._submitUser();
          }
        },
        onCancel: () => Navigator.of(context).pop(),
        isLoading: isLoading,
      ),
    );
  }

  @override
  State<AddUserModal> createState() => _AddUserModalState();
}

class _AddUserModalState extends State<AddUserModal> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class UserData {
  final String name;
  final String email;
  final String password;
  final String role;

  UserData({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });
}

class _AddUserModalContent extends StatefulWidget {
  final Function(bool) onLoadingStateChanged;
  final Function(UserData) onUserAdded;
  final String role;

  const _AddUserModalContent({
    Key? key,
    required this.onLoadingStateChanged,
    required this.onUserAdded,
    required this.role,
  }) : super(key: key);

  @override
  State<_AddUserModalContent> createState() => _AddUserModalContentState();
}

class _AddUserModalContentState extends State<_AddUserModalContent> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Track which fields have been validated
  bool _nameValidated = false;
  bool _emailValidated = false;
  bool _passwordValidated = false;

  void _submitUser() async {
    // Mark all fields as validated
    setState(() {
      _nameValidated = true;
      _emailValidated = true;
      _passwordValidated = true;
    });

    if (!_formKey.currentState!.validate()) {
      // Validation failed, don't proceed
      return;
    }

    setState(() {
      _isSubmitting = true;
      widget.onLoadingStateChanged(true);
    });

    try {
      // Create user data object with role
      final userData = UserData(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        role: widget.role,
      );

      // Call the callback
      widget.onUserAdded(userData);

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
    passwordController.dispose();
    super.dispose();
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
                  return 'Please enter the user\'s name';
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
                labelText: 'Email *',
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
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an email address';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value.trim())) {
                  return 'Please enter a valid email address';
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

            // Password Field
            TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password *',
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
                  return 'Please enter a password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
              onChanged: (value) {
                if (_passwordValidated) {
                  _formKey.currentState!.validate();
                }
              },
              autovalidateMode: _passwordValidated
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddUserModalFooter extends StatelessWidget {
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  final bool isLoading;

  const _AddUserModalFooter({
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
                btnText: isLoading ? 'Adding...' : 'Add User',
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
