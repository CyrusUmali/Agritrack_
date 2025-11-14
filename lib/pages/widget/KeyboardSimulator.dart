 // Add this new widget to simulate mobile keyboard behavior
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter/material.dart';

 class MobileKeyboardSimulator extends StatefulWidget {
  final Widget child;
  
  const MobileKeyboardSimulator({super.key, required this.child});

  @override
  State<MobileKeyboardSimulator> createState() => _MobileKeyboardSimulatorState();
}

class _MobileKeyboardSimulatorState extends State<MobileKeyboardSimulator> {
  bool _keyboardVisible = false;
  final double _simulatedKeyboardHeight = 300.0;

  void _toggleKeyboard() {
    setState(() {
      _keyboardVisible = !_keyboardVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Main content area
            Positioned.fill(
              bottom: _keyboardVisible ? _simulatedKeyboardHeight : 0,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  viewInsets: _keyboardVisible
                      ? EdgeInsets.only(bottom: _simulatedKeyboardHeight)
                      : EdgeInsets.zero,
                ),
                child: widget.child,
              ),
            ),

            // Keyboard toggle button
            Positioned(
              bottom: _keyboardVisible 
                  ? _simulatedKeyboardHeight + 20 
                  : 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: _toggleKeyboard,
                child: Icon(_keyboardVisible ? Icons.keyboard_hide : Icons.keyboard),
                backgroundColor: Colors.orange,
              ),
            ),

            // Keyboard status indicator
            if (kDebugMode) // Only show in debug mode
              Positioned(
                bottom: _keyboardVisible 
                    ? _simulatedKeyboardHeight + 80 
                    : 80,
                right: 20,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _keyboardVisible 
                        ? 'Keyboard: VISIBLE\n${_simulatedKeyboardHeight}px'
                        : 'Keyboard: HIDDEN',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}