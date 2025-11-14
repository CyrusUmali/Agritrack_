library flareline_uikit;

import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flutter/material.dart';

enum ModalType { small, medium, large }

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
    double? maxHeight, // New parameter for maximum height
    GestureTapCallback? onCancelTap,
    GestureTapCallback? onSaveTap,
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

    return showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(screenWidth < 600 ? 10 : 20),
              child: Material(
                type: MaterialType.transparency,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: width!,
                    maxHeight: maxHeight!,
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
                              padding:
                                  EdgeInsets.all(screenWidth < 600 ? 10 : 20),
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
                                        textColor:
                                            FlarelineColors.darkBlackText,
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
              ),
            ),
          ),
        );
      },
    );
  }
}
