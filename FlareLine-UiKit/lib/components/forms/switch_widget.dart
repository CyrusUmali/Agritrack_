library flareline_uikit;

import 'package:flutter/material.dart';

// ignore: must_be_immutable
class SwitchWidget extends StatelessWidget {
  final bool? checked;
  final ValueChanged<bool>? onChanged;
  late ValueNotifier<bool> toggleNotifier;

  SwitchWidget({super.key, this.checked, this.onChanged}) {
    toggleNotifier = ValueNotifier(checked ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: toggleNotifier,
        builder: (ctx, checked, child) {
          return Switch(
              value: checked,
              activeColor: const Color(0xFF10B981),
              inactiveThumbColor: const Color(0xFF8A99AF),
              inactiveTrackColor: const Color(0xFFDEE4EE),
              onChanged: (r) {
                toggleNotifier.value = !toggleNotifier.value;
                onChanged?.call(r);
              });
        });
  }
}
