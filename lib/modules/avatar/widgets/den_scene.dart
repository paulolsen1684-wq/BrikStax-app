// lib/modules/avatar/widgets/den_scene.dart
//
// The Den's scene + showcase + trophy content, extracted out of
// brick_den.dart so it can be embedded both by the full-screen
// BrickDenScreen (brick_den.dart) and by the Avatar Editor's Den tab
// (avatar_editor.dart) without duplicating the painter/animation logic in
// two places. This widget owns its own animation controller and reads
// AchievementService/CollectionProvider directly, so any caller can just
// drop it in without wiring state through.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/collection.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_themes.dart';
import '../services/achievement_service.dart';
import 'avatar_widget.dart';
import '../data/backgrounds_art.dart' as bgArt;
import 'den_hud.dart';
import 'ground_accessory.dart';
import '../../../services/den_screenshot_service.dart';
import '../../../services/widget_service.dart';

// ── Trophy families ───────────────────────────────────────────────────────────
class _TrophyFamily {
  final String name, emoji, bronzeId, silverId, goldId;
  final String bronzeHint, silverHint, goldHint;
  const _TrophyFamily(this.name, this.emoji,
      this.bronzeId, this.bronzeHint,
      this.silverId, this.silverHint,
      this.goldId,   this.goldHint);
}

const _families = [
  _TrophyFamily('Collection', '📦',
      'sets_10', '10 sets', 'sets_50', '50 sets',
      'legendary_sets', '250 sets'),
  _TrophyFamily('Sealed Vault', '🔒',
      'sealed_5', '5 sealed', 'sealed_10', '10 sealed',
      'sealed_25', '25 sealed'),
  _TrophyFamily('Portfolio', '💰',
      'value_1k', r'$1K value', 'value_10k', r'$10K value',
      'legendary_portfolio', r'$50K value'),
  _TrophyFamily('ROI Master', '📈',
      'roi_50', '50% ROI set', 'roi_200', '200% ROI set',
      'roi_500', '500% ROI set'),
];

const _badges = [
  ('theme_starwars', 'Galactic', Color(0xFF4A6A8E)),
  ('theme_ucs',      'UCS',      Color(0xFF8B00FF)),
  ('theme_icons',    'Icons',    Color(0xFF2E7D32)),
  ('theme_technic',  'Technic',  Color(0xFFCC2200)),
];

enum _Tier { none, bronze, silver, gold }

_Tier _tierOf(_TrophyFamily f, Set<String> earned) {
  if (earned.contains(f.goldId))   return _Tier.gold;
  if (earned.contains(f.silverId)) return _Tier.silver;
  if (earned.contains(f.bronzeId)) return _Tier.bronze;
  return _Tier.none;
}

Color _tierColor(_Tier t) => switch (t) {
  _Tier.bronze => const Color(0xFFCD7F32),
  _Tier.silver => const Color(0xFFC0C0C0),
  _Tier.gold   => const Color(0xFFFFD700),
  _Tier.none   => const Color(0xFF3A3A3A),
};

String _tierLabel(_Tier t) => switch (t) {
  _Tier.bronze => 'Bronze',
  _Tier.silver => 'Silver',
  _Tier.gold   => 'Gold',
  _Tier.none   => 'Locked',
};

// Redesigned BACKGROUND slot (15 items) — palette now sourced from
// backgrounds_art.dart so the avatar circle and this Den wall never drift
// out of sync with each other.
(Color, Color, Color) _denPalette(String? bgId) {
  final p = bgArt.bgPalettes[bgId] ?? bgArt.bgPalettes['bg_cream']!;
  return (p.denWall, p.denFloor, p.accent);
}

// The Den renders a ground-placed accessory itself (positioned against the
// shelf/table in the background art) rather than through
// SpriteAvatarWidget's own avatar-relative box -- see the Positioned in
// build() below. Lookup + positioning shared with den_share_screen.dart
// via ground_accessory.dart so the two can't drift out of sync.

Color _themeBoxColor(String? theme) {
  final t = (theme ?? '').toLowerCase();
  if (t.contains('star wars')) return const Color(0xFF4A6A8E);
  if (t.contains('technic'))   return const Color(0xFFCC2200);
  if (t.contains('city'))      return const Color(0xFF1565C0);
  if (t.contains('icons'))     return const Color(0xFF2E7D32);
  if (t.contains('creator'))   return const Color(0xFF8D6E63);
  if (t.contains('harry') || t.contains('castle')) return const Color(0xFF8E24AA);
  if (t.contains('ninja'))     return const Color(0xFF455A64);
  return const Color(0xFFE65100);
}

// ── Scene content ────────────────────────────────────────────────────────────
class DenSceneContent extends StatefulWidget {
  const DenSceneContent({super.key});
  @override State<DenSceneContent> createState() => _DenSceneContentState();
}

class _DenSceneContentState extends State<DenSceneContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  int _frame = 0;
  // Tracks DenLayoutTuning.generation so DenLayoutTunerScreen's live drag/
  // pinch edits show up promptly -- this ticker already fires every frame
  // for the badge/trophy shimmer below, so piggybacking one more int
  // comparison on it is free, and means the tuner doesn't need its own
  // separate rebuild mechanism for a widget that reads AchievementService/
  // CollectionProvider directly rather than accepting props.
  int _lastSeenTuningGen = DenLayoutTuning.generation;

  // Screenshot capture for the home-screen widget. Was previously only
  // wired up in brick_den.dart's BrickDenScreen, which meant opening the
  // Den via avatar_editor.dart's Den tab instead (an equally common path,
  // and the same live scene) never captured anything -- the widget was
  // stuck on its generic fallback for anyone who never happened to visit
  // BrickDenScreen specifically. Living here instead means BOTH embeddings
  // trigger it for free, since this is the one widget they both wrap.
  final _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1800))
      ..addListener(_onTick)
      ..repeat();
    DenScreenshotService.instance.registerDenKey(_repaintKey);
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureForWidget());
  }

  Future<void> _captureForWidget() async {
    final path = await DenScreenshotService.instance.captureDen();
    if (path != null) await WidgetService.instance.updateDenWidget();
  }

  void _onTick() {
    var changed = false;
    final f = (_ctrl.value * 4).floor() % 4;
    if (f != _frame) { _frame = f; changed = true; }

    if (DenLayoutTuning.generation != _lastSeenTuningGen) {
      _lastSeenTuningGen = DenLayoutTuning.generation;
      changed = true;
    }

    if (changed) setState(() {});
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final bt    = context.bt;
    final svc   = AchievementService.instance;
    final col   = context.watch<CollectionProvider>();
    final width = MediaQuery.of(context).size.width;

    final pxd        = (width / 72).floorToDouble();
    final sceneW     = pxd * 72;
    final sceneH     = pxd * 48;
    // Base size/position formula (before DenLayoutTuning overrides) lives
    // in ground_accessory.dart's denAvatarRect() now, shared with
    // den_share_screen.dart so the two can't drift apart -- see its doc
    // comment for the row-43-grounding rationale.
    final avatarRect = denAvatarRect(pxd);

    return ListenableBuilder(
      listenable: svc,
      builder: (_, __) {
        final state  = svc.state;
        final earned = state.earnedIds;

        final sorted = [...col.sets]
          ..sort((a, b) => ((b.ebayAvg ?? 0) as num)
              .compareTo((a.ebayAvg ?? 0) as num));
        final top3 = sorted.take(3).toList();

        return SingleChildScrollView(child: Column(children: [

          // ── The room (pixel art — always dark) ──────────────────
          // RepaintBoundary scoped to exactly this box now, not the whole
          // scrollable page below (fixed 2026-08-16, real bug: the Den
          // widget showed a cropped/incomplete den). DenScreenshotService
          // .captureDen() calls toImage() on whatever RenderRepaintBoundary
          // this key resolves to -- a boundary wrapping a
          // SingleChildScrollView gets its SIZE from the scroll view's
          // VIEWPORT, not the room's actual sceneW x sceneH, so the
          // captured image was whatever happened to be visible on screen
          // at capture time: cropped short if the room didn't fully fit
          // the viewport (e.g. the Avatar Editor's more cramped Den tab,
          // header+preview+tabbar eating into the available height), or
          // padded with unrelated trophy-card content otherwise -- never
          // reliably "the whole den" either way. Scoping the boundary to
          // this fixed-size box guarantees the capture is always exactly
          // the complete room, regardless of scroll position or which
          // screen embeds DenSceneContent.
          RepaintBoundary(key: _repaintKey, child: Center(child: SizedBox(
            width: sceneW, height: sceneH,
            child: Stack(children: [
              if (bgArt.denImageAsset(state.backgroundId) case final asset?)
                Positioned.fill(
                  child: Image.asset(asset, fit: BoxFit.cover),
                ),
              CustomPaint(
                size: Size(sceneW, sceneH),
                painter: _DenPainter(
                  bgId:       state.backgroundId,
                  earned:     earned,
                  top3Colors: top3
                      .map((s) => _themeBoxColor(s.theme))
                      .toList(),
                  frame: _frame,
                ),
              ),
              Positioned(
                left: avatarRect.left,
                top:  avatarRect.top,
                child: AvatarWidget(
                  state:               state,
                  size:                avatarRect.size,
                  animated:            true,
                  showBackground:      false,
                  // A ground accessory renders separately below,
                  // positioned against the shelf/table in the
                  // background art rather than relative to the
                  // figure's own box -- "beside the figure" and "in
                  // front of the cabinet" are different places.
                  showGroundAccessory: false,
                ),
              ),
              if (groundAccessoryOf(state) case final acc?)
                groundAccessoryWidget(accessory: acc, pxd: pxd),
              ...denHudWidgets(pxd: pxd, earned: earned),
            ]),
          ))),

          // Showcase labels
          if (top3.isNotEmpty)
            Container(
              width: double.infinity,
              color: BT.ink,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: top3.map((s) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: width * .22,
                        child: Text(s.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: BT.mono(size: 8,
                                color: Colors.white)),
                      ),
                      Text(
                        '\$${((s.ebayAvg ?? 0) as num).toStringAsFixed(0)}',
                        style: BT.mono(size: 9, color: BT.yellow)),
                    ],
                  ),
                )).toList(),
              ),
            ),

          const SizedBox(height: 14),

          // ── Trophy cards ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TROPHIES',
                    style: BT.mono(size: 9, color: bt.tx3)),
                const SizedBox(height: 8),

                ..._families.map((f) {
                  final tier  = _tierOf(f, earned);
                  final color = _tierColor(tier);
                  final next  = switch (tier) {
                    _Tier.none   =>
                        'Next: ${f.bronzeHint} → Bronze',
                    _Tier.bronze =>
                        'Next: ${f.silverHint} → Silver',
                    _Tier.silver =>
                        'Next: ${f.goldHint} → Gold',
                    _Tier.gold => 'Maxed out!',
                  };
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tier == _Tier.none
                          ? bt.surface2 : bt.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: tier == _Tier.none
                            ? bt.cardBorder : color,
                        width: tier == _Tier.gold ? 2.5 : BT.bw,
                      ),
                      boxShadow: tier == _Tier.gold
                          ? [BoxShadow(
                              color: color.withOpacity(.4),
                              offset: const Offset(3, 3))]
                          : [],
                    ),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: color.withOpacity(
                              tier == _Tier.none ? .15 : .2),
                          borderRadius:
                              BorderRadius.circular(10),
                          border: Border.all(
                              color: color, width: 2),
                        ),
                        child: Center(child: Text(
                            tier == _Tier.none ? '🔒' : '🏆',
                            style: const TextStyle(
                                fontSize: 18))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text('${f.emoji} ${f.name}',
                              style: BT.body(size: 14, color: bt.tx)),
                          Text(next,
                              style: BT.mono(size: 9, color: bt.tx3)),
                        ],
                      )),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: color.withOpacity(
                              tier == _Tier.none ? .1 : .18),
                          borderRadius:
                              BorderRadius.circular(8),
                          border: Border.all(
                              color: color, width: 1.5),
                        ),
                        child: Text(_tierLabel(tier),
                            style: BT.mono(size: 9,
                                color: tier == _Tier.none
                                    ? bt.txMuted : BT.ink)),
                      ),
                    ]),
                  );
                }),

                const SizedBox(height: 8),
                Text('THEME BADGES',
                    style: BT.mono(size: 9, color: bt.tx3)),
                const SizedBox(height: 8),
                Row(children: _badges.map((b) {
                  final got = earned.contains(b.$1);
                  return Expanded(child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10),
                    decoration: BoxDecoration(
                      color: got
                          ? b.$3.withOpacity(.12)
                          : bt.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: got ? b.$3 : bt.cardBorder,
                          width: BT.bw),
                    ),
                    child: Column(children: [
                      Text(got ? '🛡️' : '🔒',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 3),
                      Text(b.$2,
                          style: BT.mono(size: 7,
                              color: got ? bt.tx : bt.txMuted)),
                    ]),
                  ));
                }).toList()),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ]));
      },
    );
  }
}

// ── Room painter (pixel art — colors are palette-driven, not theme tokens) ────
class _DenPainter extends CustomPainter {
  final String?     bgId;
  final Set<String> earned;
  final List<Color> top3Colors;
  final int         frame;
  const _DenPainter({
    required this.bgId,
    required this.earned,
    required this.top3Colors,
    required this.frame,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const cols = 72;
    final px = (size.width / cols).floorToDouble();
    final p  = Paint()..style = PaintingStyle.fill;

    void dot(int gx, int gy, Color c) {
      p.color = c;
      canvas.drawRect(
          Rect.fromLTWH(gx * px, gy * px, px - 0.3, px - 0.3), p);
    }
    void block(int x0, int x1, int y0, int y1, Color c) {
      for (int y = y0; y <= y1; y++) {
        for (int x = x0; x <= x1; x++) dot(x, y, c);
      }
    }
    void solid(int x0, int x1, int y0, int y1, Color c) {
      p.color = c;
      canvas.drawRect(Rect.fromLTWH(
          x0 * px, y0 * px,
          (x1 - x0 + 1) * px, (y1 - y0 + 1) * px), p);
    }

    final (wall, floor, accent) = _denPalette(bgId);
    final wallD  = Color.lerp(wall, Colors.black, .3)!;
    final wallL  = Color.lerp(wall, Colors.white, .08)!;
    final floorD = Color.lerp(floor, Colors.black, .3)!;

    // A real generated scene (Image.asset, painted just behind this canvas)
    // already supplies the wall/floor/window/theme-decor art, so skip the
    // matching procedural strokes here — only the dynamic HUD (badges,
    // trophy shelf, showcase, diamond) still needs to be drawn on top.
    final hasImage = bgArt.denImageAsset(bgId) != null;

    if (!hasImage) {
      solid(0, 71, 0, 35, wall);
      solid(0, 71, 36, 47, floor);
      solid(0, 71, 36, 36, wallD);
      for (int x = 4; x < 72; x += 10) {
        dot(x, 40, floorD); dot(x + 5, 44, floorD);
      }

      _drawThemeWall(dot, block, accent, wallD, wallL);

      block(35, 35, 0, 2, wallD);
      block(33, 37, 3, 4, accent);
    }
    if (!hasImage && frame % 2 == 0) {
      dot(32, 5, accent.withOpacity(.35));
      dot(38, 5, accent.withOpacity(.35));
      dot(35, 5, accent.withOpacity(.5));
    }

    // Badges, trophy shelf + trophies, and the legendary_all diamond used
    // to draw here as blocky pixel-grid shapes -- moved to real images
    // rendered as Positioned widgets (see denHudWidgets in den_hud.dart,
    // spliced into this scene's Stack in DenSceneContent.build()) since
    // those elements draw regardless of hasImage and the old flat-color
    // version looked increasingly out of place next to real photo Den art.

    // The showcase boxes themselves (not just their pedestal) are skipped
    // entirely once hasImage -- they're flat procedural cubes that read as
    // leftover debug boxes against real photo art no matter what's done to
    // the pedestal or highlight around them (feedback across multiple
    // rounds kept landing back on the boxes themselves, not just their
    // base). They're also redundant once hasImage: the text label bar
    // below the scene (name + price per top-3 set) already shows the same
    // information cleanly, so nothing is lost by not drawing these in the
    // scene too.
    for (int i = 0; i < 3 && !hasImage; i++) {
      final hasItem = i < top3Colors.length;
      final x0 = 44 + i * 9;
      solid(x0, x0 + 4, 39, 44, floorD);
      solid(x0, x0 + 4, 39, 39,
          Color.lerp(floorD, Colors.white, .14)!);
      if (hasItem) {
        final c = top3Colors[i];
        block(x0, x0 + 4, 33, 38, c);
        block(x0, x0 + 4, 33, 33,
            Color.lerp(c, Colors.white, .35)!);
        dot(x0 + 1, 35, Color.lerp(c, Colors.white, .2)!);
      } else {
        dot(x0 + 2, 37, wallD);
      }
    }

    // Painted floor rug + dash texture -- against a flat procedural floor
    // this read as a rug; against real photo art it reads as a row of
    // disconnected boxes floating on the floor, so it's skipped there like
    // every other flat-color placeholder in this file once hasImage.
    if (!hasImage) {
      solid(3, 26, 44, 46, Color.lerp(floor, accent, .16)!);
      for (int x = 5; x < 26; x += 4) {
        dot(x, 45, accent.withOpacity(.3));
      }
    }
  }

  void _drawThemeWall(
      void Function(int, int, Color) dot,
      void Function(int, int, int, int, Color) block,
      Color accent, Color wallD, Color wallL) {
    // Redesigned BACKGROUND slot (15 items) — scene props now live in
    // backgrounds_art.dart so the avatar circle and this Den wall share
    // one source of truth per background id.
    bgArt.drawDenSceneDetails(dot, bgId, frame);
  }


  @override
  bool shouldRepaint(covariant _DenPainter old) =>
      old.frame != frame ||
      old.bgId != bgId ||
      old.earned.length != earned.length ||
      old.top3Colors.length != top3Colors.length;
}
