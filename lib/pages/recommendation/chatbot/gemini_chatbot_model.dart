import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiChatbotModel extends ChangeNotifier {
  final List<types.Message> _messages = [];
  final _user = const types.User(id: 'user', firstName: 'User');
  final _bot = const types.User(id: 'bot', firstName: 'AgriBot');
  bool _isTyping = false;
  String _currentModel = 'Gemini';

  // Gemini API setup
  late GenerativeModel _model;
  late ChatSession _chatSession;

  // Streaming properties
  String _currentStreamingMessageId = '';
  String _currentStreamingText = '';
  StreamSubscription? _streamSubscription;

// Agriculture system prompt
  static const String _systemPrompt =
      '''You are AgriBot, an expert agricultural assistant specializing in:
- Crop selection and planning
- Soil health and testing
- Pest and disease management
- Water and irrigation systems
- Fertilizers and nutrient management
- Seasonal farming guides
- Weather and climate adaptation
- Harvesting and storage techniques
- Organic and sustainable farming practices
- **Livestock management** (cattle, poultry, goats, sheep, pigs)
- **Animal nutrition and feed management**
- **Livestock health and disease control**
- **Fishery and aquaculture systems**
- **Fish farming techniques**
- **Pond management and water quality**
- **Fish health and disease management**

Provide practical, actionable advice tailored to the user's specific needs. Always ask clarifying questions about their region, soil type, current conditions, and livestock/fishery setup when relevant. Keep responses concise but informative. Use emojis sparingly for emphasis.''';

  List<types.Message> get messages => _messages;
  bool get isTyping => _isTyping;
  types.User get user => _user;
  types.User get bot => _bot;
  String get currentModel => _currentModel;

  GeminiChatbotModel({required String geminiApiKey}) {
    _initializeGemini(geminiApiKey);
    // Don't call _addBotWelcomeMessage() here - wait for first access
  }

  void _initializeGemini(String apiKey) {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.text(_systemPrompt),
    );
    _chatSession = _model.startChat();
  }

  // Add this method to initialize the welcome message when needed
  void initializeWelcomeMessage() {
    if (_messages.isEmpty) {
      _addBotWelcomeMessage();
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  void clearChat() {
    _messages.clear();
    _isTyping = false;
    _streamSubscription?.cancel();
    _currentStreamingMessageId = '';
    _currentStreamingText = '';
    // Reinitialize chat session
    _chatSession = _model.startChat();
    _addBotWelcomeMessage();
  }

  void _addBotWelcomeMessage() {
    final welcomeMessage = types.TextMessage(
      author: _bot,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text:
          "Hello! I'm AgriBot, your agriculture expert powered by Gemini. How can I help you with your farming or gardening needs today?",
    );

    _messages.insert(0, welcomeMessage);
    notifyListeners();
  }

  void addUserMessage(String text) {
    final userMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: text,
    );

    _messages.insert(0, userMessage);
    _isTyping = true;
    notifyListeners();
  }

  // Get streaming response from Gemini
  Future<void> getBotResponse(String userMessage) async {
    try {
      _currentStreamingMessageId = const Uuid().v4();
      _currentStreamingText = '';

      // Create initial empty message for streaming
      final initialMessage = types.TextMessage(
        author: _bot,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: _currentStreamingMessageId,
        text: '',
      );

      _messages.insert(0, initialMessage);
      notifyListeners();

      // Send message to Gemini and get streaming response
      final stream = _chatSession.sendMessageStream(
        Content.text(userMessage),
      );

      _streamSubscription = stream.listen(
        (event) {
          final chunk = event.text ?? '';
          if (chunk.isNotEmpty) {
            _currentStreamingText += chunk;
            _updateStreamingMessage(_currentStreamingText);
          }
        },
        onError: _handleStreamError,
        onDone: _handleStreamDone,
      );
    } catch (e) {
      print('Error in getBotResponse: $e');
      _addErrorMessage('Failed to get response: $e');
    }
  }

  void _updateStreamingMessage(String text) {
    final messageIndex = _messages.indexWhere(
      (msg) => msg.id == _currentStreamingMessageId,
    );

    if (messageIndex != -1) {
      final updatedMessage = types.TextMessage(
        author: _bot,
        createdAt: _messages[messageIndex].createdAt,
        id: _currentStreamingMessageId,
        text: text,
      );

      _messages[messageIndex] = updatedMessage;
      notifyListeners();
    }
  }

  void _handleStreamError(error) {
    print('Stream error: $error');
    _isTyping = false;
    _addErrorMessage('Failed to get streaming response. Please try again.');
    notifyListeners();
  }

  void _handleStreamDone() {
    _isTyping = false;
    _currentStreamingMessageId = '';
    _currentStreamingText = '';
    notifyListeners();
  }

  void _addErrorMessage(String error) {
    final errorMessage = types.TextMessage(
      author: _bot,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: 'Sorry, I encountered an error: $error. Please try again later.',
    );

    _messages.insert(0, errorMessage);
    notifyListeners();
  }

  void handleSendPressed(types.PartialText message) {
    addUserMessage(message.text);
    getBotResponse(message.text);
  }
}
