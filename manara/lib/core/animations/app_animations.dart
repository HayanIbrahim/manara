import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppAnimations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);

  /// Extension helper for cascading list items
  static Widget staggeredEntrance(
    Widget child, {
    required int index,
    Duration delayStep = const Duration(milliseconds: 50),
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return child
        .animate(delay: delayStep * index)
        .fadeIn(duration: duration, curve: Curves.easeOut)
        .slideY(begin: 0.12, end: 0, duration: duration, curve: Curves.easeOutQuad);
  }

  /// Fade & scale entrance
  static Widget popIn(Widget child, {Duration delay = Duration.zero}) {
    return child
        .animate(delay: delay)
        .fadeIn(duration: medium)
        .scale(begin: const Offset(0.92, 0.92), end: const Offset(1, 1), curve: Curves.easeOutBack);
  }
}

/// Shake animation widget for errors (e.g. Device Mismatch)
class ShakeAnimationWidget extends StatefulWidget {
  final Widget child;
  final bool shake;
  final VoidCallback? onComplete;

  const ShakeAnimationWidget({
    super.key,
    required this.child,
    required this.shake,
    this.onComplete,
  });

  @override
  State<ShakeAnimationWidget> createState() => _ShakeAnimationWidgetState();
}

class _ShakeAnimationWidgetState extends State<ShakeAnimationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reset();
        widget.onComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ShakeAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake && !oldWidget.shake) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        // 4 shakes with decay
        final offset = math.sin(progress * math.pi * 8) * 12 * (1 - progress);
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
