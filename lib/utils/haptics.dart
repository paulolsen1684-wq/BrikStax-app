// lib/utils/haptics.dart
//
// Thin wrapper around Flutter's HapticFeedback so call sites read clearly
// (BrikHaptics.light() instead of remembering which HapticFeedback method
// maps to which feeling) and so the whole app can be muted/tuned from one
// place later if needed.
import 'package:flutter/services.dart';

class BrikHaptics {
  BrikHaptics._();

  /// Light tap — for routine taps: nav items, chips, list items.
  static void light() => HapticFeedback.lightImpact();

  /// Medium tap — for confirmations: saving an edit, submitting a form.
  static void medium() => HapticFeedback.mediumImpact();

  /// Heavy tap — for significant moments: claiming daily brick, unlocking
  /// an achievement, completing a hidden theme tier.
  static void heavy() => HapticFeedback.heavyImpact();

  /// Selection tick — for toggles, segmented control switches (theme
  /// picker, scanner mode toggle).
  static void selection() => HapticFeedback.selectionClick();
}
