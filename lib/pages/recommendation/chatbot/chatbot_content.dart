// Updated chatbot_widget.dart
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
  bool _showQuickChat = true;
  bool _conversationStarted = false;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final List<String> _availableModels = ['Gemini', 'GPT-4', 'Claude', 'Llama'];

  // Quick options will now use translation keys
  List<Map<String, dynamic>> _getQuickOptions(BuildContext context) {
    return [
      {
        'icon': Icons.eco,
        'titleKey': 'Soil Health',
        'messageKey': 'Tell me about soil health and pH levels',
        'color': Colors.brown,
      },
      {
        'icon': Icons.agriculture,
        'titleKey': 'Crop Selection',
        'messageKey': 'What crops should I grow in my region?',
        'color': Colors.green,
      },
      {
        'icon': Icons.bug_report,
        'titleKey': 'Pest Control',
        'messageKey': 'How do I control pests organically?',
        'color': Colors.red,
      },
      {
        'icon': Icons.water_drop,
        'titleKey': 'Irrigation',
        'messageKey': 'What are the best irrigation practices?',
        'color': Colors.blue,
      },
      {
        'icon': Icons.scatter_plot,
        'titleKey': 'Fertilizers',
        'messageKey': 'Which fertilizers should I use for my crops?',
        'color': Colors.orange,
      },
      {
        'icon': Icons.calendar_today,
        'titleKey': 'Planting Season',
        'messageKey': 'When is the best time to plant crops?',
        'color': Colors.purple,
      },
      {
        'icon': Icons.healing,
        'titleKey': 'Plant Disease',
        'messageKey': 'How do I identify and treat plant diseases?',
        'color': Colors.teal,
      },
      {
        'icon': Icons.wb_sunny,
        'titleKey': 'Weather Impact',
        'messageKey': 'How does weather affect crop growth?',
        'color': Colors.amber,
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    // Initialize chatbot model with language provider
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
        _showQuickChat = false;
      });
    }
  }

  void hideQuickChat() {
    setState(() {
      _showQuickChat = false;
    });
  }

  void showQuickChat() {
    setState(() {
      _showQuickChat = true;
    });
  }

  void toggleQuickChat() {
    setState(() {
      _showQuickChat = !_showQuickChat;
    });
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
                  if (!_conversationStarted)
                    _buildQuickOptionsSection(isMobile, isDarkMode),
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
          // Enable scrolling with mouse drag on web
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

  Widget _buildQuickOptionsSection(bool isMobile, bool isDarkMode) {
    return Consumer<ChatbotModel>(
      builder: (context, model, child) {
        final quickOptions = _getQuickOptions(context);
        
        return Card(
          elevation: 2,
          color: isDarkMode ? FlarelineColors.darkerBackground : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.flash_on, color: Colors.amber[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          context.translate('Quick Topics'),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.grey[300] : Theme.of(context).cardTheme.color,
                              ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: AnimatedRotation(
                        turns: _showQuickChat ? 0 : 0.5,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.expand_less,
                          size: 24,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      onPressed: toggleQuickChat,
                      tooltip: _showQuickChat
                          ? context.translate('Hide Quick Topics')
                          : context.translate('Show Quick Topics'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _showQuickChat
                      ? Column(
                          children: [
                            const SizedBox(height: 12),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isMobile ? 2 : 4,
                                childAspectRatio: isMobile ? 2.5 : 4.0,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: quickOptions.length,
                              itemBuilder: (context, index) {
                                final option = quickOptions[index];
                                return _buildQuickOptionCard(option, isMobile, isDarkMode);
                              },
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickOptionCard(Map<String, dynamic> option, bool isMobile, bool isDarkMode) {
    return InkWell(
      onTap: () => _handleQuickOption(context.translate(option['messageKey'])),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 8 : 12),
        decoration: BoxDecoration(
          border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: isDarkMode ? Theme.of(context).cardTheme.color : Colors.grey[50],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              option['icon'],
              color: option['color'],
              size: isMobile ? 20 : 24,
            ),
            SizedBox(width: isMobile ? 4 : 6),
            Flexible(
              child: Text(
                context.translate(option['titleKey']),
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleQuickOption(String message) {
    _chatbotModel.addUserMessage(message);
    _chatbotModel.getBotResponse(message, useStreaming: _chatbotModel.useStreaming);
  }

  Widget _buildResponsiveHeader(bool isMobile, bool isTablet, bool isDarkMode) {
    void _showNavigationMenu() async { 
      final RenderBox? renderBox =
          _navigationMenuKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final Offset buttonPosition = renderBox.localToGlobal(Offset.zero);
      final Size buttonSize = renderBox.size;

      final result = await showMenu(
        context: context,
        position: RelativeRect.fromLTRB(
          buttonPosition.dx,
          buttonPosition.dy + buttonSize.height,
          buttonPosition.dx + 200,
          buttonPosition.dy + buttonSize.height + 100,
        ),
        color: Theme.of(context).cardTheme.color,
        items: [
          PopupMenuItem(
            value: 'back',
            child: ListTile(
              title: Text(context.translate('Crop Recommendations')),
            ),
          ),
          PopupMenuItem(
            value: 'suitability',
            child: ListTile(
              title: Text(context.translate('Crop Suitability')),
            ),
          ),
        ],
      );

      if (result == 'back') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const RecommendationPage(),
          ),
        );
      } else if (result == 'suitability') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SuitabilityPage()),
        );
      }
    }

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
          height: 90,
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
                      onSubmitted: (_) => _handleSendPressed(),
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
          ],
        );
      },
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
                Container(
                  height: 60,
                  child: Row(
                    children: [],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Chat(
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
                          child: Icon(
                            isBot ? Icons.agriculture : Icons.person,
                            color: isBot
                                ? (isDarkMode ? Colors.grey[400] : Colors.grey.shade800)
                                : (isDarkMode ? Colors.grey.shade200 : Colors.grey.shade800),
                            size: 20,
                          ),
                          radius: 18,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }



}