




import 'package:flutter/material.dart';

import 'dart:math' as math;

class ResetButton extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onReset;

  const ResetButton({
    required this.isDarkMode,
    required this.onReset,
  });

  @override
  State<ResetButton> createState() => _ResetButtonState();
}

class _ResetButtonState extends State<ResetButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _scale = 1.0;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _scale = 0.95;
    });
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _scale = _isHovering ? 1.1 : 1.0;
    });
    _controller.forward(from: 0);
    widget.onReset();
  }

  void _onTapCancel() {
    setState(() {
      _scale = _isHovering ? 1.1 : 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() {
          _isHovering = true;
          _scale = 1.1;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovering = false;
          _scale = 1.0;
        });
      },
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: _scale,
          curve: Curves.easeInOut,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ripple effect
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _RipplePainter(
                      progress: _controller.value,
                      color: widget.isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.1),
                    ),
                    size: const Size(56, 56),
                  );
                },
              ),
              
              // Button content
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.isDarkMode
                      ? Colors.grey[850]!.withOpacity(0.95)
                      : Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: widget.isDarkMode
                          ? Colors.black.withOpacity(0.25)
                          : Colors.grey.withOpacity(0.25),
                      blurRadius: _isHovering ? 20 : 12,
                      offset: const Offset(0, 3),
                      spreadRadius: _isHovering ? 2 : 1,
                    ),
                    if (_isHovering)
                      BoxShadow(
                        color: (widget.isDarkMode 
                            ? Colors.blue.withOpacity(0.2) 
                            : Colors.blueAccent.withOpacity(0.1)),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                  ],
                  border: Border.all(
                    color: _isHovering
                        ? (widget.isDarkMode 
                            ? Colors.blue.withOpacity(0.4) 
                            : Colors.blueAccent.withOpacity(0.3))
                        : (widget.isDarkMode
                            ? Colors.grey[700]!.withOpacity(0.6)
                            : Colors.grey[400]!.withOpacity(0.6)),
                    width: _isHovering ? 1.8 : 1.5,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isHovering
                        ? [
                            if (widget.isDarkMode) ...[
                              Colors.grey[800]!.withOpacity(0.9),
                              Colors.grey[900]!.withOpacity(0.9),
                            ] else ...[
                              Colors.white.withOpacity(0.98),
                              Colors.grey[100]!.withOpacity(0.98),
                            ],
                          ]
                        : [
                            if (widget.isDarkMode) ...[
                              Colors.grey[850]!.withOpacity(0.9),
                              Colors.grey[800]!.withOpacity(0.9),
                            ] else ...[
                              Colors.white.withOpacity(0.95),
                              Colors.grey[50]!.withOpacity(0.95),
                            ],
                          ],
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 300),
                      turns: _isHovering ? 0.25 : 0.0,
                      curve: Curves.easeInOut,
                      child: Icon(
                        Icons.refresh_rounded,
                        color: _isHovering
                            ? (widget.isDarkMode 
                                ? Colors.blue[300] 
                                : Colors.blueAccent)
                            : (widget.isDarkMode 
                                ? Colors.grey[300]!.withOpacity(0.9)
                                : Colors.grey[700]!.withOpacity(0.9)),
                        size: 22,
                      ),
                    ),
                 
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  _RipplePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height) / 2;
    final currentRadius = maxRadius * progress;

    final paint = Paint()
      ..color = color.withOpacity(1.0 - progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, currentRadius, paint);
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) {
    return progress != oldDelegate.progress || color != oldDelegate.color;
  }
}