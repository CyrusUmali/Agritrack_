library flareline_uikit;

import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flutter/material.dart';

enum ModalType { small, medium, large }

class ModalPosition {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  
  const ModalPosition({
    this.top,
    this.bottom,
    this.left,
    this.right,
  });
  
  const ModalPosition.center()
      : top = null,
        bottom = null,
        left = null,
        right = null;
}

class ModalDialog {
  static show({
    required BuildContext context,
    String? title,
    bool? showTitle = false,
    bool? showTitleDivider = false,
    Alignment? titleAlign = Alignment.center,
    Widget? child,
    Widget? footer,
    bool? showFooter,
    bool? showCancel = true,
    ModalType modalType = ModalType.large,
    double? width,
    double? maxHeight,
    GestureTapCallback? onCancelTap,
    GestureTapCallback? onSaveTap,
    // Positioning parameters
    ModalPosition position = const ModalPosition.center(),
    bool dismissOnTapOutside = true,
    Color? barrierColor,
    Duration transitionDuration = const Duration(milliseconds: 300),
    Curve transitionCurve = Curves.easeInOut,
    String barrierLabel = 'Dismiss', // Added barrierLabel with default value
  }) {
    // Get screen dimensions
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    // Set default max height if not provided (70% of screen height)
    maxHeight ??= screenHeight * 0.7;

    // Adjust modal width for mobile devices
    if (width == null) { 
      if (modalType == ModalType.large) {
        width = screenWidth < 600 ? screenWidth * 0.9 : screenWidth * 0.6;
      } else if (modalType == ModalType.medium) {
        width = screenWidth < 600 ? screenWidth * 0.8 : screenWidth * 0.4;
      } else if (modalType == ModalType.small) {
        width = screenWidth < 600 ? screenWidth * 0.7 : screenWidth * 0.28;
      }
    }

    Widget confirmWidget;

    if (showCancel!) {
      confirmWidget = SizedBox(
        width: 120,
        child: ButtonWidget(
          btnText: 'Save',
          onTap: onSaveTap,
          type: ButtonType.primary.type,
        ),
      );
    } else {
      confirmWidget = Expanded(
        child: ButtonWidget(
          btnText: 'Save',
          onTap: onSaveTap,
          type: ButtonType.primary.type,
        ),
      );
    }

    // Create the modal widget
    Widget modalContent = Material(
      type: MaterialType.transparency,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width!,
          maxHeight: maxHeight,
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
              if (showTitle != null)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth < 600 ? 10 : 20,
                  ),
                  alignment: Alignment.center,
                  height: 50,
                  child: Stack(
                    children: [
                      if (title != null)
                        Align(
                          alignment: titleAlign!,
                          child: Text(
                            title,
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
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              if (showTitleDivider ?? false)
                const Divider(
                  thickness: 0,
                  height: 0.2,
                  color: FlarelineColors.darkBorder,
                ),
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth < 600 ? 10 : 20),
                    child: child,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (showFooter ?? true)
                if (footer != null)
                  footer
                else
                  Container(
                    margin: EdgeInsets.only(
                      left: screenWidth < 600 ? 10 : 20,
                      right: screenWidth < 600 ? 10 : 20,
                      bottom: screenWidth < 600 ? 10 : 20,
                    ),
                    child: Row(
                      children: [
                        if (showCancel) const Spacer(),
                        if (showCancel)
                          SizedBox(
                            width: 120,
                            child: ButtonWidget(
                              btnText: 'Cancel',
                              textColor: FlarelineColors.darkBlackText,
                              onTap: () {
                                Navigator.of(context).pop();
                                if (onCancelTap != null) {
                                  onCancelTap();
                                }
                              },
                            ),
                          ),
                        if (showCancel) const SizedBox(width: 20),
                        confirmWidget,
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ),
    );

    // Wrap with SingleChildScrollView and padding
    modalContent = SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(screenWidth < 600 ? 10 : 20),
        child: modalContent,
      ),
    );

    // Position the modal based on parameters
    if (position.top != null || 
        position.bottom != null || 
        position.left != null || 
        position.right != null) {
      // Positioned modal
      modalContent = Align(
        alignment: Alignment.topLeft,
        child: Container(
          margin: EdgeInsets.only(
            top: position.top ?? 0,
            bottom: position.bottom ?? 0,
            left: position.left ?? 0,
            right: position.right ?? 0,
          ),
          child: modalContent,
        ),
      );
    } else {
      // Centered modal (default behavior)
      modalContent = Center(
        child: modalContent,
      );
    }

    return showGeneralDialog(
      context: context,
      barrierDismissible: dismissOnTapOutside,
      barrierLabel: barrierLabel, // Added barrierLabel parameter
      barrierColor: barrierColor ?? Colors.black54,
      transitionDuration: transitionDuration,
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: transitionCurve,
          ),
          child: child,
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return modalContent;
      },
    );
  }
}