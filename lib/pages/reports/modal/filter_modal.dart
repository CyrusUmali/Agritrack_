import 'package:flareline_uikit/components/modal/modal_dialog.dart';
import 'package:flutter/material.dart';

void showDesktopModal({
  required BuildContext context,
  required String title,
  required List<String> items,
  required Set<String> selectedItems,
  required ValueChanged<Set<String>> onSelected,
  bool multiple = false,
}) {
  final searchController = TextEditingController();
  final filteredItems = ValueNotifier<List<String>>(items);
  final focusNode = FocusNode();
  final tempSelection = ValueNotifier<Set<String>>(Set.from(selectedItems));

  void filterItems(String query) {
    if (query.isEmpty) {
      filteredItems.value = items;
    } else {
      filteredItems.value = items
          .where((item) => item.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  ModalDialog.show(
    context: context,
    title: title,
    showTitle: true,
    showTitleDivider: true,
    modalType: ModalType.medium,
    onCancelTap: () => Navigator.of(context).pop(),
    onSaveTap: () {
      onSelected(tempSelection.value);
      Navigator.of(context).pop();
    },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search input
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: SearchBar(
            controller: searchController,
            focusNode: focusNode,
            hintText: 'Search...',
            leading: const Icon(Icons.search),
            trailing: [
              if (searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    searchController.clear();
                    filterItems('');
                    focusNode.unfocus();
                  },
                ),
            ],
            onChanged: filterItems,
            elevation: MaterialStateProperty.all(1.0),
            shape: MaterialStateProperty.all(const ContinuousRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            )),
          ),
        ),
        // Selection controls
        Row(
          children: [
            TextButton(
              onPressed: () {
                tempSelection.value = Set.from(filteredItems.value);
              },
              child: const Text('Select all'),
            ),
            if (selectedItems.isNotEmpty) ...[
              const SizedBox(width: 16),
              TextButton(
                onPressed: () {
                  tempSelection.value = Set();
                },
                child: const Text('Clear all'),
              ),
            ],
          ],
        ),
        // Items list
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: ValueListenableBuilder<List<String>>(
            valueListenable: filteredItems,
            builder: (context, filteredList, _) {
              return ListView.builder(
                shrinkWrap: true,
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final item = filteredList[index];
                  return ValueListenableBuilder<Set<String>>(
                    valueListenable: tempSelection,
                    builder: (context, selection, _) {
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            final newSelection = Set<String>.from(selection);
                            if (newSelection.contains(item)) {
                              newSelection.remove(item);
                            } else {
                              newSelection.add(item);
                            }
                            tempSelection.value = newSelection;
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: selection.contains(item),
                                  onChanged: (value) {
                                    final newSelection =
                                        Set<String>.from(selection);
                                    if (value == true) {
                                      newSelection.add(item);
                                    } else {
                                      newSelection.remove(item);
                                    }
                                    tempSelection.value = newSelection;
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                                Text(
                                  item,
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
              width: 120,
              child: FilledButton.tonal(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 20),
            SizedBox(
              width: 120,
              child: FilledButton(
                onPressed: () {
                  onSelected(tempSelection.value);
                  Navigator.of(context).pop();
                },
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void showMobileModal({
  required BuildContext context,
  required String title,
  required List<String> items,
  required Set<String> selectedItems,
  required ValueChanged<Set<String>> onSelected,
  bool multiple = false,
}) {
  final searchController = TextEditingController();
  final filteredItems = ValueNotifier<List<String>>(items);
  final focusNode = FocusNode();
  final tempSelection = ValueNotifier<Set<String>>(Set.from(selectedItems));

  void filterItems(String query) {
    if (query.isEmpty) {
      filteredItems.value = items;
    } else {
      filteredItems.value = items
          .where((item) => item.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Search input
            SearchBar(
              controller: searchController,
              focusNode: focusNode,
              hintText: 'Search...',
              leading: const Icon(Icons.search),
              trailing: [
                if (searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      searchController.clear();
                      filterItems('');
                      focusNode.unfocus();
                    },
                  ),
              ],
              onChanged: filterItems,
              elevation: MaterialStateProperty.all(1.0),
              shape: MaterialStateProperty.all(
                const ContinuousRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Selection controls
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    tempSelection.value = Set.from(filteredItems.value);
                  },
                  child: const Text('Select all'),
                ),
                if (selectedItems.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () {
                      tempSelection.value = Set();
                    },
                    child: const Text('Clear all'),
                  ),
                ],
              ],
            ),
            // Items list
            Expanded(
              child: ValueListenableBuilder<List<String>>(
                valueListenable: filteredItems,
                builder: (context, filteredList, _) {
                  return ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return ValueListenableBuilder<Set<String>>(
                        valueListenable: tempSelection,
                        builder: (context, selection, _) {
                          return ListTile(
                            title: Text(item),
                            leading: Checkbox(
                              value: selection.contains(item),
                              onChanged: (value) {
                                final newSelection =
                                    Set<String>.from(selection);
                                if (value == true) {
                                  newSelection.add(item);
                                } else {
                                  newSelection.remove(item);
                                }
                                tempSelection.value = newSelection;
                              },
                            ),
                            onTap: () {
                              final newSelection = Set<String>.from(selection);
                              if (newSelection.contains(item)) {
                                newSelection.remove(item);
                              } else {
                                newSelection.add(item);
                              }
                              tempSelection.value = newSelection;
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            // Action buttons
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CANCEL'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      onSelected(tempSelection.value);
                      Navigator.pop(context);
                    },
                    child: const Text('APPLY'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
