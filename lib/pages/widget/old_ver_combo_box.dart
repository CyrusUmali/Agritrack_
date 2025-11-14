import 'package:flutter/material.dart';

Widget buildComboBox({
  required BuildContext context,
  required String hint,
  required List<String> options,
  required String selectedValue,
  required ValueChanged<String> onSelected,
  double? width,
  double? height,
  String? Function(String?)? validator,
  Color? color,
}) {
  return SizedBox(
    height: height ?? 48, // Use provided height or default to 48
    width: width,
    child: Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              Theme.of(context).cardTheme.surfaceTintColor ?? Colors.grey[300]!,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Tooltip(
            message: hint,
            child: Autocomplete<String>(
              fieldViewBuilder: (context, textEditingController, focusNode,
                  onFieldSubmitted) {
                if (selectedValue.isNotEmpty) {
                  textEditingController.text = selectedValue;
                }

                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  readOnly:
                      true, // Make field read-only to show dropdown on tap
                  onTap: () {
                    // Show options when field is tapped
                    focusNode.requestFocus();
                  },
                  decoration: InputDecoration(
                    hintText: hint,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: (height ?? 48) / 2 -
                          12, // Adjust padding based on height
                    ),
                    suffixIconConstraints: const BoxConstraints(
                      minHeight: 24,
                      minWidth: 24,
                    ),
                    suffixIcon: IconButton(
                      icon: selectedValue.isNotEmpty
                          ? Icon( 
                              Icons.close,
                              size: 20,
                              color: Theme.of(context).iconTheme.color,
                            )
                          : Icon(
                              Icons.arrow_drop_down,
                              size: 24,
                              color: Theme.of(context).iconTheme.color,
                            ),
                      onPressed: () {
                        if (selectedValue.isNotEmpty) {
                          textEditingController.clear();
                          onSelected('');
                          focusNode.unfocus();
                        } else {
                          // Show dropdown options when arrow is clicked
                          focusNode.requestFocus();
                        }
                      },
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                );
              },
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return options;
                }
                return options.where((option) => option
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: onSelected,
              optionsViewBuilder: (context, onSelected, options) {
                const itemHeight = 48.0;
                const maxItemsToShow = 5;
                final maxHeight = itemHeight * maxItemsToShow;
                final actualHeight = options.length * itemHeight;

                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    color: Theme.of(context).cardTheme.color,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: Theme.of(context).cardTheme.surfaceTintColor ??
                            Colors.grey[300]!,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: width ?? MediaQuery.of(context).size.width,
                        maxHeight:
                            actualHeight > maxHeight ? maxHeight : actualHeight,
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          final isSelected = option == selectedValue;

                          return SizedBox(
                            height: itemHeight,
                            child: InkWell(
                              onTap: () => onSelected(option),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        option,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}
