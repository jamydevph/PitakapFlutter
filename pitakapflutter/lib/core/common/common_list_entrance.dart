import 'package:flutter/material.dart';

class CommonListEntrance extends StatelessWidget {
  final int index;
  final Widget child;

  const CommonListEntrance({
    required this.index,
    required this.child,
    super.key,
  });

  static const Duration baseDuration = Duration(milliseconds: 220);
  static const Duration perItemDelay = Duration(milliseconds: 40);
  static const int maxStaggeredItems = 8;
  static const double slideOffset = 16;

  static Duration durationFor(int index) {
    final clamped = index.clamp(0, maxStaggeredItems);

    return baseDuration + perItemDelay * clamped;
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(index),
      tween: Tween(begin: 0, end: 1),
      duration: durationFor(index),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * slideOffset),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
