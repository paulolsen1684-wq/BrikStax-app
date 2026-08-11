// lib/modules/avatar/widgets/loot_roll_widget.dart
//
// NOTE: The popup card uses fixed light colors (BT.white / BT.ink) because it
// is always rendered over a Colors.black87 barrier. Only text secondary colors
// and the "Later" button are migrated to bt.* tokens.
import 'dart:math';
import 'package:flutter/material.dart';
import '../data/pixel_cosmetics.dart' as pixel;
import '../data/sprite_cosmetics.dart' as sprite;
import '../models/loot_roll.dart';
import '../services/achievement_service.dart';
import 'avatar_widget.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/brick_burst.dart';

/// Unifies a rolled reward's display info -- a roll can resolve to either
/// catalog now (sprite = background, pixel = head/hat/torso/legs/item), so
/// this carries whichever one matched rather than assuming sprite the way
/// it did back when the pixel catalog wasn't in the loot pool yet.
class _RewardInfo {
  final String name;
  final String description;
  final Color rarityColor;
  final String rarityLabel;
  // 0..1, common=0 through legendary=1 -- drives how elaborate the reveal
  // burst is (see BrickBurstOverlay below). Both SpriteRarity and
  // PixelRarity are the same 5-value {common, uncommon, rare, epic,
  // legendary} ordering, so rarity.index / 4.0 works generically for
  // either catalog without needing two separate scales.
  final double burstIntensity;
  final sprite.SpriteCosmetic? spriteCosmetic;
  final pixel.PixelCosmetic? pixelCosmetic;
  const _RewardInfo({
    required this.name,
    required this.description,
    required this.rarityColor,
    required this.rarityLabel,
    required this.burstIntensity,
    this.spriteCosmetic,
    this.pixelCosmetic,
  });

  static _RewardInfo? resolve(String id) {
    final sc = sprite.spriteCosmeticsById[id];
    if (sc != null) {
      return _RewardInfo(
        name: sc.name,
        // Backgrounds carry real hand-written flavor text; every other slot
        // synthesizes one since it never had a description field before.
        description: sc.description ?? '${sc.rarity.label} ${sc.slot.name}',
        rarityColor: sc.rarity.color,
        rarityLabel: sc.rarity.label,
        burstIntensity: sc.rarity.index / 4.0,
        spriteCosmetic: sc,
      );
    }
    final pc = pixel.pixelCosmeticsById[id];
    if (pc != null) {
      return _RewardInfo(
        name: pc.name,
        description: pc.description ?? '${pc.rarity.label} ${pc.slot.name}',
        rarityColor: pc.rarity.color,
        rarityLabel: pc.rarity.label,
        burstIntensity: pc.rarity.index / 4.0,
        pixelCosmetic: pc,
      );
    }
    return null;
  }
}

class LootRollWidget extends StatefulWidget {
  final LootRoll roll;
  final int  briksEarned;
  final bool wasDupe;
  final VoidCallback onDone;

  const LootRollWidget({
    super.key,
    required this.roll,
    required this.onDone,
    this.briksEarned = 0,
    this.wasDupe = false,
  });

  static Future<void> show(
    BuildContext context,
    LootRoll roll, {
    int  briksEarned = 0,
    bool wasDupe = false,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (_) => LootRollWidget(
        roll:         roll,
        briksEarned:  briksEarned,
        wasDupe:      wasDupe,
        onDone: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  State<LootRollWidget> createState() => _LootRollWidgetState();
}

class _LootRollWidgetState extends State<LootRollWidget>
    with TickerProviderStateMixin {
  late AnimationController _spinCtrl;
  late AnimationController _revealCtrl;
  late Animation<double>   _spin;
  late Animation<double>   _revealScale;
  late Animation<double>   _revealFade;

  bool _revealed   = false;
  int  _flashColor = 0;
  final _flashColors = [
    0xFFFFCB00, 0xFF2196F3, 0xFFE53935, 0xFF66BB6A, 0xFF9C27B0,
  ];

  static const double _avatarSize   = 108;
  static const double _stageHeight  = 184;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1800));
    _revealCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600));
    _spin = Tween<double>(begin: 0, end: 4 * pi).animate(
      CurvedAnimation(parent: _spinCtrl, curve: Curves.easeInOut),
    );
    _revealScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _revealCtrl, curve: Curves.elasticOut),
    );
    _revealFade =
        CurvedAnimation(parent: _revealCtrl, curve: Curves.easeIn);

    _spinCtrl.addListener(() {
      final idx =
          (_spinCtrl.value * 10).toInt() % _flashColors.length;
      if (idx != _flashColor) setState(() => _flashColor = idx);
    });

    _spinCtrl.forward().then((_) {
      setState(() => _revealed = true);
      _revealCtrl.forward();
    });
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _revealCtrl.dispose();
    super.dispose();
  }

  Color get _tierColor => switch (widget.roll.tier) {
    BrickTier.common => BT.yellow,
    BrickTier.rare   => const Color(0xFF006CB7),
    BrickTier.epic   => const Color(0xFF8B00FF),
  };

  String get _tierLabel => switch (widget.roll.tier) {
    BrickTier.common => 'Common Brick',
    BrickTier.rare   => 'Rare Brick',
    BrickTier.epic   => 'Epic Brick',
  };

  @override
  Widget build(BuildContext context) {
    final reward = _RewardInfo.resolve(widget.roll.cosmeticId);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
          horizontal: 28, vertical: 24),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
          decoration: BoxDecoration(
            // Fixed white — must pop against black87 barrier
            color: BT.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _tierColor, width: 3),
            boxShadow: [BoxShadow(
                color: _tierColor.withOpacity(.4),
                blurRadius: 0,
                offset: const Offset(4, 4))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: BT.ink,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(_tierLabel,
                  style: BT.display(size: 11, color: _tierColor)),
            ),
            const SizedBox(height: 14),

            SizedBox(
              height: _stageHeight,
              child: _revealed
                  ? _buildReveal(reward)
                  : _buildSpin(),
            ),

            const SizedBox(height: 14),

            if (_revealed && reward != null) ...[
              Text(reward.name,
                  style: BT.display(size: 22),
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: reward.rarityColor.withOpacity(.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: reward.rarityColor, width: 1),
                ),
                child: Text(reward.rarityLabel,
                    style: BT.mono(size: 9,
                        color: reward.rarityColor)),
              ),
              const SizedBox(height: 8),
              Text(reward.description,
                  style: BT.mono(size: 10, color: BT.tx3),
                  textAlign: TextAlign.center),

              if (widget.briksEarned > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: BT.yellowBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: BT.yellow3, width: BT.bw),
                  ),
                  child: Row(
                      mainAxisSize: MainAxisSize.min, children: [
                    const Text('🧱',
                        style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Text(
                      widget.wasDupe
                          ? '+${widget.briksEarned} Briks — already owned!'
                          : '+${widget.briksEarned} Brik earned',
                      style: BT.body(size: 12),
                    ),
                  ]),
                ),
              ],

              const SizedBox(height: 18),
              GestureDetector(
                onTap: widget.onDone,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _tierColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: BT.ink, width: BT.bw),
                    boxShadow: BT.shadowSm,
                  ),
                  child: Text('Collect!',
                      textAlign: TextAlign.center,
                      style: BT.body(size: 16)),
                ),
              ),
            ] else if (!_revealed) ...[
              Text('Rolling...',
                  style: BT.mono(size: 11, color: BT.tx3)),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _buildSpin() {
    return AnimatedBuilder(
      animation: _spin,
      builder: (_, __) {
        final color = Color(_flashColors[_flashColor]);
        return Center(
          child: Transform.rotate(
            angle: _spin.value,
            child: _PixelBrick(color: color, size: 100),
          ),
        );
      },
    );
  }

  Widget _buildReveal(_RewardInfo? reward) {
    if (reward == null) return const SizedBox();
    final state = AchievementService.instance.state;
    final sc = reward.spriteCosmetic;
    final pc = reward.pixelCosmetic;
    // Sprite side of the pool is backgrounds-only post-cutover, so any
    // sprite match here is a background. Pixel side can be any figure slot
    // -- equip into whichever field that slot maps to so the reveal
    // preview actually shows the item on the figure, not just unlocks it
    // invisibly.
    final previewState = sc != null
        ? (sc.slot == sprite.CosmeticSlot.background
            ? state.copyWith(backgroundId: sc.id)
            : state)
        : pc != null
            ? switch (pc.slot) {
                pixel.PixelSlot.head  => state.copyWith(headId: pc.id),
                pixel.PixelSlot.hat   => state.copyWith(hatId: pc.id),
                pixel.PixelSlot.torso => state.copyWith(torsoId: pc.id),
                pixel.PixelSlot.legs  => state.copyWith(legsId: pc.id),
                pixel.PixelSlot.item  => state.copyWith(itemId: pc.id),
              }
            : state;

    return Center(
      child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
        // Burst plays once behind the figure, scaled by the item's own
        // rarity (not the coarser common/rare/epic roll tier used for the
        // dialog border above) -- a common reveal gets a token flourish,
        // legendary gets the full show. Capped at 1.6x the avatar so it
        // stays inside the fixed _stageHeight (184) box rather than
        // visually overlapping the tier badge/text above and below it.
        SizedBox(
          width: _avatarSize * 1.6, height: _avatarSize * 1.6,
          child: BrickBurstOverlay(
            color: reward.rarityColor,
            intensity: reward.burstIntensity,
            duration: Duration(milliseconds: (700 + reward.burstIntensity * 500).round()),
          ),
        ),
        FadeTransition(
          opacity: _revealFade,
          child: ScaleTransition(
            scale: _revealScale,
            child: AvatarWidget(
              state: previewState,
              size: _avatarSize,
              animated: true,
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Pixel art LEGO brick (game element — fixed palette colors) ────────────────
class _PixelBrick extends StatelessWidget {
  final Color  color;
  final double size;
  const _PixelBrick({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(size, size * .75),
    painter: _BrickPainter(color: color),
  );
}

class _BrickPainter extends CustomPainter {
  final Color color;
  const _BrickPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p     = Paint()..style = PaintingStyle.fill;
    final w     = size.width;
    final h     = size.height;
    final dark  = HSLColor.fromColor(color)
        .withLightness(
            (HSLColor.fromColor(color).lightness - .2).clamp(0.0, 1.0))
        .toColor();
    final light = HSLColor.fromColor(color)
        .withLightness(
            (HSLColor.fromColor(color).lightness + .1).clamp(0.0, 1.0))
        .toColor();

    p.color = color;
    canvas.drawRect(Rect.fromLTWH(0, h * .25, w, h * .75), p);

    final topPath = Path()
      ..moveTo(0,      h * .25)
      ..lineTo(w * .5, 0)
      ..lineTo(w,      h * .25)
      ..lineTo(w * .5, h * .5)
      ..close();
    p.color = light;
    canvas.drawPath(topPath, p);

    p.color       = dark.withOpacity(.3);
    p.style       = PaintingStyle.stroke;
    p.strokeWidth = 1;
    for (double x = w * .25; x < w; x += w * .25) {
      canvas.drawLine(Offset(x, h * .25), Offset(x, h), p);
    }
    canvas.drawLine(Offset(0, h * .5), Offset(w, h * .5), p);
    p.style = PaintingStyle.fill;

    p.color = light;
    for (int i = 0; i < 3; i++) {
      final cx = w * .2 + i * w * .3;
      final cy = h * .22;
      canvas.drawOval(Rect.fromCenter(
          center: Offset(cx, cy),
          width: w * .18, height: h * .12), p);
      p.color = color;
      canvas.drawOval(Rect.fromCenter(
          center: Offset(cx, cy - h * .03),
          width: w * .12, height: h * .08), p);
      p.color = light;
    }

    p.color       = const Color(0xFF0A0907).withOpacity(.6);
    p.style       = PaintingStyle.stroke;
    p.strokeWidth = 2;
    canvas.drawRect(Rect.fromLTWH(0, h * .25, w, h * .75), p);
    p.strokeWidth = 1.5;
    canvas.drawPath(Path()
      ..moveTo(0,      h * .25)
      ..lineTo(w * .5, 0)
      ..lineTo(w,      h * .25)
      ..lineTo(w * .5, h * .5)
      ..close(), p);
  }

  @override
  bool shouldRepaint(covariant _BrickPainter old) => old.color != color;
}
