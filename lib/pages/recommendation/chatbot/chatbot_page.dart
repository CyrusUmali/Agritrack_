import 'package:flareline/pages/recommendation/chatbot/chatbot_content.dart';
import 'package:flutter/material.dart';
import 'package:flareline/pages/layout.dart';

class ChatbotPage extends LayoutWidget {
  const ChatbotPage({super.key});

  @override
  String breakTabTitle(BuildContext context) {
    return '';
  }

  @override
  Widget contentDesktopWidget(BuildContext context) {
    return const ChatbotWidget();
  }

  @override
  Widget buildContent(BuildContext context) {
    return const ChatbotWidget();
  }

    @override
  EdgeInsetsGeometry? get customPadding => const EdgeInsets.only(top: 0);
}
