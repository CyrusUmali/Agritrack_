import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flareline/services/lanugage_extension.dart';

// ============================================================
// SUGGESTIONS CARD WIDGET
// ============================================================

class SuggestionsCard extends StatefulWidget {
  final List<String> suggestions;
  final int deficientParamsCount;
  final bool isSmallScreen;
  final double padding;
  final Function() onGetSuggestions;
  final bool isLoadingSuggestions;

  const SuggestionsCard({
    super.key,
    required this.suggestions,
    required this.deficientParamsCount,
    required this.isSmallScreen,
    required this.padding,
    required this.onGetSuggestions,
    required this.isLoadingSuggestions,
  });

  @override
  State<SuggestionsCard> createState() => _SuggestionsCardState();
}

class _SuggestionsCardState extends State<SuggestionsCard> {
  late FlutterTts _flutterTts;
  bool _isSpeaking = false;
  bool _ttsInitialized = false;
  int? _currentSpeakingIndex;
  int? _speakingStartIndex;
  
  // For pause/resume functionality
  String? _currentSpeakingText;
  int? _currentTextPosition;
  bool _isPaused = false;
  
  // Floating button visibility control
  bool _showFloatingButton = false;
  final _floatingButtonAnimationDuration = const Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initializeTts();
    }
  }

@override
void deactivate() {
  // Stop TTS when widget is removed from the widget tree
  if (!kIsWeb && _ttsInitialized && (_isSpeaking || _isPaused)) {
    _flutterTts.stop();
    _isSpeaking = false;
    _isPaused = false;
    _currentSpeakingIndex = null;
    _speakingStartIndex = null;
    _currentTextPosition = null;
    _currentSpeakingText = null;
    _showFloatingButton = false;
  }
  super.deactivate();
}


@override
void didUpdateWidget(SuggestionsCard oldWidget) {
  super.didUpdateWidget(oldWidget);
  
  // If suggestions changed while speaking, stop TTS
  if (widget.suggestions != oldWidget.suggestions && 
      !kIsWeb && 
      _ttsInitialized && 
      (_isSpeaking || _isPaused)) {
    _flutterTts.stop();
    _isSpeaking = false;
    _isPaused = false;
    _currentSpeakingIndex = null;
    _speakingStartIndex = null;
    _currentTextPosition = null;
    _currentSpeakingText = null;
    _showFloatingButton = false;
  }
}

  @override
  void dispose() {
    if (!kIsWeb && _ttsInitialized) {
      _flutterTts.stop();
    }
    super.dispose();
  }

  Future<void> _initializeTts() async {
    if (kIsWeb) return;
    
    try {
      _flutterTts = FlutterTts();
      
      await _flutterTts.setLanguage("fil-PH");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      
      _ttsInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize TTS: $e');
      }
    }
  }

  Future<void> _speakFromIndex(int startIndex) async {
    if (kIsWeb || !_ttsInitialized) return;
    
    // If clicking the same starting point, stop
    if (_isSpeaking && _speakingStartIndex == startIndex && !_isPaused) {
      await _stopSpeaking();
      return;
    }
    
    // If paused and same index, resume
    if (_isPaused && _speakingStartIndex == startIndex) {
      await _resumeSpeaking();
      return;
    }
    
    // Stop any current speech
    await _stopSpeaking();
    
    // Show floating button
    setState(() {
      _showFloatingButton = true;
      _isPaused = false;
    });
    
    // Set initial state
    setState(() {
      _isSpeaking = true;
      _currentSpeakingIndex = startIndex;
      _speakingStartIndex = startIndex;
      _currentTextPosition = null;
    });
    
    // Speak each suggestion sequentially
    for (int i = startIndex; i < widget.suggestions.length; i++) {
      // Check if we should stop (user clicked stop or paused)
      if (!_isSpeaking || _isPaused) break;
      
      // Update which suggestion is currently being spoken
      if (mounted) {
        setState(() {
          _currentSpeakingIndex = i;
        });
      }
      
      // Store current text for potential pause/resume
      _currentSpeakingText = widget.suggestions[i];
      _currentTextPosition = 0;
      
      // Speak this suggestion and wait for it to complete
      try {
        await _flutterTts.speak(widget.suggestions[i]);
        // Wait for speech to complete before moving to next
        await _flutterTts.awaitSpeakCompletion(true);
      } catch (e) {
        if (kDebugMode) {
          print('TTS speak error: $e');
        }
        break;
      }
      
      // Reset position after finishing
      _currentTextPosition = null;
      _currentSpeakingText = null;
      
      // Small delay between suggestions
      if (i < widget.suggestions.length - 1) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
    
    // All done or stopped
    if (mounted && !_isPaused) {
      setState(() {
        _isSpeaking = false;
        _currentSpeakingIndex = null;
        _speakingStartIndex = null;
        _currentTextPosition = null;
        _currentSpeakingText = null;
      });
    }
  }

  Future<void> _speak(String text, {int? index}) async {
    if (kIsWeb || !_ttsInitialized) return;
    
    if (_isSpeaking && !_isPaused) {
      await _stopSpeaking();
    } else if (_isPaused) {
      await _resumeSpeaking();
    } else {
      // Show floating button
      setState(() {
        _showFloatingButton = true;
        _isPaused = false;
      });
      
      setState(() {
        _isSpeaking = true;
        _currentSpeakingIndex = index;
        _speakingStartIndex = 0;
      });
      
      try {
        await _flutterTts.speak(text);
        
        // Listen for completion to hide floating button
        _flutterTts.setCompletionHandler(() {
          if (mounted) {
            setState(() {
              _isSpeaking = false;
              _isPaused = false;
              if (_currentSpeakingIndex == widget.suggestions.length - 1) {
                _showFloatingButton = false;
              }
            });
          }
        });
      } catch (e) {
        if (kDebugMode) {
          print('TTS speak error: $e');
        }
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            _isPaused = false;
            _currentSpeakingIndex = null;
            _speakingStartIndex = null;
            _showFloatingButton = false;
          });
        }
      }
    }
  }

  Future<void> _toggleSpeaking() async {
    if (kIsWeb || !_ttsInitialized) return;
    
    if (_isSpeaking && !_isPaused) {
      await _pauseSpeaking();
    } else if (_isPaused) {
      await _resumeSpeaking();
    } else if (_currentSpeakingIndex != null) {
      // Resume from current index
      await _speakFromIndex(_currentSpeakingIndex!);
    }
  }

  Future<void> _pauseSpeaking() async {
    if (kIsWeb || !_ttsInitialized || !_isSpeaking || _isPaused) return;
    
    await _flutterTts.stop();
    setState(() {
      _isPaused = true;
      _isSpeaking = false;
    });
  }

  Future<void> _resumeSpeaking() async {
    if (kIsWeb || !_ttsInitialized || (!_isPaused && _isSpeaking)) return;
    
    setState(() {
      _isPaused = false;
      _isSpeaking = true;
      _showFloatingButton = true;
    });
    
    // Resume from current position
    if (_currentSpeakingIndex != null) {
      await _speakFromIndex(_currentSpeakingIndex!);
    } else if (_currentSpeakingText != null && _currentTextPosition != null) {
      // If we had a specific position, restart that specific text
      // Note: FlutterTts doesn't support resuming from a specific position,
      // so we restart from the beginning of the current text
      await _speak(_currentSpeakingText!, index: _currentSpeakingIndex);
    }
  }

  Future<void> _stopSpeaking() async {
    if (kIsWeb || !_ttsInitialized) return;
    
    await _flutterTts.stop();
    
    if (mounted) {
      setState(() {
        _isSpeaking = false;
        _isPaused = false;
        _currentSpeakingIndex = null;
        _speakingStartIndex = null;
        _currentTextPosition = null;
        _currentSpeakingText = null;
        _showFloatingButton = false;
      });
    }
  }

  void _hideFloatingButton() {
    if (mounted) {
      setState(() {
        _showFloatingButton = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Main content
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).cardTheme.color,
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.blue[900]!.withOpacity(0.3)
                            : Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: isDark ? Colors.blue[300] : Colors.blue[600],
                        size: widget.isSmallScreen ? 18 : 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      context.translate('Improvement Suggestions'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[200] : Colors.grey[800],
                            fontSize: widget.isSmallScreen ? 18 : 20,
                          ),
                    ),
                    const Spacer(),
                    
                    if (widget.suggestions.isNotEmpty && !kIsWeb)
                      _buildTtsButton(isDark),
                    
                    if (widget.deficientParamsCount > 0)
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.orange[900]!.withOpacity(0.3)
                              : Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isDark ? Colors.orange[700]! : Colors.orange[200]!,
                          ),
                        ),
                        child: Text(
                          '${widget.deficientParamsCount}',
                          style: TextStyle(
                            color: isDark ? Colors.orange[300] : Colors.orange[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),

                SizedBox(height: widget.isSmallScreen ? 16 : 20),

                Text(
                  '${widget.deficientParamsCount} ${context.translate('parameters need attention')}',
                  style: TextStyle(
                    fontSize: widget.isSmallScreen ? 14 : 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),

                SizedBox(height: widget.isSmallScreen ? 16 : 20),

                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: widget.suggestions.isNotEmpty
                      ? _SuggestionsContent(
                          suggestions: widget.suggestions,
                          isSmallScreen: widget.isSmallScreen,
                          isSpeaking: _isSpeaking || _isPaused,
                          currentSpeakingIndex: _currentSpeakingIndex,
                          onSpeakFromIndex: _speakFromIndex,
                        )
                      : _GetSuggestionsButton(
                          onGetSuggestions: widget.onGetSuggestions,
                          isLoadingSuggestions: widget.isLoadingSuggestions,
                          isSmallScreen: widget.isSmallScreen,
                        ),
                ),
              ],
            ),
          ),
        ),

        // Floating TTS Control Button
        if (_showFloatingButton && !kIsWeb)
          Positioned(
            bottom: 20,
            right: 20,
            child: AnimatedOpacity(
              opacity: _showFloatingButton ? 1.0 : 0.0,
              duration: _floatingButtonAnimationDuration,
              child: AnimatedScale(
                scale: _showFloatingButton ? 1.0 : 0.5,
                duration: _floatingButtonAnimationDuration,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? Colors.blue[700] : Colors.blue[600],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Stop button
                      IconButton(
                        onPressed: _stopSpeaking,
                        icon: const Icon(Icons.stop, color: Colors.white),
                        tooltip: 'Stop',
                      ),
                      
                      // Pause/Resume button
                      IconButton(
                        onPressed: _toggleSpeaking,
                        icon: Icon(
                          _isSpeaking ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                        tooltip: _isSpeaking ? 'Pause' : _isPaused ? 'Resume' : 'Play',
                      ),
                      
                      // Close button
                      IconButton(
                        onPressed: _hideFloatingButton,
                        icon: const Icon(Icons.close, color: Colors.white),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTtsButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Tooltip(
        message: _isSpeaking 
            ? context.translate('Pause')
            : _isPaused
              ? context.translate('Resume')
              : context.translate('Read aloud'),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (_isSpeaking && !_isPaused) {
                _pauseSpeaking();
              } else if (_isPaused) {
                _resumeSpeaking();
              } else {
                _speak(widget.suggestions.join('\n\n'));
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isSpeaking
                    ? (isDark ? Colors.blue[700] : Colors.blue[100])
                    : _isPaused
                      ? (isDark ? Colors.amber[800] : Colors.amber[100])
                      : (isDark ? Colors.grey[800] : Colors.grey[200]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _isSpeaking ? Icons.pause : 
                _isPaused ? Icons.play_arrow : Icons.volume_up,
                size: 18,
                color: _isSpeaking
                    ? (isDark ? Colors.white : Colors.blue[700])
                    : _isPaused
                      ? (isDark ? Colors.white : Colors.amber[700])
                      : (isDark ? Colors.grey[400] : Colors.grey[700]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SUGGESTIONS CONTENT WIDGET
// ============================================================

class _SuggestionsContent extends StatelessWidget {
  final List<String> suggestions;
  final bool isSmallScreen;
  final bool isSpeaking;
  final int? currentSpeakingIndex;
  final Function(int startIndex) onSpeakFromIndex;

  const _SuggestionsContent({
    required this.suggestions,
    required this.isSmallScreen,
    required this.isSpeaking,
    required this.currentSpeakingIndex,
    required this.onSpeakFromIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              Text(
                'Recommendations',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.touch_app,
                size: 16,
                color: isDark ? Colors.grey[500] : Colors.grey[400],
              ),
              Text(
                ' Tap to read',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? Colors.grey[600]! : Colors.grey[200]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: suggestions.asMap().entries.map((entry) {
              final index = entry.key;
              final suggestion = entry.value;
              // Only highlight the EXACT current index being spoken
              final isCurrentlyPlaying = isSpeaking && currentSpeakingIndex == index;
              
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == suggestions.length - 1 ? 0 : 16.0,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onSpeakFromIndex(index),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCurrentlyPlaying
                            ? (isDark 
                                ? Colors.blue[900]!.withOpacity(0.3) 
                                : Colors.blue[100])
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCurrentlyPlaying
                              ? (isDark ? Colors.blue[600]! : Colors.blue[300]!)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              suggestion,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 15,
                                color: isCurrentlyPlaying
                                    ? (isDark ? Colors.blue[200] : Colors.blue[900])
                                    : (isDark ? Colors.grey[300] : Colors.grey[700]),
                                height: 1.5,
                                fontWeight: isCurrentlyPlaying 
                                    ? FontWeight.w600 
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// GET SUGGESTIONS BUTTON WIDGET
// ============================================================

class _GetSuggestionsButton extends StatelessWidget {
  final Function() onGetSuggestions;
  final bool isLoadingSuggestions;
  final bool isSmallScreen;

  const _GetSuggestionsButton({
    required this.onGetSuggestions,
    required this.isLoadingSuggestions,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: isSmallScreen ? 48 : 52,
      decoration: BoxDecoration(
        color: Colors.blue[600],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoadingSuggestions ? null : onGetSuggestions,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoadingSuggestions)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                else ...[
                  const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.translate('Get AI Suggestions'),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 15 : 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DISCLAIMER WIDGET (with tap-to-read)
// ============================================================

class DisclaimerWidget extends StatefulWidget {
  final String? disclaimer;
  final bool isSmallScreen;
  final double padding;

  const DisclaimerWidget({
    super.key,
    required this.disclaimer,
    required this.isSmallScreen,
    required this.padding,
  });

  @override
  State<DisclaimerWidget> createState() => _DisclaimerWidgetState();
}

class _DisclaimerWidgetState extends State<DisclaimerWidget> {
  late FlutterTts _flutterTts;
  bool _isSpeaking = false;
  bool _ttsInitialized = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initializeTts();
    }
  }

  @override
  void dispose() {
    if (!kIsWeb && _ttsInitialized) {
      _flutterTts.stop();
    }
    super.dispose();
  }

  Future<void> _initializeTts() async {
    if (kIsWeb) return;
    
    try {
      _flutterTts = FlutterTts();
      await _flutterTts.setLanguage("fil-PH");
      await _flutterTts.setSpeechRate(0.5);
      
      _flutterTts.setStartHandler(() {
        if (mounted) setState(() => _isSpeaking = true);
      });
      
      _flutterTts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
      
      _ttsInitialized = true;
    } catch (e) {
      if (kDebugMode) print('TTS Error: $e');
    }
  }

  Future<void> _speakDisclaimer() async {
    if (kIsWeb || !_ttsInitialized) return;
    
    if (_isSpeaking) {
      await _flutterTts.stop();
    } else {
      await _flutterTts.speak(widget.disclaimer ?? context.translate('disclaimer_ai'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: !kIsWeb ? _speakDisclaimer : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isSpeaking
                ? (isDark 
                    ? Colors.blue[900]!.withOpacity(0.2) 
                    : Colors.blue[50])
                : (isDark ? Colors.grey[850] : Colors.grey[50]),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isSpeaking
                  ? (isDark ? Colors.blue[700]! : Colors.blue[200]!)
                  : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
              width: _isSpeaking ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _isSpeaking ? Icons.volume_up : Icons.info_outline,
                size: 16,
                color: _isSpeaking
                    ? (isDark ? Colors.blue[300] : Colors.blue[600])
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.disclaimer ?? context.translate('disclaimer_ai'),
                  style: TextStyle(
                    fontSize: widget.isSmallScreen ? 12 : 13,
                    color: _isSpeaking
                        ? (isDark ? Colors.blue[200] : Colors.blue[900])
                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    fontStyle: FontStyle.italic,
                    height: 1.3,
                    fontWeight: _isSpeaking ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
              if (!kIsWeb)
                Icon(
                  Icons.touch_app,
                  size: 14,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
            ],
          ),
        ),
      ),
    );
  }
}