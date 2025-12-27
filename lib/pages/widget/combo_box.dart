import 'package:flutter/material.dart'; 

Widget buildComboBox({
  required BuildContext context,
  required String hint,
  required List<String> options,
  required String selectedValue,
  required ValueChanged<String> onSelected,
  double? width,
  double? height,
  Color? backgroundColor, 
  Color? borderColor,  
}) {
   
  String getDisplayText(String value) {
   
    final regex = RegExp(r'^\d+:\s*');
    return value.replaceFirst(regex, '');
  }

  final allOptions = [...options];
  
  final displayValue =
      selectedValue.isEmpty && options.isNotEmpty ? '' : selectedValue;

  return Container(
    decoration: BoxDecoration(
      color: backgroundColor ??
          Theme.of(context).cardTheme.color,  
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: borderColor ??  
            Theme.of(context).cardTheme.surfaceTintColor ??
            Colors.grey[300]!,
      ),
    ),
    child: SizedBox(
      height: height ?? 48,
      width: width,
      child: Autocomplete<String>(
        fieldViewBuilder:
            (context, textEditingController, focusNode, onFieldSubmitted) {
          bool isOptionsOpen = false;

          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final cleanedValue = getDisplayText(displayValue);
            if (textEditingController.text != cleanedValue) {
              textEditingController.text = cleanedValue;
            }
          });

          return StatefulBuilder(
            builder: (context, setState) {
              return ValueListenableBuilder<TextEditingValue>(
                valueListenable: textEditingController,
                builder: (context, value, _) {
                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    onTap: () {
                      setState(() {
                        isOptionsOpen = !isOptionsOpen;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: hint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: borderColor ??
                              Theme.of(context).cardTheme.surfaceTintColor ??
                              Colors.grey[300]!,
                        ),
                      ),
                      filled: backgroundColor != null,
                      fillColor: backgroundColor,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),

                   enabledBorder: OutlineInputBorder(
  borderRadius: BorderRadius.circular(8),
  borderSide: BorderSide(
    color: Colors.transparent,  
    width: 0,
  ),
),



                      suffixIcon: isOptionsOpen
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                focusNode.unfocus();
                                setState(() {
                                  isOptionsOpen = false;
                                });
                              },
                            )
                          : (value.text.isNotEmpty && value.text != 'All'
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    textEditingController.clear();
                                    onSelected('');
                                  },
                                )
                              : const Icon(Icons.arrow_drop_down, size: 24)),
                    ),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              );
            },
          );
        },
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return allOptions;
          }
         
          return allOptions.where((option) {
            final displayText = getDisplayText(option);
            return displayText
                .toLowerCase()
                .contains(textEditingValue.text.toLowerCase());
          }).toList();
        },
        onSelected: (String selection) {
         
          onSelected(selection == 'All' ? '' : selection);
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              color: backgroundColor ??
                  Theme.of(context)
                      .cardTheme
                      .color,  
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 200,
                ),
                child: SizedBox(
                  width: width == double.infinity ? 250 : (width ?? 200),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final option = options.elementAt(index);
                      final isSelected = option == 'All'
                          ? selectedValue.isEmpty
                          : option == selectedValue;

                      return ListTile(
                        title: Text(
                           
                          getDisplayText(option),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        minVerticalPadding: 12,
                        dense: true,
                        trailing: isSelected
                            ? const Icon(Icons.check, size: 16)
                            : null,
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}



