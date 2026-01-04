import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SelectNodeAnimation extends StatefulWidget {
  const SelectNodeAnimation({super.key});

  @override
  State<SelectNodeAnimation> createState() => _SelectNodeAnimationState();
}

class _SelectNodeAnimationState extends State<SelectNodeAnimation>
    with TickerProviderStateMixin {
  int _currentModeIndex = 0;
  Timer? _timer;
  late AnimationController _controller;

  // Animation modes
  static const List<String> _modes = [
    'Appear',
    'Fade',
    'Fly In',
    'Zoom',
    'Float In',
    'Split',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Start animation loop
    _startAnimationLoop();
  }

  void _startAnimationLoop() {
    // Initial animation
    _playCurrentAnimation();

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentModeIndex = (_currentModeIndex + 1) % _modes.length;
        });
        _playCurrentAnimation();
      }
    });
  }

  void _playCurrentAnimation() {
    _controller.reset();
    _controller.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = GoogleFonts.sourceCodePro(
      fontSize: 16,
      color: theme.hintColor,
      fontWeight: FontWeight.w500,
    );

    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final mode = _modes[_currentModeIndex];
          return _buildAnimationForMode(mode, textStyle);
        },
      ),
    );
  }

  Widget _buildAnimationForMode(String mode, TextStyle style) {
    const text = "Make it simple";

    switch (mode) {
      case 'Appear':
        // No transition, just visible
        return Text(text, style: style);

      case 'Fade':
        return Opacity(
          opacity: _controller.value,
          child: Text(text, style: style),
        );

      case 'Fly In':
        // Slide from left
        return Transform.translate(
          offset: Offset(-50 * (1 - _controller.value), 0),
          child: Opacity(
            opacity: _controller.value,
            child: Text(text, style: style),
          ),
        );

      case 'Zoom':
        return Transform.scale(
          scale: _controller.value,
          child: Opacity(
            opacity: _controller.value,
            child: Text(text, style: style),
          ),
        );

      case 'Float In':
        // Spring-like slide up with fade
        return Transform.translate(
          offset: Offset(
            0,
            20 * (1 - Curves.easeOutBack.transform(_controller.value)),
          ),
          child: Opacity(
            // Make opacity reach 1.0 a bit faster than the movement
            opacity: min(1.0, _controller.value * 2),
            child: Text(text, style: style),
          ),
        );

      case 'Split':
        // Split "select" and "node"
        // "select" comes from left, "node" from right
        final splitValue = Curves.easeInOut.transform(_controller.value);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: Offset(-30 * (1 - splitValue), 0),
              child: Opacity(
                opacity: splitValue,
                child: Text("select ", style: style),
              ),
            ),
            Transform.translate(
              offset: Offset(30 * (1 - splitValue), 0),
              child: Opacity(
                opacity: splitValue,
                child: Text("node", style: style),
              ),
            ),
          ],
        );

      default:
        return Text(text, style: style);
    }
  }
}
