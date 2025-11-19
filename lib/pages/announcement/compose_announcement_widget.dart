import 'package:flareline/core/models/farmer_model.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/card/common_card.dart'; 

class ComposeAnnouncementWidget extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController messageController;
  final ValueNotifier<String> recipientTypeNotifier;
  final ValueNotifier<String?> selectedFarmerNotifier;
  final ValueNotifier<bool> isSendingNotifier;
  final ValueNotifier<bool> showComposeNotifier;
  final List<Farmer> farmers;
  final VoidCallback onSendAnnouncement;

  const ComposeAnnouncementWidget({
    super.key,
    required this.titleController,
    required this.messageController,
    required this.recipientTypeNotifier,
    required this.selectedFarmerNotifier,
    required this.isSendingNotifier,
    required this.showComposeNotifier,
    required this.farmers,
    required this.onSendAnnouncement,
  });

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color:Theme.of(context).cardTheme.surfaceTintColor!),
              ),
            ),
            child: Row(
              children: [
                if (MediaQuery.of(context).size.width < 768) ...[
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => showComposeNotifier.value = false,
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(Icons.create, color: FlarelineColors.primary, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'New Announcement',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    showComposeNotifier.value = false;
                    titleController.clear();
                    messageController.clear();
                    recipientTypeNotifier.value = 'everyone';
                    selectedFarmerNotifier.value = null;
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipient Type
                  const Text(
                    'Send To',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<String>(
                    valueListenable: recipientTypeNotifier,
                    builder: (context, recipientType, child) {
                      return Column(
                        children: [
                          InkWell(
                            onTap: () => recipientTypeNotifier.value = 'everyone',
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: recipientType == 'everyone'
                                      ? Colors.blue.shade700
                                      : Theme.of(context).cardTheme.surfaceTintColor!,
                                  width: recipientType == 'everyone' ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: recipientType == 'everyone'
                                    ? Colors.blue.shade50
                                    : Theme.of(context).cardTheme.surfaceTintColor!,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.group,
                                    color: recipientType == 'everyone'
                                        ? Colors.blue.shade700
                                        : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'All Farmers',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: recipientType == 'everyone'
                                                ? Colors.blue.shade700
                                                : Colors.black,
                                          ),
                                        ),
                                        Text(
                                          'Send to all registered farmers',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Radio<String>(
                                    value: 'everyone',
                                    groupValue: recipientType,
                                    onChanged: (value) {
                                      if (value != null) {
                                        recipientTypeNotifier.value = value;
                                      }
                                    },
                                    activeColor: Colors.blue.shade700,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () => recipientTypeNotifier.value = 'specific',
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: recipientType == 'specific'
                                      ? Colors.blue.shade700
                                      : Theme.of(context).cardTheme.surfaceTintColor!  , 
                                  width: recipientType == 'specific' ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: recipientType == 'specific'
                                    ? Colors.blue.shade50 
                                    : Theme.of(context).cardTheme.color,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    color: recipientType == 'specific'
                                        ? Colors.blue.shade700
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Specific Farmer',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: recipientType == 'specific'
                                                ? Colors.blue.shade700
                                                : null,
                                          ),
                                        ),
                                        Text(
                                          'Send to a selected farmer',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Radio<String>(
                                    value: 'specific',
                                    groupValue: recipientType,
                                    onChanged: (value) {
                                      if (value != null) {
                                        recipientTypeNotifier.value = value;
                                      }
                                    },
                                    activeColor: Colors.blue.shade700,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),


_buildFarmerSelectionDropdown(),
                  // // Farmer Selection (conditional)
                  // ValueListenableBuilder<String>(
                  //   valueListenable: recipientTypeNotifier,
                  //   builder: (context, recipientType, child) {
                  //     if (recipientType != 'specific') return const SizedBox.shrink();
                      
                  //     return Column(
                  //       crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: [
                  //         const SizedBox(height: 20),
                  //         const Text(
                  //           'Select Farmer',
                  //           style: TextStyle(
                  //             fontSize: 15,
                  //             fontWeight: FontWeight.w600,
                  //           ),
                  //         ),
                  //         const SizedBox(height: 12),
                  //         ValueListenableBuilder<String?>(
                  //           valueListenable: selectedFarmerNotifier,
                  //           builder: (context, selectedFarmer, child) {
                  //             return Container(
                  //               decoration: BoxDecoration(
                  //                 border: Border.all(color: Colors.grey.shade300),
                  //                 borderRadius: BorderRadius.circular(8),
                  //               ),
                  //               child: DropdownButtonHideUnderline(
                  //                 child: DropdownButton<String>(
                  //                   value: selectedFarmer,
                  //                   isExpanded: true,
                  //                   hint: const Padding(
                  //                     padding: EdgeInsets.symmetric(horizontal: 16),
                  //                     child: Text('Choose a farmer'),
                  //                   ),
                  //                   padding: const EdgeInsets.symmetric(horizontal: 16),
                  //                   items: farmers.map((farmer) {
                  //                     return DropdownMenuItem<String>(
                  //                       value: farmer.id.toString(),
                  //                       child: Column(
                  //                         crossAxisAlignment: CrossAxisAlignment.start,
                  //                         mainAxisSize: MainAxisSize.min,
                  //                         children: [
                  //                           Text(
                  //                             farmer.name,
                  //                             style: const TextStyle(
                  //                               fontSize: 14,
                  //                               fontWeight: FontWeight.w500,
                  //                             ),
                  //                           ),
                  //                           Text(
                  //                             farmer.email!,
                  //                             style: TextStyle(
                  //                               fontSize: 12,
                  //                               color: Colors.grey.shade600,
                  //                             ),
                  //                           ),
                  //                         ],
                  //                       ),
                  //                     );
                  //                   }).toList(),
                  //                   onChanged: (value) {
                  //                     selectedFarmerNotifier.value = value;
                  //                   },
                  //                 ),
                  //               ),
                  //             );
                  //           },
                  //         ),
                  //       ],
                  //     );
                  //   },
                  // ),

                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    'Title',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color:Theme.of(context).cardTheme.surfaceTintColor!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        hintText: 'Enter announcement title',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Message
                  const Text(
                    'Message',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color:Theme.of(context).cardTheme.surfaceTintColor!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: messageController,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        hintText: 'Type your announcement message here...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Send Button
                  ValueListenableBuilder<bool>(
                    valueListenable: isSendingNotifier,
                    builder: (context, isSending, child) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSending ? null : onSendAnnouncement,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isSending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.send, size: 18  , color: Colors.white,),
                                    SizedBox(width: 8),
                                    Text(
                                      'Send Announcement',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                  
                  // Info text
                  ValueListenableBuilder<String>(
                    valueListenable: recipientTypeNotifier,
                    builder: (context, recipientType, child) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                recipientType == 'everyone' 
                                    ? 'This announcement will be sent to all registered farmers.' 
                                    : 'This announcement will be sent to the selected farmer only.', 
                                style: TextStyle(
                                  fontSize: 13, 
                                  color: Colors.blue.shade900
                                )
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }





Widget _buildFarmerSelectionDropdown() {
  return ValueListenableBuilder<String>(
    valueListenable: recipientTypeNotifier,
    builder: (context, recipientType, child) {
      if (recipientType != 'specific') return const SizedBox.shrink();
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Select Farmer',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<String?>(
            valueListenable: selectedFarmerNotifier,
            builder: (context, selectedFarmer, child) {
              return Autocomplete<Farmer>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return farmers;
                  }
                  return farmers.where((Farmer farmer) {
                    return farmer.name
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase()) ||
                        (farmer.email ?? '')
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (Farmer selection) {
                  selectedFarmerNotifier.value = selection.id.toString();
                },
                displayStringForOption: (Farmer farmer) => farmer.name,
                fieldViewBuilder: (BuildContext context,
                    TextEditingController textEditingController,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted) {
                  // Set initial value if a farmer is already selected
                  if (selectedFarmer != null && textEditingController.text.isEmpty) {
                    final selected = farmers.firstWhere(
                      (farmer) => farmer.id.toString() == selectedFarmer,
                      orElse: () => Farmer(id: -1, name: '', email: '' , sector: ''),
                    );
                    if (selected.id != -1) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        textEditingController.text = selected.name;
                      });
                    }
                  }

                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color:Theme.of(context).cardTheme.surfaceTintColor!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Theme.of(context).cardTheme.surfaceTintColor!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.blue, width: 1),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      hintText: 'Type to search farmers...',
                      hintStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      suffixIcon: selectedFarmer != null
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                selectedFarmerNotifier.value = null;
                                textEditingController.clear();
                              },
                            )
                          : null,
                    ),
                  );
                },
                optionsViewBuilder: (BuildContext context,
                    AutocompleteOnSelected<Farmer> onSelected,
                    Iterable<Farmer> options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: MediaQuery.of(context).size.width - 64,
                        constraints: const BoxConstraints(maxWidth: 770),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final Farmer farmer = options.elementAt(index);
                              return InkWell(
                                onTap: () {
                                  onSelected(farmer);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    border: index < options.length - 1
                                        ? Border(
                                            bottom: BorderSide(
                                              color:Theme.of(context).cardTheme.surfaceTintColor!,
                                            ),
                                          )
                                        : null,
                                    color: Colors.white,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        farmer.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (farmer.email != null && farmer.email!.isNotEmpty)
                                        Text(
                                          farmer.email!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      );
    },
  );
}


}