import 'package:flutter/material.dart';

class NeonFlickerRoute extends PageRouteBuilder {
  final Widget page;

  NeonFlickerRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          // 800ms is enough time to feel the "clip clip" flicker effect
          transitionDuration: const Duration(milliseconds: 800),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            
            // This sequence creates the "Bad Neon Lamp" startup effect
            // It jumps brightness up and down before stabilizing at 1.0
            var flickerTween = TweenSequence<double>([
              TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.1), weight: 10), // Dark start
              TweenSequenceItem(tween: Tween(begin: 0.1, end: 0.8), weight: 15), // Flash Bright
              TweenSequenceItem(tween: Tween(begin: 0.8, end: 0.2), weight: 10), // Die out
              TweenSequenceItem(tween: Tween(begin: 0.2, end: 0.9), weight: 20), // Flash Bright again
              TweenSequenceItem(tween: Tween(begin: 0.9, end: 0.4), weight: 10), // Dim again
              TweenSequenceItem(tween: Tween(begin: 0.4, end: 1.0), weight: 35), // Full ON
            ]);

            return FadeTransition(
              opacity: flickerTween.animate(
                CurvedAnimation(parent: animation, curve: Curves.linear),
              ),
              child: child,
            );
          },
        );
}