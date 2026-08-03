// lib/utils/brik_page_route.dart
//
// Custom page transition — fade + slight scale-up, replacing the default
// Material slide-from-right. Feels more deliberate/branded than the stock
// transition. Use BrikPageRoute in place of MaterialPageRoute wherever you
// want the polished transition (recommend: everywhere except modal sheets).
import 'package:flutter/material.dart';

class BrikPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  BrikPageRoute({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.97, end: 1.0).animate(curved),
                child: child,
              ),
            );
          },
        );
}
