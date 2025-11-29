// Updated chatbot_model.dart with debugging
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ChatbotModel extends ChangeNotifier {
  final List<types.Message> _messages = [];
  final _user = const types.User(id: 'user', firstName: 'User');
  final _bot = const types.User(id: 'bot', firstName: 'AgriBot');
  bool _isTyping = false;
  String _currentStreamingMessageId = '';
  String _currentStreamingText = '';
  List<String> _latestSuggestions = [];
  
  // Update this to your actual backend URL
  // static const String backendUrl = 'http://localhost:3001/auth';

    static const String backendUrl = 'https://agritrack-server.onrender.com/auth';
   

  List<types.Message> get messages => _messages;
  bool get isTyping => _isTyping;
  types.User get user => _user;
  types.User get bot => _bot;
  List<String> get latestSuggestions => _latestSuggestions;

  ChatbotModel() {
  
    _initializeChat();
  }

  Future<String?> _getAuthToken() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final token = await currentUser.getIdToken();
         
        return token;
      } 
      return null;
    } catch (e) { 
      return null;
    }
  }

  Future<void> _initializeChat() async {
    try {
    
      final token = await _getAuthToken();
      
      if (token == null) {
        
        _addErrorMessage('Hindi nakuha ang authentication. Pakisubukan muli.');
        return;
      }

   
      
      final response = await http.post(
        Uri.parse('$backendUrl/chatbot/init'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timeout');
        },
      );

  
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final welcomeMessage = types.TextMessage(
          author: _bot,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: const Uuid().v4(),
          text: data['welcomeMessage'] ?? 'Kumusta!',
        );
        
        _messages.insert(0, welcomeMessage);
        _latestSuggestions = List<String>.from(data['suggestions'] ?? []);
       notifyListeners();
      } else {
      _addErrorMessage('Hindi ma-initialize ang chat. Status: ${response.statusCode}');
      }
    } catch (e) { 
      _addErrorMessage('May problema sa koneksyon. Error: $e');
    }
  }

  void clearChat() async {
    try {
     final token = await _getAuthToken();
      if (token == null) {
     return;
      }

      _messages.clear();
      _isTyping = false;
      _currentStreamingMessageId = '';
      _currentStreamingText = '';
      _latestSuggestions = [];
      notifyListeners();

      final response = await http.post(
        Uri.parse('$backendUrl/chatbot/clear'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

 
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final welcomeMessage = types.TextMessage(
          author: _bot,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: const Uuid().v4(),
          text: data['welcomeMessage'] ?? 'Kumusta!',
        );
        
        _messages.insert(0, welcomeMessage);
        _latestSuggestions = List<String>.from(data['suggestions'] ?? []);
      notifyListeners();
      }
    } catch (e) {
    _addErrorMessage('Hindi ma-clear ang chat. Pakisubukan muli.');
    }
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
    _latestSuggestions = [];
    notifyListeners();
  }

  Future<void> getBotResponse(String userMessage) async {
    try {
     
      final token = await _getAuthToken();
      if (token == null) { 
        _addErrorMessage('Hindi nakuha ang authentication. Pakisubukan muli.');
        return;
      }

      _currentStreamingMessageId = const Uuid().v4();
      _currentStreamingText = '';

      // Add empty message for streaming
      final initialMessage = types.TextMessage(
        author: _bot,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: _currentStreamingMessageId,
        text: '',
      );
      _messages.insert(0, initialMessage);
      notifyListeners();

 
      final request = http.Request(
        'POST',
        Uri.parse('$backendUrl/chatbot/message'),
      );
      
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
      });
      
      request.body = json.encode({'message': userMessage});

     final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timeout');
        },
      );

    
      if (streamedResponse.statusCode == 200) {
      int chunkCount = 0;
        
        await for (var chunk in streamedResponse.stream.transform(utf8.decoder)) {
          chunkCount++;
        
          final lines = chunk.split('\n');
          
          for (var line in lines) {
            if (line.startsWith('data: ')) {
              final jsonData = line.substring(6);
              try {
                final data = json.decode(jsonData);
          
                if (data['error'] == true) {
              _handleError(data['message'] ?? 'May nangyaring error');
                  break;
                }
                
                if (data['done'] == true) {
              _finishStreaming(
                    data['fullResponse'] ?? _currentStreamingText,
                    List<String>.from(data['suggestions'] ?? []),
                  );
                } else if (data['chunk'] != null) {
                  _currentStreamingText += data['chunk'];
                  _updateStreamingMessage(_currentStreamingText);
                }
              } catch (e) {
         }
            }
          }
        }
        
     } else { 
        final responseBody = await streamedResponse.stream.bytesToString(); 
        _handleError('May problema sa pagkonekta sa server (${streamedResponse.statusCode})');
      }
    } catch (e, stackTrace) { 
      _handleError('May problema sa koneksyon. Error: $e');
    }
  }

  void _updateStreamingMessage(String text) {
    final messageIndex = _messages.indexWhere(
      (msg) => msg.id == _currentStreamingMessageId,
    );

    if (messageIndex != -1) {
      String displayText = text;
      if (text.contains('[FOLLOW_UP_QUESTIONS]')) {
        displayText = text.substring(0, text.indexOf('[FOLLOW_UP_QUESTIONS]')).trim();
      }

      final updatedMessage = types.TextMessage(
        author: _bot,
        createdAt: _messages[messageIndex].createdAt,
        id: _currentStreamingMessageId,
        text: displayText,
      );

      _messages[messageIndex] = updatedMessage;
      notifyListeners();
    }
  }

  void _finishStreaming(String finalText, List<String> suggestions) { 
    
    final messageIndex = _messages.indexWhere(
      (msg) => msg.id == _currentStreamingMessageId,
    );

    if (messageIndex != -1) {
      final updatedMessage = types.TextMessage(
        author: _bot,
        createdAt: _messages[messageIndex].createdAt,
        id: _currentStreamingMessageId,
        text: finalText,
      );

      _messages[messageIndex] = updatedMessage;
    }

    _latestSuggestions = suggestions;
    _isTyping = false;
    _currentStreamingMessageId = '';
    _currentStreamingText = '';
    notifyListeners();
  }

  void _handleError(String errorMessage) { 
    _isTyping = false;

    if (_currentStreamingMessageId.isNotEmpty) {
      _messages.removeWhere((msg) => msg.id == _currentStreamingMessageId);
    }

    final errorMsg = types.TextMessage(
      author: _bot,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: errorMessage,
    );

    _messages.insert(0, errorMsg);
    _latestSuggestions = [
      'Subukan muli kapag may koneksyon',
      'Suriin ang aking koneksyon',
    ];

    _currentStreamingMessageId = '';
    _currentStreamingText = '';
    notifyListeners();
  }

  void _addErrorMessage(String message) {
 
    final errorMessage = types.TextMessage(
      author: _bot,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message,
    );

    _messages.insert(0, errorMessage);
    notifyListeners();
  }

  void handleSendPressed(types.PartialText message) {
    addUserMessage(message.text);
    getBotResponse(message.text);
  }
}