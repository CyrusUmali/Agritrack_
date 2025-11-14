// ignore_for_file: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member

import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flareline_uikit/components/modal/modal_dialog.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flutter/material.dart';

void showBarangayFilterModal(BuildContext context) {
  // Sample barangay data
  final List<String> allBarangays = [
    'Barangay 1',
    'Barangay 2',
    'Barangay 3',
    'Barangay 4',
    'Barangay 5',
    'Barangay 6'
  ];

  final double screenWidth = MediaQuery.of(context).size.width;

  // State management
  final selectedBarangays = <String>{};
  final searchController = TextEditingController();
  final filteredBarangays = ValueNotifier<List<String>>(allBarangays);
  final focusNode = FocusNode();

  // Search function
  void filterBarangays(String query) {
    if (query.isEmpty) {
      filteredBarangays.value = allBarangays;
    } else {
      filteredBarangays.value = allBarangays
          .where((barangay) =>
              barangay.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  ModalDialog.show(
    context: context,
    title: 'Filter by Barangay',
    showTitle: true,
    showTitleDivider: true,
    modalType: ModalType.medium,
    onCancelTap: () => Navigator.of(context).pop(),
    onSaveTap: () {
      // Handle selected barangays
      print('Selected barangays: $selectedBarangays');
      Navigator.of(context).pop();
    },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search input (Material 3 style)
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: SearchBar(
            controller: searchController,
            focusNode: focusNode,
            hintText: 'Search barangay...',
            leading: const Icon(Icons.search),
            trailing: [
              if (searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    searchController.clear();
                    filterBarangays('');
                    focusNode.unfocus();
                  },
                ),
            ],
            onChanged: filterBarangays,
            elevation: MaterialStateProperty.all(1.0),
            shape: MaterialStateProperty.all(
              const ContinuousRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
        ),
        // Select All checkbox
        SizedBox(
          height: 48,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (selectedBarangays.length == allBarangays.length) {
                  selectedBarangays.clear();
                } else {
                  selectedBarangays.addAll(allBarangays);
                }
                filteredBarangays.notifyListeners();
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Checkbox(
                      value: selectedBarangays.length == allBarangays.length,
                      onChanged: (value) {
                        if (value == true) {
                          selectedBarangays.addAll(allBarangays);
                        } else {
                          selectedBarangays.clear();
                        }
                        filteredBarangays.notifyListeners();
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      visualDensity: VisualDensity.compact,
                      activeColor:
                          FlarelineColors.primary, // Set the active color
                      checkColor: Colors.white, // Set the checkmark color
                    ),
                    const Text(
                      'Select All',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Divider
        const Divider(height: 1),
        // Barangay list with checkboxes
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: ValueListenableBuilder<List<String>>(
            valueListenable: filteredBarangays,
            builder: (context, filteredList, _) {
              return ListView.builder(
                shrinkWrap: true,
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final barangay = filteredList[index];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (selectedBarangays.contains(barangay)) {
                          selectedBarangays.remove(barangay);
                        } else {
                          selectedBarangays.add(barangay);
                        }
                        filteredBarangays.notifyListeners();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          children: [
                            Checkbox(
                              value: selectedBarangays.contains(barangay),
                              onChanged: (value) {
                                if (value == true) {
                                  selectedBarangays.add(barangay);
                                } else {
                                  selectedBarangays.remove(barangay);
                                }
                                filteredBarangays.notifyListeners();
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              visualDensity: VisualDensity.compact,
                              activeColor: FlarelineColors
                                  .primary, // Set the active color
                              checkColor:
                                  Colors.white, // Set the checkmark color
                            ),
                            Text(
                              barangay,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
    footer: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: screenWidth < 600 ? 100 : 120,
              child: ButtonWidget(
                btnText: 'Cancel',
                textColor: FlarelineColors.darkBlackText,
                onTap: () {
                  Navigator.of(context).pop(); // Close the modal
                },
              ),
            ),
            const SizedBox(width: 20),
            SizedBox(
              width: screenWidth < 600 ? 100 : 120,
              child: ButtonWidget(
                btnText: 'Apply',
                onTap: () {
                  Navigator.of(context).pop(); // Close the modal
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
