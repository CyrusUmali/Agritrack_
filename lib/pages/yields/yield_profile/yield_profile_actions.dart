import 'package:flareline/providers/user_provider.dart';
import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class YieldProfileActions extends StatefulWidget {
  final bool isMobile;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onSave;
  final VoidCallback onDelete;
  final bool isLoading;
  final bool isDeleting;
  final bool isAccepting;
  final bool isRejecting;
  final String? yieldStatus; // Add this new parameter

  const YieldProfileActions({
    super.key,
    required this.isMobile,
    required this.onAccept,
    required this.onReject,
    required this.onSave,
    required this.onDelete,
    this.isLoading = false,
    this.isDeleting = false,
    this.isAccepting = false,
    this.isRejecting = false,
    this.yieldStatus, // Add this
  });

  @override
  State<YieldProfileActions> createState() => _YieldProfileActionsState();
}

class _YieldProfileActionsState extends State<YieldProfileActions> {
  @override
  void initState() {
    super.initState();
    print('YieldProfileActions initialized');
  }

  @override
  void didUpdateWidget(YieldProfileActions oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Print when any of the loading states change
    if (widget.isLoading != oldWidget.isLoading) {
      print(
          'isLoading changed from ${oldWidget.isLoading} to ${widget.isLoading}');
    }
    if (widget.isDeleting != oldWidget.isDeleting) {
      print(
          'isDeleting changed from ${oldWidget.isDeleting} to ${widget.isDeleting}');
    }
    if (widget.isAccepting != oldWidget.isAccepting) {
      print(
          'isAccepting changed from ${oldWidget.isAccepting} to ${widget.isAccepting}');
    }
    if (widget.isRejecting != oldWidget.isRejecting) {
      print(
          'isRejecting changed from ${oldWidget.isRejecting} to ${widget.isRejecting}');
    }

    print('YieldProfileActions didUpdateWidget - rebuild triggered');
  }

  // Helper methods to determine which buttons to show
  bool get _shouldShowAcceptButton {
    return widget.yieldStatus !=
        'Accepted'; // Show Accept if status is NOT Accepted
  }

  bool get _shouldShowRejectButton {
    return widget.yieldStatus !=
        'Rejected'; // Show Reject if status is NOT Rejected
  }

  @override
  Widget build(BuildContext context) {
    print('YieldProfileActions build method called');
    print('Yield status: ${widget.yieldStatus}');
    print('Show Accept: $_shouldShowAcceptButton');
    print('Show Reject: $_shouldShowRejectButton');

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final isFarmer = userProvider.isFarmer;
        print('Consumer rebuild - isFarmer: $isFarmer');

        final buttonWidth = widget.isMobile ? double.infinity : 180.0;

        // Check if we should show any Accept/Reject buttons
        final shouldShowAcceptRejectSection =
            !isFarmer && (_shouldShowAcceptButton || _shouldShowRejectButton);

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: widget.isMobile ? double.infinity : 600),
            child: Column(
              children: [
                // First row with SAVE and DELETE buttons
                Row(
                  children: [
                    if (!widget.isMobile) const Spacer(),
                    Expanded(
                      child: SizedBox(
                        width: buttonWidth,
                        child: ButtonWidget(
                          btnText: "Save Changes",
                          textColor: FlarelineColors.background,
                          onTap: () {
                            print('Save button pressed');
                            widget.onSave();
                          },
                          type: ButtonType.primary.type,
                          isLoading: widget.isLoading,
                          height: 48,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: SizedBox(
                        width: buttonWidth,
                        child: ButtonWidget(
                          btnText: "Delete Record",
                          textColor: FlarelineColors.background,
                          onTap: () {
                            print('Delete button pressed');
                            widget.onDelete();
                          },
                          type: ButtonType.danger.type,
                          isLoading: widget.isDeleting,
                          height: 48,
                        ),
                      ),
                    ),
                    if (!widget.isMobile) const Spacer(),
                  ],
                ),

                // Show Accept/Reject section if:
                // 1. User is not a farmer
                // 2. AND at least one of the buttons should be shown
                if (shouldShowAcceptRejectSection) ...[
                  SizedBox(height: widget.isMobile ? 16 : 24),
                  widget.isMobile
                      ? Column(
                          children: [
                            // Show Reject button if status is NOT Rejected
                            if (_shouldShowRejectButton) ...[
                              SizedBox(
                                width: buttonWidth,
                                child: ButtonWidget(
                                  btnText: "Reject",
                                  textColor: FlarelineColors.background,
                                  onTap: () {
                                    print('Reject button pressed');
                                    widget.onReject();
                                  },
                                  type: ButtonType.danger.type,
                                  isLoading: widget.isRejecting,
                                  height: 48,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            // Show Accept button if status is NOT Accepted
                            if (_shouldShowAcceptButton)
                              SizedBox(
                                width: buttonWidth,
                                child: ButtonWidget(
                                  btnText: "Accept",
                                  textColor: FlarelineColors.background,
                                  onTap: () {
                                    print('Accept button pressed');
                                    widget.onAccept();
                                  },
                                  type: ButtonType.success.type,
                                  isLoading: widget.isAccepting,
                                  height: 48,
                                ),
                              ),
                          ],
                        )
                      : Row(
                          children: [
                            const Spacer(),
                            // Show Reject button if status is NOT Rejected
                            if (_shouldShowRejectButton)
                              Expanded(
                                child: SizedBox(
                                  width: buttonWidth,
                                  child: ButtonWidget(
                                    btnText: "Reject",
                                    textColor: FlarelineColors.background,
                                    onTap: () {
                                      print('Reject button pressed');
                                      widget.onReject();
                                    },
                                    type: ButtonType.danger.type,
                                    isLoading: widget.isRejecting,
                                    height: 48,
                                  ),
                                ),
                              ),
                            if (_shouldShowRejectButton &&
                                _shouldShowAcceptButton)
                              const SizedBox(width: 20),
                            // Show Accept button if status is NOT Accepted
                            if (_shouldShowAcceptButton)
                              Expanded(
                                child: SizedBox(
                                  width: buttonWidth,
                                  child: ButtonWidget(
                                    btnText: "Accept",
                                    textColor: FlarelineColors.background,
                                    onTap: () {
                                      print('Accept button pressed');
                                      widget.onAccept();
                                    },
                                    type: ButtonType.success.type,
                                    isLoading: widget.isAccepting,
                                    height: 48,
                                  ),
                                ),
                              ),
                            const Spacer(),
                          ],
                        ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
