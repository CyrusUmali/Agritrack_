import 'package:flareline/pages/recommendation/chatbot/chatbot_content.dart';
import 'package:flutter/material.dart';
import 'package:flareline/pages/layout.dart';
import 'recommendation_content.dart';

class RecommendationPage extends LayoutWidget {
  const RecommendationPage({super.key});

  @override
  String breakTabTitle(BuildContext context) {
    return '';
  }

  @override
  Widget contentDesktopWidget(BuildContext context) {
    // return const ChatbotWidget();
    return const RecommendationContent();
  }

  @override
  Widget buildContent(BuildContext context) {
    return const RecommendationContent();
    // return const ChatbotWidget();
  }
}
