import 'package:flutter/material.dart';

class SegmentedFilter extends StatelessWidget {
  final String label;
  final Map<String, String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  final EdgeInsetsGeometry padding;

  const SegmentedFilter({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 0.0),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            // Calculate equal width for each segment based on available space
            final segmentWidth = constraints.maxWidth / options.length;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: Padding(
                  padding: padding,
                  child: SegmentedButton<String>(
                    segments: options.entries
                        .map(
                          (e) => ButtonSegment(
                            value: e.key,
                            label: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                e.value,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    selected: {selected},
                    onSelectionChanged: (Set<String> newSelection) {
                      onChanged(newSelection.first);
                    },
                    style: ButtonStyle(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      fixedSize: MaterialStateProperty.all(
                        Size(segmentWidth, 36),
                      ),
                      padding: MaterialStateProperty.all<EdgeInsets>(
                        EdgeInsets.zero,
                      ),
                      // Add border to the buttons
                      side: MaterialStateProperty.resolveWith<BorderSide>(
                        (Set<MaterialState> states) {
                          // You can customize the border color based on states
                          if (states.contains(MaterialState.selected)) {
                            return const BorderSide(
                              color: Colors.blue, // Selected border color
                              width: 1.0,
                            );
                          }
                          return BorderSide(
                            color:
                                Theme.of(context).cardTheme.surfaceTintColor ??
                                    Colors.grey[300]!,
                            width: 1.0,
                          );
                        },
                      ),
                    ),
                    showSelectedIcon: false,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
