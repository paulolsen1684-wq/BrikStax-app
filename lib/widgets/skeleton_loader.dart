// lib/widgets/skeleton_loader.dart
//
// Reusable shimmering placeholder for loading states — swap a plain
// CircularProgressIndicator for a shape that hints at the content coming in,
// which reads as more polished / less jarring than a spinner.
import 'package:flutter/material.dart';
import '../theme/app_themes.dart';

class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(6),
            gradient: LinearGradient(
              begin: Alignment(-1 + t * 3, 0),
              end: Alignment(0 + t * 3, 0),
              colors: [
                bt.surface2,
                bt.surface3,
                bt.surface2,
              ],
              stops: const [0.1, 0.5, 0.9],
            ),
          ),
        );
      },
    );
  }
}

/// Pre-built skeleton matching a typical list/card row — icon box + two
/// text lines. Use this directly for common cases (set cards, feed posts,
/// news cards) instead of hand-building the layout each time.
class SkeletonListRow extends StatelessWidget {
  final double iconSize;
  const SkeletonListRow({super.key, this.iconSize = 48});

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bt.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bt.cardBorder, width: 1.5),
      ),
      child: Row(children: [
        SkeletonBox(
          width: iconSize,
          height: iconSize,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: double.infinity, height: 14),
              const SizedBox(height: 8),
              SkeletonBox(width: 120, height: 10),
            ],
          ),
        ),
      ]),
    );
  }
}

/// A vertical stack of skeleton rows — drop this in wherever a list is
/// loading, instead of a centered spinner.
class SkeletonListLoader extends StatelessWidget {
  final int count;
  final double iconSize;
  const SkeletonListLoader({super.key, this.count = 5, this.iconSize = 48});

  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      count,
      (_) => SkeletonListRow(iconSize: iconSize),
    ),
  );
}
