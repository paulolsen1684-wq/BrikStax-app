// lib/widgets/brick_burst.dart
//
// Shared "brick burst" celebration effect -- small rotating pixel-bricks
// bursting outward from center with a fade-out, intensity/color tunable.
// Originally private to deal_check_screen.dart (Deal Check's OK/Decent/Great
// result reveal); extracted so loot_roll_widget.dart (rarer cosmetic
// reveals) and set_added_celebration.dart (new: celebrating adding a set,
// scaled by its value) can reuse the same particle effect instead of each
// hand-rolling their own painter.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BrickBurstPainter extends CustomPainter {
  final double progress;   // 0..1
  final Color  color;
  final double intensity;  // 0..1 -- more bricks / bigger spread for bigger moments
  BrickBurstPainter({
    required this.progress,
    required this.color,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final p  = Paint()..style = PaintingStyle.fill;

    final count = (8 + intensity * 16).round();
    final maxR  = (40 + intensity * 90);
    final ease  = Curves.easeOut.transform(progress.clamp(0.0, 1.0));

    for (int i = 0; i < count; i++) {
      final ang = (i / count) * 2 * math.pi + i * 0.6;
      final dist = maxR * ease * (0.5 + (i % 5) / 8);
      final x = cx + dist * 0.95 * math.cos(ang);
      final y = cy + dist * 0.7  * math.sin(ang) - ease * 8;

      // fade out toward the end
      final fade = (1.0 - (progress - 0.5).clamp(0.0, 0.5) * 2).clamp(0.0, 1.0);
      final pal = [color, BT.yellow, BT.ink];
      p.color = pal[i % pal.length].withOpacity(0.85 * fade);

      final s = 5.0 + (i % 3) * 2.0;
      // little rotating brick (rounded rect)
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(ang + ease * 3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: s * 1.6, height: s),
          const Radius.circular(1.5),
        ), p);
      // stud
      p.color = p.color.withOpacity(0.5 * fade);
      canvas.drawCircle(Offset(0, -s * 0.4), s * 0.18, p);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant BrickBurstPainter old) =>
      old.progress != progress || old.color != color ||
      old.intensity != intensity;
}

/// Self-contained one-shot burst: owns its own controller, plays forward
/// once on mount, calls [onComplete] when finished. For call sites that
/// just want "play a burst here" without wiring their own
/// AnimationController -- deal_check_screen.dart still drives
/// BrickBurstPainter off its own shared controller directly, since it syncs
/// the burst with other reveal effects (text pop-in) on the same timeline.
class BrickBurstOverlay extends StatefulWidget {
  final Color color;
  final double intensity;
  final Duration duration;
  final VoidCallback? onComplete;
  const BrickBurstOverlay({
    super.key,
    required this.color,
    this.intensity = 0.6,
    this.duration = const Duration(milliseconds: 900),
    this.onComplete,
  });

  @override
  State<BrickBurstOverlay> createState() => _BrickBurstOverlayState();
}

class _BrickBurstOverlayState extends State<BrickBurstOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(() => setState(() {}))
      ..forward().whenComplete(() => widget.onComplete?.call());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      painter: BrickBurstPainter(
        progress: _ctrl.value, color: widget.color, intensity: widget.intensity),
      size: Size.infinite,
    ),
  );
}
