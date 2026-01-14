import 'dart:ui';
import 'dart:convert';
import 'dart:async';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flareline/pages/recommendation/chatbot/reset_button.dart';
import 'package:flareline/pages/yields/yield_bloc/yield_bloc.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'chatbot_model.dart';
import 'package:flutter/services.dart';

import 'dart:math' as math;
class ChatbotWidget extends StatefulWidget {
  const ChatbotWidget({super.key});

  @override
  ChatbotContentState createState() => ChatbotContentState();
}

class ChatbotContentState extends State<ChatbotWidget>
    with SingleTickerProviderStateMixin {
  late ChatbotModel _chatbotModel;
  late AnimationController _dotAnimationController;
  late Animation<double> _dotAnimation;
  bool _conversationStarted = false;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<dynamic>? _yieldData;
  bool _isLoadingYields = false;
  bool _hasLoadedYields = false;


   late FlutterTts _flutterTts;
  bool _isSpeaking = false;
  String? _currentSpeakingMessageId;
 bool _hasTagalogVoice = false;
  String? _selectedVoice;
  // Carousel auto-scroll variables
  late ScrollController _carouselScrollController;
  bool _isUserInteracting = false;
  double _scrollSpeed = 250.0; // pixels per second
  Timer? _autoScrollTimer;
  double _currentScrollOffset = 0.0;

  // Yield analysis prompt templates
  List<Map<String, dynamic>> _getYieldAnalysisPrompts() {
    return [
      {
        'icon': Icons.summarize,
        'title': 'Buod ng Ani',
        'message': 'Magbigay ng buod ng lahat ng yield records.',
        'color': Colors.blue,
        'requiredFields': ['volume', 'hectare', 'productName', 'harvestDate'],
      },
      {
        'icon': Icons.compare_arrows,
        'title': 'Paghahambing',
        'message':
            'Ikumpara ang mga yield ng iba\'t ibang produkto. Alin ang may pinakamataas na volume at hectare?',
        'color': Colors.green,
        'requiredFields': ['productName', 'volume', 'harvestDate', 'hectare'],
      },
      {
        'icon': Icons.calendar_today,
        'title': 'Bagong Ani',
        'message':
            'Ano ang mga pinakabagong harvest records at ano ang kanilang status?',
        'color': Colors.teal,
        'requiredFields': ['harvestDate', 'productName', 'volume', 'status'],
      },
      {
        'icon': Icons.analytics,
        'title': 'Halaga ng Ani',
        'message':
            'Mag-analyze ng economic value ng mga harvest. Alin ang most profitable na produkto?',
        'color': Colors.indigo,
        'requiredFields': ['productName', 'value', 'volume', 'hectare'],
      },
      {
        'icon': Icons.terrain,
        'title': 'Gamit ng Lupa',
        'message':
            'Paano ginagamit ang lupa? Mag-analyze ng hectare at area harvested data.',
        'color': Colors.brown,
        'requiredFields': [
          'farmName',
          'hectare',
          'areaHarvested',
          'productName',
          'volume'
        ],
      },
    ];
  }

  // General farming quick options
  List<Map<String, dynamic>> _getGeneralFarmingOptions() {
    return [
      {
        'icon': Icons.eco,
        'title': 'Kalusugan ng Lupa',
        'message':
            'Sabihin mo sa akin ang tungkol sa kalusugan ng lupa at mga antas ng pH',
        'color': Colors.green,
      },
      {
        'icon': Icons.agriculture,
        'title': 'Pagpili ng Pananim',
        'message': 'Anong mga pananim ang dapat kong itanim sa aking rehiyon?',
        'color': Colors.teal,
      },
      {
        'icon': Icons.bug_report,
        'title': 'Kontrol sa Peste',
        'message': 'Paano ko makokontrol ang mga peste nang organiko?',
        'color': Colors.red,
      },
      {
        'icon': Icons.water_drop,
        'title': 'Mga Tip sa Irigasyon',
        'message': 'Ano ang mga pinakamahusay na kasanayan sa irigasyon?',
        'color': Colors.blue,
      },
      {
        'icon': Icons.scatter_plot,
        'title': 'Pataba sa Pananim',
        'message':
            'Aling pataba ang dapat kong gamitin para sa aking mga pananim?',
        'color': Colors.orange,
      },
      {
        'icon': Icons.calendar_today,
        'title': 'Panahon ng Pagtatanim',
        'message':
            'Kailan ang pinakamagandang panahon upang magtanim ng mga pananim?',
        'color': Colors.purple,
      },
      {
        'icon': Icons.healing,
        'title': 'Sakit ng Halaman',
        'message': 'Paano ko matutukoy at magagamot ang mga sakit sa halaman?',
        'color': Colors.pink,
      },
      {
        'icon': Icons.wb_sunny,
        'title': 'Epekto ng Panahon',
        'message': 'Paano nakakaapekto ang panahon sa paglago ng pananim?',
        'color': Colors.amber,
      },
    ];
  }

  // Get all quick options (yield analysis + general farming)
  List<Map<String, dynamic>> _getAllQuickOptions() {
    final options = <Map<String, dynamic>>[];

    // Add general farming options first
    options.addAll(_getGeneralFarmingOptions());

    // Add yield analysis options if we have data
    if (_yieldData != null && _yieldData!.isNotEmpty) {
      options.addAll(_getYieldAnalysisPrompts());
    }

    return options;
  }

  // Extract only required fields from yield data
  Map<String, dynamic> _extractYieldFields(
      dynamic yield, List<String> requiredFields) {
    final Map<String, dynamic> extracted = {};

    for (var field in requiredFields) {
      switch (field) {
        case 'id':
          extracted['id'] = yield.id;
          break;
        case 'volume':
          extracted['volume'] = yield.volume;
          break;
        case 'farmerName':
          extracted['farmerName'] = yield.farmerName;
          break;
        case 'productName':
          extracted['productName'] = yield.productName;
          break;
        case 'value':
          extracted['value'] = yield.value;
          break;
        case 'harvestDate':
          extracted['harvestDate'] = yield.harvestDate?.toIso8601String();
          break;
        case 'status':
          extracted['status'] = yield.status;
          break;
        case 'farmName':
          extracted['farmName'] = yield.farmName;
          break;
        case 'hectare':
          extracted['hectare'] = yield.hectare;
          break;
        case 'areaHarvested':
          extracted['areaHarvested'] = yield.areaHarvested;
          break;
        case 'sector':
          extracted['sector'] = yield.sector;
          break;
        case 'barangay':
          extracted['barangay'] = yield.barangay;
          break;
      }
    }

    return extracted;
  }

  // Create condensed yield data for a specific prompt
  List<Map<String, dynamic>> _getCondensedYieldData(
      List<String> requiredFields) {
    final dataToUse = _yieldData ?? [];

    if (dataToUse.isEmpty) return [];

    return dataToUse
        .map((yield) => _extractYieldFields(yield, requiredFields))
        .toList();
  }

  // Construct full prompt with yield data
  String _constructPromptWithData(
      String basePrompt, List<String> requiredFields) {
    final condensedData = _getCondensedYieldData(requiredFields);

    // Convert to JSON string
    final jsonData = jsonEncode(condensedData);

    // Construct final prompt
    final fullPrompt = '''$basePrompt

Yield Data:
$jsonData

Pakianalyze ang data na ito at magbigay ng detalyadong sagot sa Tagalog.''';

    return fullPrompt;
  }

  void _resetChat() {
    setState(() {
      _chatbotModel.clearMessages();
      _conversationStarted = false;
      _textController.clear();
      _focusNode.unfocus();

      // Resume auto-scroll when resetting to empty state
      if (!_conversationStarted) {
        _resumeAutoScroll();
      }
    });
  }

  void _startAutoScroll() {
    _stopAutoScroll();

    // Changed from 16ms (60fps) to 8ms (120fps) for ultra-smooth scrolling
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 8), (timer) {
      if (!mounted || !_carouselScrollController.hasClients) return;

      final maxScroll = _carouselScrollController.position.maxScrollExtent;
      if (maxScroll <= 0) return;

      // Calculate next position with higher frame rate
      _currentScrollOffset += (_scrollSpeed / 225); // Adjusted for 125 FPS

      // Seamless loop with instant jump
      if (_currentScrollOffset >= maxScroll) {
        _currentScrollOffset = 0;
        _carouselScrollController.jumpTo(_currentScrollOffset);
      } else {
        _carouselScrollController.jumpTo(_currentScrollOffset);
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  void _pauseAutoScroll() {
    _stopAutoScroll();
  }

  void _resumeAutoScroll() {
    // Reduced delay from 2 seconds to 1 second for faster resume
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted && !_isUserInteracting) {
        _startAutoScroll();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _chatbotModel = ChatbotModel();
    _chatbotModel.addListener(_onChatbotModelChanged);
if (!kIsWeb) {
      _initializeTts();
    }
    // Initialize AnimationController for dots
    _dotAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();

    _dotAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_dotAnimationController);

    // Initialize scroll controller
    _carouselScrollController = ScrollController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadYields();
  }

  @override
  void didUpdateWidget(covariant ChatbotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ensure auto-scroll is running when widget updates
    if (!_conversationStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _carouselScrollController.hasClients) {
          _startAutoScroll();
        }
      });
    }
  }

  void _loadYields() {
    if (!_hasLoadedYields) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final farmerId = userProvider.farmer?.id.toString();

      context.read<YieldBloc>().add(farmerId != null && farmerId.isNotEmpty
          ? LoadYieldsByFarmer(int.parse(farmerId))
          : LoadYields());

      _hasLoadedYields = true;
      setState(() {
        _isLoadingYields = true;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _chatbotModel.removeListener(_onChatbotModelChanged);
    _dotAnimationController.dispose();
    _stopAutoScroll();
    _carouselScrollController.dispose();
 if (!kIsWeb && _flutterTts != null) {
      _flutterTts!.stop();
    }
    super.dispose();
  }




 Future<void> _initializeTts() async {
    if (kIsWeb) return; // Skip on web
    
    try {
      _flutterTts = FlutterTts();
      
      await _flutterTts!.setLanguage("fil-PH");
      await _flutterTts!.setSpeechRate(0.5);
      await _flutterTts!.setVolume(1.0);
      await _flutterTts!.setPitch(1.0);
      
      _flutterTts!.setStartHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = true;
          });
        }
      });
      
      _flutterTts!.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            _currentSpeakingMessageId = null;
          });
        }
      });
      
      _flutterTts!.setErrorHandler((msg) {
        if (kDebugMode) {
          print('TTS Error: $msg');
        }
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            _currentSpeakingMessageId = null;
          });
        }
      });
      
      if (kDebugMode) {
        final languages = await _flutterTts!.getLanguages;
        print('Available TTS languages: $languages');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize TTS: $e');
      }
    }
  }
  
  Future<void> _speak(String text, String messageId) async {
    if (kIsWeb || _flutterTts == null) return; // Skip on web
    
    if (_isSpeaking && _currentSpeakingMessageId == messageId) {
      await _flutterTts!.stop();
      setState(() {
        _isSpeaking = false;
        _currentSpeakingMessageId = null;
      });
    } else {
      await _flutterTts!.stop();
      setState(() {
        _currentSpeakingMessageId = messageId;
      });
      await _flutterTts!.speak(text);
    }
  }
  
  Future<void> _stopSpeaking() async {
    if (kIsWeb || _flutterTts == null) return; // Skip on web
    
    await _flutterTts!.stop();
    setState(() {
      _isSpeaking = false;
      _currentSpeakingMessageId = null;
    });
  }




  void _onChatbotModelChanged() {
    if (_chatbotModel.messages.length > 1 && !_conversationStarted) {
      setState(() {
        _conversationStarted = true;
      });
      _stopAutoScroll();
    }
  }

  void _handleSendPressed() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _chatbotModel.addUserMessage(text, yieldData: _yieldData);
    _chatbotModel.getBotResponse(text);
    _textController.clear();
  }

  void _handleQuickOption(Map<String, dynamic> option) {
    final message = option['message'] as String;

    // Check if this is a yield analysis option (has requiredFields)
    if (option.containsKey('requiredFields')) {
      final requiredFields = option['requiredFields'] as List<String>;
      final fullPrompt = _constructPromptWithData(message, requiredFields);

      // Send the full prompt with yield data
      _chatbotModel.addUserMessage(option['title']);
      _chatbotModel.getBotResponse(fullPrompt);
    } else {
      // Send regular message for general farming options
      _chatbotModel.addUserMessage(message);
      _chatbotModel.getBotResponse(message);
    }
  }

  Widget _buildRedditStylePill(Map<String, dynamic> option, bool isDarkMode) {
    final color = option['color'] as Color;

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
        onTap: () => _handleQuickOption(option),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            // color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
            // gradient: LinearGradient(
            //   begin: Alignment.topLeft,
            //   end: Alignment.bottomRight,
            //   colors: isDarkMode
            //       ? [
            //           color.withOpacity(0.2),
            //           color.withOpacity(0.1),
            //         ]
            //       : [
            //           color.withOpacity(0.15),
            //           color.withOpacity(0.05),
            //         ],
            // ),

            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  isDarkMode ? color.withOpacity(0.4) : color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                option['icon'],
                size: 16,
                color: isDarkMode ? color.withOpacity(0.9) : color,
              ),
              const SizedBox(width: 8),
              Text(
                option['title'],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return
    
     BlocConsumer<YieldBloc, YieldState>(
      listener: (context, state) {
        if (state is YieldsLoaded) {
          _chatbotModel.setYieldData(state.yields);

          if (_yieldData == null || _yieldData!.length != state.yields.length) {
            setState(() {
              _yieldData = state.yields;
              _isLoadingYields = false;
            });
          }
        } else if (state is YieldsLoading) {
          setState(() {
            _isLoadingYields = true;
          });
        } else if (state is YieldsError) {
          setState(() {
            _isLoadingYields = false;
          });
        }
      },
      builder: (context, state) {
        return ChangeNotifierProvider.value(
          value: _chatbotModel,
          child: SingleChildScrollView(
            child: Container(
              height: screenHeight - 80,
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
      },
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
    _chatbotModel.getBotResponse(suggestion);
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
            // Show dynamic suggestions when conversation has started
            if (_conversationStarted && !model.isTyping)
              _buildDynamicSuggestions(isMobile, isDarkMode),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Theme.of(context).cardTheme.color!
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(24),
              ),
              child: RawKeyboardListener(
                focusNode: FocusNode(),
                onKey: (RawKeyEvent event) {
                  if (event is RawKeyDownEvent) {
                    if (event.logicalKey == LogicalKeyboardKey.enter &&
                        !event.isShiftPressed) {
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
                          hintText: 'Magsulat dito...',
                          hintStyle: TextStyle(
                            color: isDarkMode
                                ? Colors.grey[500]
                                : Colors.grey[600],
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

  Widget _buildHorizontalGridOptions(
      List<Map<String, dynamic>> quickOptions, bool isDarkMode) {
    // Start auto-scroll when widget builds if we have options
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && quickOptions.isNotEmpty && !_conversationStarted) {
        _startAutoScroll();
      }
    });

    final loopedOptions = [...quickOptions, ...quickOptions];

    return SizedBox(
      height: 120,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification) {
            _isUserInteracting = true;
            _pauseAutoScroll();
          } else if (notification is ScrollUpdateNotification) {
            // Update _currentScrollOffset to match user's manual scroll position
            if (_isUserInteracting && _carouselScrollController.hasClients) {
              _currentScrollOffset = _carouselScrollController.offset;
            }
          } else if (notification is ScrollEndNotification) {
            // Sync one final time when user stops scrolling
            if (_carouselScrollController.hasClients) {
              _currentScrollOffset = _carouselScrollController.offset;
            }
            _isUserInteracting = false;
            _resumeAutoScroll();
          }
          return false;
        },
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            scrollbars: false,
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.stylus,
              PointerDeviceKind.trackpad,
            },
          ),
          child: ListView.builder(
            controller: _carouselScrollController,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            itemCount: (loopedOptions.length / 2).ceil(),
            itemBuilder: (context, sectionIndex) {
              final startIndex = sectionIndex * 2;
              final endIndex = math.min(startIndex + 2, loopedOptions.length);
              final sectionOptions =
                  loopedOptions.sublist(startIndex, endIndex);

              return Container(
                margin: EdgeInsets.only(
                  left: sectionIndex == 0 ? 16 : 8,
                  right: 8,
                ),
                child: IntrinsicWidth(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // First pill in the column
                      if (sectionOptions.length > 0)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: _buildPillWithAnimation(
                            sectionOptions[0],
                            isDarkMode,
                            (loopedOptions.indexOf(sectionOptions[0]) %
                                quickOptions.length),
                          ),
                        ),

                      // Second pill in the column
                      if (sectionOptions.length > 1)
                        _buildPillWithAnimation(
                          sectionOptions[1],
                          isDarkMode,
                          (loopedOptions.indexOf(sectionOptions[1]) %
                              quickOptions.length),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPillWithAnimation(
      Map<String, dynamic> option, bool isDarkMode, int index) {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 300 + (index * 50)),
      opacity: 1.0,
      child: Transform.translate(
        offset: Offset(0, 0),
        child: _buildRedditStylePill(option, isDarkMode),
      ),
    );
  }

  Widget _buildQuickTopicsEmptyState(bool isMobile, bool isDarkMode) {
    final quickOptions = _getAllQuickOptions();

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Paano kita matutulungan?',
              style: TextStyle(
                fontSize: isMobile ? 18 : 22,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.grey[200] : Colors.grey[900],
              ),
              textAlign: TextAlign.center,
            ),
            if (_yieldData != null && _yieldData!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'May yield data: ${_yieldData!.length} records',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.green[300] : Colors.green[700],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Auto-scrolling horizontal carousel
            if (quickOptions.isNotEmpty)
              _buildHorizontalGridOptions(quickOptions, isDarkMode),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }






// Replace the _buildChatInterfaceCard method with this fixed version:

Widget _buildChatInterfaceCard(bool isMobile, bool isDarkMode) {
  return Consumer<ChatbotModel>(
    builder: (context, model, child) {
      final bool isTyping = model.isTyping;
      final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isTyping && !_dotAnimationController.isAnimating) {
          _dotAnimationController.repeat();
        } else if (!isTyping && _dotAnimationController.isAnimating) {
          _dotAnimationController.stop();
        }
      });

      return Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Card(
              color: isDarkMode ? FlarelineColors.darkerBackground : Colors.white,
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (model.messages.length > 1)
                    const SizedBox(height: 50),

                  Expanded(
                    child: model.messages.length <= 1
                        ? Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: _buildQuickTopicsEmptyState(isMobile, isDarkMode),
                          )
                        : Chat(
                            messages: model.messages,
                            onSendPressed: (p) {},
                            user: model.user,
                            showUserAvatars: true,
                            showUserNames: true,
                            usePreviewData: false,


    bubbleBuilder: !kIsWeb 
                                  ? (child, {required message, required nextMessageInGroup}) {
                                      final isBot = message.author.id == model.bot.id;
                                      
                                      // Extract text from message safely
                                      String messageText = '';
                                      if (message is types.TextMessage) {
                                        messageText = message.text;
                                      }
                                      
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Flexible(child: child),
                                          
                                          // Add TTS button for bot messages with text (mobile only)
                                          if (isBot && messageText.isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            _buildTtsButton(
                                              message.id,
                                              messageText,
                                              isDarkMode,
                                            ),
                                          ],
                                        ],
                                      );
                                    }
                                  : null, // No custom bubble builder on web



                            customBottomWidget: Padding(
                              // KEY FIX: Add padding at bottom to lift input above keyboard
                              padding: EdgeInsets.only(bottom: keyboardHeight),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_conversationStarted && !model.isTyping)
                                    _buildDynamicSuggestions(isMobile, isDarkMode),
                                  
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? Theme.of(context).cardTheme.color!
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: RawKeyboardListener(
                                      focusNode: FocusNode(),
                                      onKey: (RawKeyEvent event) {
                                        if (event is RawKeyDownEvent) {
                                          if (event.logicalKey == LogicalKeyboardKey.enter &&
                                              !event.isShiftPressed) {
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
                                                hintText: 'Magsulat dito...',
                                                hintStyle: TextStyle(
                                                  color: isDarkMode
                                                      ? Colors.grey[500]
                                                      : Colors.grey[600],
                                                ),
                                                border: InputBorder.none,
                                                contentPadding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 10,
                                                ),
                                              ),
                                              maxLines: null,
                                              textCapitalization: TextCapitalization.sentences,
                                              // REMOVED: scrollPadding (not needed with proper bottom padding)
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
                              ),
                            ),
                            theme: DefaultChatTheme(
                              backgroundColor: isDarkMode
                                  ? FlarelineColors.darkerBackground
                                  : Colors.white,
                              primaryColor: isDarkMode
                                  ? Theme.of(context).cardTheme.color!
                                  : Colors.grey.shade200,
                              secondaryColor: isDarkMode
                                  ? Theme.of(context).cardTheme.color!
                                  : Colors.grey.shade200,
                              inputBackgroundColor: isDarkMode
                                  ? Theme.of(context).cardTheme.color!
                                  : Colors.grey.shade200,
                              inputTextColor:
                                  isDarkMode ? Colors.white : Colors.black87,
                              inputBorderRadius: BorderRadius.circular(24),
                              inputMargin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              userAvatarNameColors: [
                                isDarkMode ? Colors.grey[300]! : Colors.black
                              ],
                              receivedMessageBodyTextStyle: TextStyle(
                                color: isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[800],
                                fontSize: isMobile ? 14 : 16,
                                height: 1.4,
                              ),
                              sentMessageBodyTextStyle: TextStyle(
                                color: isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[800],
                                fontSize: 14,
                                height: 1.4,
                              ),
                              receivedMessageBodyLinkTextStyle: TextStyle(
                                color: isDarkMode
                                    ? Colors.blue[200]!
                                    : Colors.blue,
                                fontSize: isMobile ? 14 : 16,
                                height: 1.4,
                              ),
                              sendButtonIcon: Icon(
                                Icons.send,
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey,
                                size: 22,
                              ),
                            ),
                            typingIndicatorOptions: TypingIndicatorOptions(
                              typingUsers: model.isTyping ? [model.bot] : [],
                              customTypingIndicator: model.isTyping
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: AnimatedBuilder(
                                              animation: _dotAnimation,
                                              builder: (context, child) {
                                                return Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    _buildAnimatedDot(
                                                        0,
                                                        isDarkMode,
                                                        _dotAnimation.value),
                                                    const SizedBox(width: 4),
                                                    _buildAnimatedDot(
                                                        1,
                                                        isDarkMode,
                                                        _dotAnimation.value),
                                                    const SizedBox(width: 4),
                                                    _buildAnimatedDot(
                                                        2,
                                                        isDarkMode,
                                                        _dotAnimation.value),
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : null,
                            ),
                            avatarBuilder: (userId) {
                              final bool isBot = userId == model.bot.id;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: CircleAvatar(
                                  backgroundColor: isBot
                                      ? (isDarkMode
                                          ? Theme.of(context)
                                              .cardTheme
                                              .color!
                                          : Colors.grey.shade200)
                                      : (isDarkMode
                                          ? Theme.of(context)
                                              .cardTheme
                                              .color!
                                          : Colors.grey[200]!),
                                  child: isBot
                                      ? Icon(
                                          Icons.person,
                                          color: isDarkMode
                                              ? Colors.grey.shade200
                                              : Colors.grey.shade800,
                                          size: 20,
                                        )
                                      : ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(22),
                                          child: SvgPicture.asset(
                                            'assets/DA_image.svg',
                                            width: 36,
                                            height: 36,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                ),
                              );
                            },
                            scrollPhysics: const BouncingScrollPhysics(),
                            listBottomWidget: const SizedBox(height: 16),
                          ),
                  ),
                  
                  // Input for empty state with keyboard padding
                  if (model.messages.length <= 1)
                    Padding(
                      padding: EdgeInsets.only(bottom: keyboardHeight),
                      child: _buildCustomInput(isMobile, isDarkMode),
                    ),
                ],
              ),
            ),
          ),

          // Reset button
          if (model.messages.length > 1)
            Positioned(
              top: 8,
              right: 8,
              child: ResetButton(
                isDarkMode: isDarkMode,
                onReset: () {
                  _resetChat();
                  if (_dotAnimationController.isAnimating) {
                    _dotAnimationController.stop();
                  }
                },
              ),
            ),
        ],
      );
    },
  );
}







Widget _buildAnimatedDot(int index, bool isDarkMode, double animationValue) {
  final double phase = (animationValue + (index * 0.33)) % 1.0;
  final double opacity = 
      // ADD CHECK: If animation is not running, show static dots
      _dotAnimationController.isAnimating 
          ? 0.3 + (0.7 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi)))
          : 0.3; // Static opacity when not animating

  return Opacity(
    opacity: opacity,
    child: Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        shape: BoxShape.circle,
      ),
    ),
  );
}




 Widget _buildTtsButton(String messageId, String text, bool isDarkMode) {
    final isThisMessageSpeaking = _isSpeaking && _currentSpeakingMessageId == messageId;
    
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Tooltip(
        message: isThisMessageSpeaking ? 'Itigil' : 'Basahin',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _speak(text, messageId),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isThisMessageSpeaking
                    ? (isDarkMode ? Colors.blue[700] : Colors.blue[100])
                    : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isThisMessageSpeaking ? Icons.stop : Icons.volume_up,
                size: 18,
                color: isThisMessageSpeaking
                    ? (isDarkMode ? Colors.white : Colors.blue[700])
                    : (isDarkMode ? Colors.grey[400] : Colors.grey[700]),
              ),
            ),
          ),
        ),
      ),
    );
  }



}




