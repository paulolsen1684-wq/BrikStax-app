// lib/widgets/atoms.dart — BrikStax Brick UI atoms
import 'package:flutter/material.dart';
import '../models/lego_set.dart';
import '../theme/app_theme.dart';
import '../theme/app_themes.dart';

// ── Bold bordered container ────────────────────────────────────────────────────
class BrikCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final BorderRadius? radius;

  const BrikCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.radius,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color ?? BT.white,
      borderRadius: radius ?? BorderRadius.circular(12),
      border: Border.all(color: BT.ink, width: BT.bw),
      boxShadow: BT.shadow,
    ),
    child: child,
  );
}

// ── Condition badge ────────────────────────────────────────────────────────────
class CondBadge extends StatelessWidget {
  final String status;
  final bool small;
  const CondBadge(this.status, {super.key, this.small = false});

  @override
  Widget build(BuildContext context) {
    final sealed = status == 'sealed';
    final color  = sealed ? BT.blue  : BT.green;
    final bg     = sealed ? BT.blueBg : BT.greenBg;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8, vertical: small ? 2 : 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color, width: 1.8),
      ),
      child: Text(
        sealed ? 'Sealed' : 'Open',
        style: BT.mono(size: small ? 8 : 9, color: color, weight: FontWeight.w500),
      ),
    );
  }
}

// ── Theme badge ────────────────────────────────────────────────────────────────
class ThemeBadge extends StatelessWidget {
  final String theme;
  final String? subtheme;
  final bool compact;
  const ThemeBadge({super.key, required this.theme, this.subtheme, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = themeColor(theme);
    final bg    = Color.alphaBlend(color.withOpacity(.12), Colors.white);
    final label = compact ? _short(theme)
        : subtheme != null ? '$theme · $subtheme' : theme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8, vertical: compact ? 2 : 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(.5), width: 1.8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
          style: BT.mono(size: compact ? 9 : 10, color: color, weight: FontWeight.w500),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  String _short(String t) {
    const map = {
      'Star Wars': 'SW', 'Harry Potter': 'HP', 'Jurassic World': 'JW',
      'Speed Champions': 'SC', 'Creator Expert': 'CE', 'Super Mario': 'SM',
      'Indiana Jones': 'IJ',
    };
    return map[t] ?? (t.length > 9 ? '${t.substring(0,8)}…' : t);
  }
}

// ── Open extras badge ──────────────────────────────────────────────────────────
class ExtrasBadge extends StatelessWidget {
  final OpenExtras extras;
  final bool compact;
  const ExtrasBadge(this.extras, {super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (!extras.hasAnything) {
      return _pill('No box/manual', BT.tx3, Colors.white);
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (extras.hasBox)
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: _pill('📦 Box', BT.green, BT.greenBg),
        ),
      if (extras.hasManual)
        _pill('📖 Manual', BT.blue, BT.blueBg),
    ]);
  }

  Widget _pill(String label, Color color, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(100),
      border: Border.all(color: color, width: 1.5),
    ),
    child: Text(label, style: BT.mono(size: 8, color: color, weight: FontWeight.w500)),
  );
}

// ── ROI badge ──────────────────────────────────────────────────────────────────
class RoiBadge extends StatelessWidget {
  final double roi;
  const RoiBadge(this.roi, {super.key});

  @override
  Widget build(BuildContext context) {
    final pos   = roi >= 0;
    final color = pos ? BT.green  : BT.red;
    final bg    = pos ? BT.greenBg : BT.redBg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1.8),
      ),
      child: Text(
        '${pos ? "+" : ""}${roi.toStringAsFixed(1)}%',
        style: BT.display(size: 15, color: color),
      ),
    );
  }
}

// ── Source badge ───────────────────────────────────────────────────────────────
class SourceBadge extends StatelessWidget {
  final PurchaseSource source;
  final bool compact;
  const SourceBadge({super.key, required this.source, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final isLego = source.earnsInsiderPoints;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 8, vertical: 2),
      decoration: BoxDecoration(
        color: isLego ? BT.yellowBg : BT.cream2,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isLego ? BT.yellow3 : BT.cream3, width: 1.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(source.emoji, style: TextStyle(fontSize: compact ? 10 : 13)),
        if (!compact) ...[
          const SizedBox(width: 4),
          Text(
            source == PurchaseSource.legoStore ? 'LEGO Store' : source.label,
            style: BT.mono(size: 9,
                color: isLego ? BT.gold : BT.tx3,
                weight: FontWeight.w500),
          ),
        ],
      ]),
    );
  }
}

// ── Price pair ─────────────────────────────────────────────────────────────────
class PricePair extends StatelessWidget {
  final String label;
  final double value;
  final Color?  color;
  const PricePair({super.key, required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('$label ', style: BT.mono(size: 9, color: BT.txMuted)),
      Text('\$${value.toStringAsFixed(0)}',
          style: BT.mono(size: 10, color: color ?? BT.tx, weight: FontWeight.w500)),
    ],
  );
}

// ── Section header ─────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    // Text on top of `primary` needs to flip per theme -- primary is dark
    // gold on a light card for Icons, but a light-ish blue/red/green fill
    // for several others, so a single fixed ink/white choice would go
    // low-contrast on some themes. Same threshold BT.isDark-adjacent code
    // elsewhere in the app uses.
    final onPrimary = ThemeData.estimateBrightnessForColor(bt.primary) ==
            Brightness.dark
        ? Colors.white
        : BT.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bt.surface,
        border: Border(
          top:    BorderSide(color: bt.cardBorder, width: BT.bw),
          bottom: BorderSide(color: bt.cardBorder, width: BT.bw),
        ),
      ),
      child: Row(children: [
        Text(title, style: BT.display(size: 20, color: bt.tx)),
        const Spacer(),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: bt.primary,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: bt.cardBorder, width: BT.bw),
                boxShadow: [BoxShadow(color: bt.shadowColor, offset: const Offset(2, 2))],
              ),
              child: Text(action!,
                  style: BT.mono(size: 9, color: onPrimary, weight: FontWeight.w500)),
            ),
          ),
      ]),
    );
  }
}

// ── Info row ───────────────────────────────────────────────────────────────────
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color?  valueColor;
  const InfoRow({super.key, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(children: [
      Text(label, style: BT.mono(size: 11, color: BT.tx2)),
      const Spacer(),
      Text(value, style: BT.mono(size: 12, color: valueColor ?? BT.tx, weight: FontWeight.w500)),
    ]),
  );
}

// ── Stat tile (dashboard) ──────────────────────────────────────────────────────
class StatTile extends StatelessWidget {
  final String   value;
  final String   label;
  final String?  sub;
  final Color    valueColor;
  final bool     last;

  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.sub,
    this.valueColor = BT.ink,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: BT.white,
        border: Border(
          right: last
              ? BorderSide.none
              : const BorderSide(color: BT.ink, width: BT.bw),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: BT.display(size: 22, color: valueColor)),
        const SizedBox(height: 2),
        Text(label, style: BT.mono(size: 8, color: BT.tx3)),
        if (sub != null)
          Text(sub!, style: BT.mono(size: 8, color: BT.tx3)),
      ]),
    ),
  );
}

// ── Filter chip ────────────────────────────────────────────────────────────────
class BrikChip extends StatelessWidget {
  final String   label;
  final bool     selected;
  final Color?   selectedColor;
  final VoidCallback onTap;

  const BrikChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = selectedColor ?? BT.ink;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:        selected ? c : BT.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? c : BT.ink, width: BT.bw),
          boxShadow: selected ? [] : BT.shadowSm,
        ),
        child: Text(
          label,
          style: BT.mono(
            size: 10,
            color: selected
                ? (c == BT.ink ? BT.yellow : BT.white)
                : BT.ink,
            weight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Bottom sheet handle ────────────────────────────────────────────────────────
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 40, height: 4,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: BT.cream3,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

// ── Divider with ink ───────────────────────────────────────────────────────────
class InkDivider extends StatelessWidget {
  const InkDivider({super.key});
  @override
  Widget build(BuildContext context) =>
      const Divider(color: BT.ink, thickness: BT.bw, height: 0);
}

// ── GWP / free badge ──────────────────────────────────────────────────────────
class GwpBadge extends StatelessWidget {
  const GwpBadge({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: BT.yellowBg,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: BT.yellow3, width: 1.8),
    ),
    child: Text('GWP', style: BT.display(size: 13, color: BT.gold)),
  );
}
