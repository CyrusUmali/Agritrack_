import 'package:flareline/pages/assoc/assoc_bloc/assocs_bloc.dart';
import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flareline_uikit/components/modal/modal_dialog.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toastification/toastification.dart';

class AddAssociationModal extends StatefulWidget {
  const AddAssociationModal({Key? key}) : super(key: key);

  static Future<void> show(BuildContext context) async {
    final associationBloc = BlocProvider.of<AssocsBloc>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final contentKey = GlobalKey<_AddAssociationModalContentState>();
    bool isLoading = false;

    await ModalDialog.show(
      context: context,
      title: 'Add New Association',
      showTitle: true,
      showTitleDivider: true,
      modalType: screenWidth < 600 ? ModalType.large : ModalType.medium,
      child: BlocProvider.value(
        value: associationBloc,
        child: _AddAssociationModalContent(
          key: contentKey,
          onLoadingStateChanged: (loading) {
            isLoading = loading;
          },
        ),
      ),
      footer: _AddAssociationModalFooter(
        onSubmit: () {
          if (contentKey.currentState != null && !isLoading) {
            contentKey.currentState!._submitAssociation();
          }
        },
        onCancel: () => Navigator.of(context).pop(),
        isLoading: isLoading,
      ),
    );
  }

  @override
  State<AddAssociationModal> createState() => _AddAssociationModalState();
}

class _AddAssociationModalState extends State<AddAssociationModal> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _AddAssociationModalContent extends StatefulWidget {
  final Function(bool) onLoadingStateChanged;

  const _AddAssociationModalContent({
    Key? key,
    required this.onLoadingStateChanged,
  }) : super(key: key);

  @override
  State<_AddAssociationModalContent> createState() =>
      _AddAssociationModalContentState();
}

class _AddAssociationModalContentState
    extends State<_AddAssociationModalContent> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    widget.onLoadingStateChanged(false);
  }

  void _submitAssociation() async {
    final associationBloc = context.read<AssocsBloc>();
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

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

    try {
      associationBloc.add(CreateAssoc(
        name: name,
        description: description,
      ));

      await Future.delayed(const Duration(milliseconds: 500));

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
    _nameController.dispose();
    _descriptionController.dispose();
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
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Association Name',
              border: const OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                vertical: screenWidth < 600 ? 10.0 : 16.0,
                horizontal: 10.0,
              ),
            ),
          ),
          SizedBox(height: screenWidth < 600 ? 16.0 : 24.0),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description',
              border: const OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                vertical: screenWidth < 600 ? 10.0 : 16.0,
                horizontal: 10.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddAssociationModalFooter extends StatelessWidget {
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  final bool isLoading;

  const _AddAssociationModalFooter({
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
                btnText: isLoading ? 'Saving...' : 'Save ',
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
