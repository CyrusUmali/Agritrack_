import 'package:flareline/core/models/farmer_model.dart';
import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/modal/modal_dialog.dart';
import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';

class LinkUserModal extends StatefulWidget {
  final Function(UserData) onUserLinked;

  const LinkUserModal({Key? key, required this.onUserLinked}) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required String role,
    required Function(UserData) onUserLinked,
    String? googleEmail,
    List<Farmer> farmers = const [],
  }) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentKey = GlobalKey<_LinkUserModalContentState>();
    bool isLoading = false;

    await ModalDialog.show(
      context: context,
      title: 'Add New User',
      showTitle: true,
      showTitleDivider: true,
      modalType: screenWidth < 600 ? ModalType.small : ModalType.medium,
      child: _LinkUserModalContent(
        key: contentKey,
        role: role,
        googleEmail: googleEmail,
        farmers: farmers,
        onLoadingStateChanged: (loading) {
          isLoading = loading;
        },
        onUserLinked: onUserLinked,
      ),
      footer: _LinkUserModalFooter(
        onSubmit: () {
          if (contentKey.currentState != null && !isLoading) {
            contentKey.currentState!._submitUser();
          }
        },
        onCancel: () => Navigator.of(context).pop(),
        isLoading: isLoading,
        submitText: 'Add User',
      ),
    );
  }

  @override
  State<LinkUserModal> createState() => _LinkUserModalState();
}

class _LinkUserModalState extends State<LinkUserModal> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class UserData {
  final String name;
  final String email;
  final String? password;
  final String role;
  final int? farmerId;

  UserData({
    required this.name,
    required this.email,
    this.password,
    required this.role,
    this.farmerId,
  });
}

class _LinkUserModalContent extends StatefulWidget {
  final Function(bool) onLoadingStateChanged;
  final Function(UserData) onUserLinked;
  final String role;
  final String? googleEmail;
  final List<Farmer> farmers;

  const _LinkUserModalContent({
    Key? key,
    required this.onLoadingStateChanged,
    required this.onUserLinked,
    required this.role,
    this.googleEmail,
    this.farmers = const [],
  }) : super(key: key);

  @override
  State<_LinkUserModalContent> createState() => _LinkUserModalContentState();
}

class _LinkUserModalContentState extends State<_LinkUserModalContent> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController farmerSearchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  Farmer? selectedFarmer;

  // Track which fields have been validated
  bool _nameValidated = false;
  bool _emailValidated = false;
  bool _passwordValidated = false;
  bool _farmerValidated = false;

  final GlobalKey farmerFieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.googleEmail != null) {
      emailController.text = widget.googleEmail!;
    }
  }

  void _submitUser() async {
    // Mark all fields as validated
    setState(() {
      _nameValidated = true;
      _emailValidated = true;
      if (widget.googleEmail == null) _passwordValidated = true;
      if (widget.farmers.isNotEmpty) _farmerValidated = true;
    });

    if (!_formKey.currentState!.validate()) {
      // Validation failed, don't proceed
      print('Validation failed! Detailed errors:');

      // Check each field individually
      final nameError = _validateName(nameController.text);
      if (nameError != null) print('Name error: $nameError');

      final emailError = _validateEmail(emailController.text);
      if (emailError != null) print('Email error: $emailError');

      if (widget.googleEmail == null) {
        final passwordError = _validatePassword(passwordController.text);
        if (passwordError != null) print('Password error: $passwordError');
      }

      if (widget.farmers.isNotEmpty) {
        final farmerError = _validateFarmer(farmerSearchController.text);
        if (farmerError != null) print('Farmer error: $farmerError');
      }

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
        password:
            widget.googleEmail == null ? passwordController.text.trim() : null,
        role: widget.role,
        farmerId: selectedFarmer?.id,
      );

      // Call the callback
      widget.onUserLinked(userData);

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

  // Helper validation methods for debugging
  String? _validateName(String value) {
    if (value.trim().isEmpty) {
      return 'Please enter the user\'s name';
    }
    return null;
  }

  String? _validateEmail(String value) {
    if (value.trim().isEmpty) {
      return 'Please enter an email address';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String value) {
    if (value.trim().isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateFarmer(String value) {
    if (widget.farmers.isEmpty) return null;
    if (value.trim().isEmpty) {
      return 'Please select a farmer';
    }
    if (!widget.farmers.any((f) => f.name == value.trim())) {
      return 'Please select a valid farmer';
    }
    return null;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    farmerSearchController.dispose();
    super.dispose();
  }

  Widget _buildFarmerDetails() {
    if (selectedFarmer == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        if (selectedFarmer!.imageUrl != null)
          CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(selectedFarmer!.imageUrl!),
          ),
        const SizedBox(height: 8),
        Text('Name : ${selectedFarmer!.name}'),
        Text('Barangay: ${selectedFarmer!.barangay}'),
        const SizedBox(height: 4),
        Text('Phone: ${selectedFarmer!.phone}'),
      ],
    );
  }

  // Using the EXACT same pattern from your working AddYieldModal
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
              readOnly: widget.googleEmail != null,
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

            if (widget.googleEmail == null) ...[
              // Password Field with show/hide toggle
              TextFormField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password *',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
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
              SizedBox(height: screenWidth < 600 ? 8.0 : 16.0),
            ],

            // Farmer Autocomplete - Using the EXACT same pattern as your working AddYieldModal
            if (widget.farmers.isNotEmpty) ...[
              SizedBox(
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
                      farmerSearchController.text = farmer.name;
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
                    // Keep the text controllers in sync
                    textEditingController.text = farmerSearchController.text;

                    return TextFormField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Farmer *',
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
                      onChanged: (value) {
                        farmerSearchController.text = value;
                        if (_farmerValidated) {
                          _formKey.currentState!.validate();
                        }
                      },
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
              _buildFarmerDetails(),
            ],
          ],
        ),
      ),
    );
  }
}

class _LinkUserModalFooter extends StatelessWidget {
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  final bool isLoading;
  final String submitText;

  const _LinkUserModalFooter({
    Key? key,
    required this.onSubmit,
    required this.onCancel,
    this.isLoading = false,
    this.submitText = 'Add User',
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
                btnText: isLoading ? 'Processing...' : submitText,
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
