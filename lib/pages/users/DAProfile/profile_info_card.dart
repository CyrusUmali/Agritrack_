import 'package:flareline/core/models/user_model.dart';
import 'package:flareline/pages/toast/toast_helper.dart';
import 'package:flareline/services/lanugage_extension.dart';
import 'package:flutter/material.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../user_bloc/user_bloc.dart';

class UserInfoCard extends StatefulWidget {
  final Map<String, dynamic> user;
  final bool isMobile;

  const UserInfoCard({super.key, required this.user, this.isMobile = false});

  @override
  State<UserInfoCard> createState() => _UserInfoCardState();
}

class _UserInfoCardState extends State<UserInfoCard> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _contactController;

  String? _nameError;
  String? _contactError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user['name'] ?? '');
    _contactController =
        TextEditingController(text: widget.user['phone'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset controllers and errors when exiting edit mode
        _nameController.text = widget.user['name'] ?? '';
        _contactController.text = widget.user['phone'] ?? '';
        _nameError = null;
        _contactError = null;
      }
    });
  }

  void _clearErrors() {
    setState(() {
      _nameError = null;
      _contactError = null;
    });
  }

  bool _validateFields() {
    bool isValid = true;
    _clearErrors();

    // Validate name
    if (_nameController.text.isEmpty) {
      setState(() {
        _nameError = 'Name is required';
      });
      isValid = false;
    }

    // Validate contact (optional field, but if provided should be valid)
    if (_contactController.text.isNotEmpty && _contactController.text.length < 3) {
      setState(() {
        _contactError = 'Contact number should be at least 3 characters';
      });
      isValid = false;
    }

    return isValid;
  }

  void _saveChanges() {
    if (!_validateFields()) {
      return;
    }

    if (_formKey.currentState!.validate()) {
      // Get the current user data
      final updatedUser = Map<String, dynamic>.from(widget.user);

      // Update with new values
      updatedUser['name'] = _nameController.text;
      updatedUser['phone'] = _contactController.text;
 

      // Dispatch the UpdateUser event
      context.read<UserBloc>().add(UpdateUser(
            UserModel.fromJson(updatedUser),
          ));

      // _toggleEdit();
    }
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required Widget value,
    IconData? icon,
    String? errorText,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasError = errorText != null;

    // Use explicit red color for errors
    final errorColor = Colors.red.shade400;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color:
                      hasError ? errorColor : colors.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color:
                      hasError ? errorColor : colors.onSurface.withOpacity(0.6),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasError
                    ? errorColor
                    : Theme.of(context).cardTheme.surfaceTintColor!,
                width: hasError ? 2.0 : 1.0,
              ),
            ),
            child: value,
          ),
          if (hasError) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.error_outline, size: 14, color: errorColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    errorText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: errorColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    String? errorText,
    bool enabled = true,
  }) {
    return _buildInfoRow(
      context,
      label: label,
      icon: icon,
      errorText: errorText,
      value: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
        validator: validator,
        onChanged: (_) {
          // Clear field-specific error when user types
          if (errorText != null) {
            setState(() {
              if (controller == _nameController) {
                _nameError = null;
              } else if (controller == _contactController) {
                _contactError = null;
              }
            });
          }
        },
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    IconData? icon,
  }) {
    return _buildInfoRow(
      context,
      label: label,
      icon: icon,
      value: Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isCurrentUser = userProvider.user?.id == widget.user['id'];
    final theme = Theme.of(context); 

    return BlocListener<UserBloc, UserState>(
        listener: (context, state) {
          if (state is UsersError) {
            ToastHelper.showErrorToast(
              state.message,
              context,
            );
          } else if (state is UserUpdated) {
            final currentUser = userProvider.user;
            if (currentUser != null) {
              final updatedUser = currentUser.copyWith(
                name: _nameController.text,
                phone: _contactController.text,
              );
              userProvider.setUser(updatedUser);
            }

            ToastHelper.showSuccessToast(
                'Profile updated successfully', context);
            _toggleEdit(); // Exit edit mode after successful save
          }
        },
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.isMobile ? 12 : 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_outline),
                          const SizedBox(width: 12),
                          Text(
                            context.translate('Personal Information'), 
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold, 
                            ),
                          ),
                        ],
                      ),
                      if (isCurrentUser)
                        IconButton(
                          icon: Icon(_isEditing ? Icons.close : Icons.edit),
                          onPressed: _toggleEdit,
                          tooltip: _isEditing ? 'Cancel' : 'Edit',
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isEditing) ...[
                    _buildEditableField(
                      label: context.translate('Full Name'),      
                      controller: _nameController,
                      icon: Icons.person_outline,
                      errorText: _nameError,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    _buildReadOnlyField(
                      label: 'Email',
                      value: widget.user['email'] ?? 'N/A',
                      icon: Icons.email_outlined,
                    ),
                    _buildEditableField(
                      label:  context.translate('Contact Number'),   
                      controller: _contactController,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      errorText: _contactError,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saveChanges,
                        child: Text(
                          context.translate('Save Changes'),    
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    _buildReadOnlyField(
                     label: context.translate('Full Name'),      
                      value: widget.user['name'] ?? 'N/A',
                      icon: Icons.person_outline,
                    ),
                    _buildReadOnlyField(
                      label: 'Email',
                      value: widget.user['email'] ?? 'N/A',
                      icon: Icons.email_outlined,
                    ),
                    _buildReadOnlyField(
                     label:  context.translate('Contact Number'),   
                      value: widget.user['phone'] ?? 'N/A',
                      icon: Icons.phone_outlined,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ));
  }
}