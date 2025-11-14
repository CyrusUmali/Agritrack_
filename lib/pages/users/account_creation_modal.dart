import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/modal/modal_dialog.dart';
import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';

class AccountCreationMethodModal {
  static void show({
    required BuildContext context,
    required Function(String role, String method) onMethodSelected,
    required Function() onLinkExistingFarmer,
  }) {
    String selectedRole = 'farmer';
    String selectedMethod = 'email';

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 600;

    ModalDialog.show(
      context: context,
      title: 'Create New Account',
      
      showTitle: true,
      showTitleDivider: true,
      modalType: isSmallScreen ? ModalType.large : ModalType.medium,
      onCancelTap: () => Navigator.of(context).pop(),
      onSaveTap: () {
        Navigator.of(context).pop();
        onMethodSelected(selectedRole, selectedMethod);
      },
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Padding(
            padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Role Selection
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  
                  decoration: InputDecoration( 
                    labelText: 'Account Role',
                    border: const OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 10.0 : 16.0,
                      horizontal: 10.0,
                    ),
                    // filled: true, // Add this
    // fillColor:Theme.of(context).cardTheme.color,
                  ),
                  dropdownColor: Theme.of(context).cardTheme.color,
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'officer', child: Text('Officer')),
                    DropdownMenuItem(value: 'farmer', child: Text('Farmer')),
                  ],
                  onChanged: (String? value) {
                    if (value != null) {
                      setModalState(() {
                        selectedRole = value;
                      });
                    }
                  },
                ),
                SizedBox(height: isSmallScreen ? 16.0 : 24.0),

                // Method Selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Creation Method',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Email Account'),
                            selected: selectedMethod == 'email',
                            onSelected: (bool selected) {
                              setModalState(() {
                                selectedMethod = 'email';
                              });
                            },

                               backgroundColor:   Theme.of(context).cardTheme.color,   
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                        
                          child: ChoiceChip( 
                            label: const Text('Google Account'),
                            selected: selectedMethod == 'google',
                            onSelected: (bool selected) {
                              setModalState(() {
                                selectedMethod = 'google';
                              });
                            },
                         
                         
                          backgroundColor:   Theme.of(context).cardTheme.color,   
      
                          ), 
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      footer: Padding(
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
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              SizedBox(width: screenWidth < 600 ? 10 : 20),
              SizedBox(
                width: screenWidth < 600 ? 100 : 120,
                child: ButtonWidget(
                  btnText: 'Continue',
                  onTap: () {
                    Navigator.of(context).pop();
                    onMethodSelected(selectedRole, selectedMethod);
                  },
                  type: ButtonType.primary.type,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
