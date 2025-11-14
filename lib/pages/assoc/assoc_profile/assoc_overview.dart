import 'package:flareline/core/models/assocs_model.dart';
import 'package:flareline/pages/assoc/assoc_bloc/assocs_bloc.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

class AssociationOverviewPanel extends StatefulWidget {
  final Association association;
  final bool isMobile;
  final VoidCallback? onUpdateSuccess;

  const AssociationOverviewPanel({
    super.key,
    required this.association,
    this.isMobile = false,
    this.onUpdateSuccess,
  });

  @override
  State<AssociationOverviewPanel> createState() =>
      _AssociationOverviewPanelState();
}

class _AssociationOverviewPanelState extends State<AssociationOverviewPanel> {
  late TextEditingController _descriptionController;
  late TextEditingController _nameController;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.association.description);
    _nameController = TextEditingController(text: widget.association.name);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset to original values when canceling edit
        _descriptionController.text = widget.association.description ?? '';
        _nameController.text = widget.association.name;
      }
    });
  }

  void _showSuccessToast(String message) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      title: Text(message),
      autoCloseDuration: const Duration(seconds: 5),
    );
  }

  void _showErrorToast(String message) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.flat,
      title: Text(message),
      autoCloseDuration: const Duration(seconds: 5),
    );
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      final updatedAssociation = widget.association.copyWith(
        name: _nameController.text,
        description: _descriptionController.text,
      );

      try {
        context.read<AssocsBloc>().add(UpdateAssoc(updatedAssociation));
        _showSuccessToast('${widget.association.name} updated successfully!');
        _toggleEditMode();
      } catch (e) {
        _showErrorToast(
            'Failed to update ${widget.association.name}: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isFarmer = userProvider.isFarmer;

    return Card(
      elevation: widget.isMobile ? 8 : 24,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(widget.isMobile ? 12 : 16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(widget.isMobile ? 8 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.assessment_outlined,
                    size: widget.isMobile ? 20 : 24),
                SizedBox(width: widget.isMobile ? 8 : 12),
                Expanded(
                  child: _isEditing
                      ? TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter association name',
                            isDense: widget.isMobile,
                            contentPadding: EdgeInsets.zero,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a name';
                            }
                            return null;
                          },
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                            fontSize: widget.isMobile ? 18 : null,
                          ),
                        )
                      : Text(
                          '${widget.association.name} Overview',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                            fontSize: widget.isMobile ? 18 : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                if (!isFarmer) ...[
                  IconButton(
                    icon: Icon(
                      _isEditing ? Icons.close : Icons.edit,
                      size: widget.isMobile ? 20 : 24,
                    ),
                    onPressed: _toggleEditMode,
                    tooltip: _isEditing ? 'Cancel' : 'Edit',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  if (_isEditing) ...[
                    SizedBox(width: widget.isMobile ? 4 : 8),
                    IconButton(
                      icon: Icon(
                        Icons.save,
                        size: widget.isMobile ? 20 : 24,
                      ),
                      onPressed: _saveChanges,
                      tooltip: 'Save',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ],
              ],
            ),
            SizedBox(height: widget.isMobile ? 16 : 24),
            _isEditing
                ? _buildEditForm(context)
                : Column(
                    children: [
                      _buildInfoRow(
                        context,
                        icon: Icons.badge_outlined,
                        label: 'Name',
                        value: widget.association.name,
                      ),
                      SizedBox(height: widget.isMobile ? 12 : 16),
                      _buildInfoRow(
                        context,
                        icon: Icons.description_outlined,
                        label: 'Description',
                        value: widget.association.description ??
                            'No description available for this association.',
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name Field
          Row(
            children: [
              Icon(Icons.badge_outlined,
                  size: widget.isMobile ? 16 : 18,
                  color: colors.onSurface.withOpacity(0.6)),
              SizedBox(width: widget.isMobile ? 4 : 8),
              Text(
                'NAME',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurface.withOpacity(0.6),
                  letterSpacing: 0.5,
                  fontSize: widget.isMobile ? 12 : null,
                ),
              ),
            ],
          ),
          SizedBox(height: widget.isMobile ? 4 : 8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(widget.isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(widget.isMobile ? 8 : 12),
            ),
            child: TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter association name...',
                isDense: widget.isMobile,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
          ),
          SizedBox(height: widget.isMobile ? 12 : 16),
          // Description Field
          Row(
            children: [
              Icon(Icons.description_outlined,
                  size: widget.isMobile ? 16 : 18,
                  color: colors.onSurface.withOpacity(0.6)),
              SizedBox(width: widget.isMobile ? 4 : 8),
              Text(
                'DESCRIPTION',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurface.withOpacity(0.6),
                  letterSpacing: 0.5,
                  fontSize: widget.isMobile ? 12 : null,
                ),
              ),
            ],
          ),
          SizedBox(height: widget.isMobile ? 4 : 8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(widget.isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color:Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(widget.isMobile ? 8 : 12),
            ),
            child: TextFormField(
              controller: _descriptionController,
              maxLines: widget.isMobile ? 3 : 5,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter association description...',
                isDense: widget.isMobile,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    IconData? icon,
    bool isHighlighted = false,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: widget.isMobile ? 16 : 18,
                  color: colors.onSurface.withOpacity(0.6)),
              SizedBox(width: widget.isMobile ? 4 : 8),
            ],
            Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurface.withOpacity(0.6),
                letterSpacing: 0.5,
                fontSize: widget.isMobile ? 12 : null,
              ),
            ),
          ],
        ),
        SizedBox(height: widget.isMobile ? 4 : 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(widget.isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            // color:
            //     isHighlighted ? colors.primaryContainer : colors.surfaceVariant,
            borderRadius: BorderRadius.circular(widget.isMobile ? 8 : 12),
            border: isHighlighted
                ? Border.all(color: colors.primary.withOpacity(0.2))
                : null,
          ),
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isHighlighted
                  ? colors.onPrimaryContainer
                  : colors.onSurfaceVariant,
              height: 1.4,
              fontSize: widget.isMobile ? 14 : null,
            ),
          ),
        ),
      ],
    );
  }
}