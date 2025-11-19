import 'dart:ui';
import 'package:flareline/pages/recommendation/recommendation_page.dart';
import 'package:flareline/services/lanugage_extension.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flutter/material.dart';
import 'package:flareline/pages/recommendation/suitability/suitability_page.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:provider/provider.dart';
import 'chatbot_model.dart';
import 'package:flareline/providers/language_provider.dart';
import 'package:flutter/services.dart';


class ChatbotWidget extends StatefulWidget {
  const ChatbotWidget({super.key});

  @override
  ChatbotContentState createState() => ChatbotContentState();
}

class ChatbotContentState extends State<ChatbotWidget> {
  final GlobalKey _navigationMenuKey = GlobalKey();
  late ChatbotModel _chatbotModel;
  String _selectedModel = 'Gemini';
  bool _conversationStarted = false;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final List<String> _availableModels = ['Gemini', 'GPT-4', 'Claude', 'Llama'];

  // Quick options with shorter, more Reddit-like text
  List<Map<String, dynamic>> _getQuickOptions(BuildContext context) {
    return [
      {
        'icon': Icons.eco,
        'titleKey': 'Soil Health',
        'messageKey': 'Tell me about soil health and pH levels',
      },
      {
        'icon': Icons.agriculture,
        'titleKey': 'Crop Selection',
        'messageKey': 'What crops should I grow in my region?',
      },
      {
        'icon': Icons.bug_report,
        'titleKey': 'Pest Control',
        'messageKey': 'How do I control pests organically?',
      },
      {
        'icon': Icons.water_drop,
        'titleKey': 'Irrigation Tips',
        'messageKey': 'What are the best irrigation practices?',
      },
      {
        'icon': Icons.scatter_plot,
        'titleKey': 'Fertilizers',
        'messageKey': 'Which fertilizers should I use for my crops?',
      },
      {
        'icon': Icons.calendar_today,
        'titleKey': 'Planting Season',
        'messageKey': 'When is the best time to plant crops?',
      },
      {
        'icon': Icons.healing,
        'titleKey': 'Plant Disease',
        'messageKey': 'How do I identify and treat plant diseases?',
      },
      {
        'icon': Icons.wb_sunny,
        'titleKey': 'Weather Impact',
        'messageKey': 'How does weather affect crop growth?',
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    _chatbotModel = ChatbotModel(languageProvider: languageProvider);
    _chatbotModel.addListener(_onChatbotModelChanged);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _chatbotModel.removeListener(_onChatbotModelChanged);
    super.dispose();
  }

  void _onChatbotModelChanged() {
    if (_chatbotModel.messages.length > 1 && !_conversationStarted) {
      setState(() {
        _conversationStarted = true;
      });
    }
  }

  void _handleSendPressed() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _chatbotModel.addUserMessage(text);
    _chatbotModel.getBotResponse(text, useStreaming: _chatbotModel.useStreaming);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final bool isTablet = MediaQuery.of(context).size.width < 900;
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ChangeNotifierProvider.value(
      value: _chatbotModel,
      child: SingleChildScrollView(
        child: Container(
          height: screenHeight - 100,
          padding: EdgeInsets.all(isMobile ? 0.0 : 16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isMobile ? double.infinity : 1200,
                minHeight: screenHeight - 132,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_conversationStarted)
                    _buildResponsiveHeader(isMobile, isTablet, isDarkMode),
                  if (!_conversationStarted) const SizedBox(height: 16),
                  Expanded(
                    child: _buildChatInterfaceCard(isMobile, isDarkMode),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalScrollSuggestions(
      List<String> suggestions, bool isDarkMode) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          scrollbars: true,
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.stylus,
            PointerDeviceKind.trackpad,
          },
        ),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: suggestions.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            return _buildSuggestionChip(suggestions[index], isDarkMode);
          },
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String suggestion, bool isDarkMode) {
    return InkWell(
      onTap: () => _handleSuggestionTap(suggestion),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color:
              isDarkMode ? Theme.of(context).cardTheme.color : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 16,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              suggestion,
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSuggestionTap(String suggestion) {
    _chatbotModel.addUserMessage(suggestion);
    _chatbotModel.getBotResponse(suggestion,
        useStreaming: _chatbotModel.useStreaming);
  }

  // Reddit-style quick option pill button (smaller and animated)
  Widget _buildRedditStylePill(Map<String, dynamic> option, bool isDarkMode) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: InkWell(
        onTap: () => _handleQuickOption(context.translate(option['messageKey'])),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDarkMode 
                ? Colors.grey[850]
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                option['icon'],
                size: 14,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
              ),
              const SizedBox(width: 6),
              Text(
                context.translate(option['titleKey']),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleQuickOption(String message) {
    _chatbotModel.addUserMessage(message);
    _chatbotModel.getBotResponse(message, useStreaming: _chatbotModel.useStreaming);
  }

  Widget _buildResponsiveHeader(bool isMobile, bool isTablet, bool isDarkMode) {
    if (!isMobile && !isTablet) {
      return Consumer<ChatbotModel>(
        builder: (context, model, child) {
          return Container(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 80,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          context.translate('Agriculture Assistant'),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 32,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return Consumer<ChatbotModel>(
      builder: (context, model, child) {
        return Container(
          height: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.translate('Agriculture Assistant'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: isMobile ? 24 : 28,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              if (_conversationStarted) const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDynamicSuggestions(bool isMobile, bool isDarkMode) {
    return Consumer<ChatbotModel>(
      builder: (context, model, child) {
        final suggestions = model.latestSuggestions;

        if (suggestions.isEmpty) {
          return const SizedBox.shrink();
        }

        return _buildHorizontalScrollSuggestions(suggestions, isDarkMode);
      },
    );
  }




Widget _buildCustomInput(bool isMobile, bool isDarkMode) {
  return Consumer<ChatbotModel>(
    builder: (context, model, child) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_conversationStarted && !model.isTyping)
            _buildDynamicSuggestions(isMobile, isDarkMode),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDarkMode ? Theme.of(context).cardTheme.color! : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(24),
            ),
            child: RawKeyboardListener(
              focusNode: FocusNode(),
              onKey: (RawKeyEvent event) {
                if (event is RawKeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.enter && 
                      !event.isShiftPressed) {
                    // Prevent default behavior
                    if (_textController.text.trim().isNotEmpty) {
                      _handleSendPressed();
                    }
                  }
                }
              },
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: context.translate('Type here...'),
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _handleSendPressed,
                    icon: Icon(
                      Icons.send,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey,
                      size: 22,
                    ),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}


  // Reddit-style empty state with flowing pill buttons (animated)
  Widget _buildQuickTopicsEmptyState(bool isMobile, bool isDarkMode) {
    final quickOptions = _getQuickOptions(context);
    
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Welcome message
            Text(
              context.translate('How can I help you today?'),
              style: TextStyle(
                fontSize: isMobile ? 18 : 22,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.grey[200] : Colors.grey[900],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Reddit-style flowing pill buttons with staggered animation
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: List.generate(quickOptions.length, (index) {
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 400 + (index * 50)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: _buildRedditStylePill(quickOptions[index], isDarkMode),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInterfaceCard(bool isMobile, bool isDarkMode) {
    return Consumer<ChatbotModel>(
      builder: (context, model, child) {
        return Card(
          color: isDarkMode ? FlarelineColors.darkerBackground : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: model.messages.length <= 1
                      ? _buildQuickTopicsEmptyState(isMobile, isDarkMode)
                      : Chat(
                          messages: model.messages,
                          onSendPressed: (p) {},
                          user: model.user,
                          showUserAvatars: true,
                          showUserNames: true,
                          usePreviewData: false,
                          customBottomWidget: _buildCustomInput(isMobile, isDarkMode),
                          theme: DefaultChatTheme(
                            backgroundColor: isDarkMode ? FlarelineColors.darkerBackground : Colors.white,
                            primaryColor: isDarkMode ? Theme.of(context).cardTheme.color! : Colors.grey.shade200,
                            secondaryColor: isDarkMode ? Theme.of(context).cardTheme.color! : Colors.grey.shade200,
                            inputBackgroundColor: isDarkMode ? Theme.of(context).cardTheme.color! : Colors.grey.shade200,
                            inputTextColor: isDarkMode ? Colors.white : Colors.black87,
                            inputBorderRadius: BorderRadius.circular(24),
                            inputMargin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            userAvatarNameColors: [isDarkMode ? Colors.grey[300]! : Colors.black],
                            receivedMessageBodyTextStyle: TextStyle(
                              color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                              fontSize: isMobile ? 14 : 16,
                              height: 1.4,
                            ),
                            sentMessageBodyTextStyle: TextStyle(
                              color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                              fontSize: 14,
                              height: 1.4,
                            ),
                            receivedMessageBodyLinkTextStyle: TextStyle(
                              color: isDarkMode ? Colors.blue[200]! : Colors.blue,
                              fontSize: isMobile ? 14 : 16,
                              height: 1.4,
                            ),
                            sendButtonIcon: Icon(
                              Icons.send,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey,
                              size: 22,
                            ),
                          ),
                          typingIndicatorOptions: TypingIndicatorOptions(
                            typingUsers: model.isTyping ? [model.bot] : [],
                          ),
                          avatarBuilder: (userId) {
                            final bool isBot = userId == model.bot.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: CircleAvatar(
                                backgroundColor: isBot
                                    ? (isDarkMode ? Theme.of(context).cardTheme.color! : Colors.grey.shade200)
                                    : (isDarkMode ? Theme.of(context).cardTheme.color! : Colors.grey[200]!),
                                child: isBot 
                                    ? Icon(
                                        Icons.person,
                                        color: isDarkMode ? Colors.grey.shade200 : Colors.grey.shade800,
                                        size: 20,
                                      )
                                    : ClipOval(
                                        child: Image.asset(
                                          'assets/DA_image.jpg',
                                          width: 36,
                                          height: 36,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                radius: 18,
                              ),
                            );
                          },
                        ),
                ),
                if (model.messages.length <= 1)
                  _buildCustomInput(isMobile, isDarkMode),
              ],
            ),
          ),
        );
      },
    );
  }
}