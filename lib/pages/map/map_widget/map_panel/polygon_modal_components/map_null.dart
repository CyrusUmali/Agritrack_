import 'package:flutter/material.dart';

class NullSafeDisplay extends StatelessWidget {
  final Widget child;
  final Widget placeholder;
  final dynamic value;

  const NullSafeDisplay({
    super.key,
    required this.child,
    required this.placeholder,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return value != null ? child : placeholder;
  }
}
