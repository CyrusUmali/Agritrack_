import 'package:flutter/material.dart';
import 'package:flareline/pages/layout.dart';
import 'suitability_content.dart';

class SuitabilityPage extends LayoutWidget {
  const SuitabilityPage({super.key});

  @override
  String breakTabTitle(BuildContext context) {
    return '';
  }

  @override
  Widget contentDesktopWidget(BuildContext context) {
    return const SuitabilityContent();
  }

  @override
  Widget buildContent(BuildContext context) {
    return const SuitabilityContent();
  }
}
