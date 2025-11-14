import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/pages/toast/toast_helper.dart';
import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flutter/material.dart';

class SimpleAnnotationDialog extends StatefulWidget {
  final String year;
  final double initialValue;
  final String initialText;
  final bool isEditing;
  final Function(double)? onValueChanged;

  const SimpleAnnotationDialog({
    required this.year,
    required this.initialValue,
    required this.initialText,
    this.isEditing = false,
    this.onValueChanged,
    super.key,
  });

  @override
  State<SimpleAnnotationDialog> createState() => _SimpleAnnotationDialogState();
}

class _SimpleAnnotationDialogState extends State<SimpleAnnotationDialog> {
  late TextEditingController _textController;
  late double _currentValue;
  late TextEditingController _valueController;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
    _textController = TextEditingController(text: widget.initialText);
    _valueController =
        TextEditingController(text: _currentValue.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _textController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 600;

    // Calculate width based on screen size
    double width;
    if (screenWidth < 600) {
      width = screenWidth * 0.9;
    } else {
      width = screenWidth * 0.4; // Medium size for desktop
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4), // Match ModalDialog's border radius
      ),
      elevation: 4,
      insetPadding: EdgeInsets.all(screenWidth < 600 ? 10 : 20), // Match ModalDialog padding
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width,
          maxHeight: MediaQuery.of(context).size.height * 0.7, // Match ModalDialog maxHeight
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button - matching ModalDialog structure
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth < 600 ? 10 : 20,
                ),
                alignment: Alignment.center,
                height: 50,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        widget.isEditing ? 'Edit Annotation' : 'Add Annotation',
                        style: TextStyle(
                          fontSize: screenWidth < 600 ? 14 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        child: const Icon(Icons.close),
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content area with proper padding
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth < 600 ? 10 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Year display
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:   colorScheme.surfaceVariant.withOpacity(0.1),
                            
                            borderRadius: BorderRadius.circular(4), // Match main border radius
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 18,
                                  color: colorScheme.onSurface.withOpacity(0.7)),
                              const SizedBox(width: 8),
                              Text('Year: ${widget.year}',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(0.8),
                                  )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Value input
                        Text('Value (kg)',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface.withOpacity(0.8),
                            )),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              flex: isDesktop ? 3 : 1,
                              child: TextField(
                                controller: _valueController,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4), // Match border radius
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: colorScheme.surfaceVariant.withOpacity(0.1),
                                  suffixText: 'kg',
                                  suffixStyle: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                style: textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  final newValue =
                                      double.tryParse(value) ?? _currentValue;
                                  if (newValue != _currentValue) {
                                    setState(() {
                                      _currentValue = newValue;
                                    });
                                    widget.onValueChanged?.call(newValue);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              children: [
                                FloatingActionButton.small(
                                  heroTag: 'increment',
                                  onPressed: () => _adjustValue(1000),
                                  // backgroundColor: colorScheme.primaryContainer,
                                  backgroundColor:    Theme.of(context).brightness == Brightness.dark
                            ? colorScheme.onSurface.withOpacity(0.1)
                            : theme.primaryColor.withOpacity(0.1),
                                  elevation: 0, 
                                  child: Icon(Icons.add,
                                      color: colorScheme.onPrimaryContainer),
                                ),
                                const SizedBox(height: 8),
                                FloatingActionButton.small(
                                  heroTag: 'decrement',
                                  onPressed: () => _adjustValue(-1000),
                                backgroundColor:    Theme.of(context).brightness == Brightness.dark
                            ? colorScheme.onSurface.withOpacity(0.1)
                            : theme.primaryColor.withOpacity(0.1),
                                  elevation: 0,
                                  child: Icon(Icons.remove,
                                      color: colorScheme.onPrimaryContainer),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Annotation text field
                        Text('Annotation',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface.withOpacity(0.8),
                            )),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _textController,
                          decoration: InputDecoration(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4), // Match border radius
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceVariant.withOpacity(0.1),
                            hintText: widget.isEditing
                                ? 'Edit your annotation'
                                : 'Enter annotation description',
                            hintStyle: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.1),
                            ),
                          ),
                          style: textTheme.bodyLarge,
                          maxLines: isDesktop ? 4 : 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Footer buttons - matching ModalDialog footer structure
              Container(
                margin: EdgeInsets.only(
                  left: screenWidth < 600 ? 10 : 20,
                  right: screenWidth < 600 ? 10 : 20,
                  bottom: screenWidth < 600 ? 10 : 20,
                ),
                child: Row(
                  children: [
                    const Spacer(),
                    if (widget.isEditing)
                      SizedBox(
                        width: 120,
                        child: ButtonWidget(
                          btnText: 'Delete',
                          textColor: Colors.white, // Use appropriate color
                          onTap: () {
                            Navigator.pop(context, {
                              'delete': true,
                            });
                          },
                          type: ButtonType.danger.type,
                        ),
                      ),
                    if (widget.isEditing) const SizedBox(width: 20),
                    SizedBox(
                      width: 120,
                      child: ButtonWidget(
                        btnText: 'Cancel',
                        textColor: FlarelineColors.darkBlackText,
                        onTap: () => Navigator.pop(context),
                        
                      ),
                    ),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 120,
                      child: ButtonWidget(
                        btnText: widget.isEditing ? 'Update' : 'Add',
                        onTap: () {
                          if (_textController.text.isEmpty) {
                            ToastHelper.showSuccessToast(
                                'Please enter annotation text', context);
                            return;
                          }
                          Navigator.pop(context, {
                            'text': _textController.text,
                            'value': _currentValue,
                            'isEditing': widget.isEditing,
                          });
                        },
                        type: ButtonType.primary.type,
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

  void _adjustValue(double amount) {
    final newValue =
        (_currentValue + amount).clamp(0, double.infinity) as double;
    setState(() {
      _currentValue = newValue;
      _valueController.text = newValue.toStringAsFixed(0);
    });
    widget.onValueChanged?.call(newValue);
  }
}