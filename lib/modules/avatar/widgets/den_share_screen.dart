// lib/modules/avatar/widgets/den_share_screen.dart
//
// Share your den as an image. Rebuilds the den scene (room + minifig) at a
// fixed share size, with an A/B/C toggle for how much of your collection shows:
//   A — clean (scene + watermark)
//   B — + stats (sets / sealed / market + theme chips)
//   C — + trophies (tier badges too)
//
// Self-contained: includes its own copy of the den painter so it does NOT
// depend on brick_den.dart internals. Captures via RepaintBoundary and shares
// with share_plus (XFile.fromData — no path_provider needed).

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/avatar_state.dart';
import '../services/achievement_service.dart';
import '../../../providers/collection.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/share/photo_backdrop.dart';
import '../../../widgets/share/brand_mark.dart';
import 'avatar_widget.dart';
import '../data/backgrounds_art.dart' as bgArt;
import 'den_hud.dart';
import 'ground_accessory.dart';

enum DenShareMode { clean, stats, trophies }

class DenShareScreen extends StatefulWidget {
  const DenShareScreen({super.key});
  @override State<DenShareScreen> createState() => _State();
}

class _State extends State<DenShareScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  DenShareMode _mode = DenShareMode.stats;
  File? _photo;
  ShareFormat _format = ShareFormat.story;
  bool _sharing = false;

  Future<void> _pickPhoto() async {
    final photo = await pickBackdropPhoto(context, format: _format);
    if (photo != null) setState(() => _photo = photo);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Warm the den background art so it's already decoded by the time the
    // user taps Share — RenderRepaintBoundary.toImage() only captures
    // whatever has been painted so far, and Image.asset paints nothing on
    // its first frame while the asset bundle load is in flight.
    final asset = bgArt.denImageAsset(AchievementService.instance.state.backgroundId);
    if (asset != null) precacheImage(AssetImage(asset), context);
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    bool ok = false;
    try {
      final ro = _boundaryKey.currentContext?.findRenderObject();
      if (ro is RenderRepaintBoundary) {
        if (ro.debugNeedsPaint) {
          await Future.delayed(const Duration(milliseconds: 40));
        }
        final image = await ro.toImage(pixelRatio: 3.0);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes != null) {
          final png = bytes.buffer.asUint8List();
          final file = XFile.fromData(png,
              mimeType: 'image/png', name: 'brikstax_den.png');
          await Share.shareXFiles([file],
              text: 'My LEGO den, tracked with BrikStax 🧱');
          ok = true;
        }
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _sharing = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Couldn\'t create the image — try again'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = AchievementService.instance;
    final col = context.watch<CollectionProvider>();
    final state = svc.state;
    final earned = state.earnedIds;

    final sorted = [...col.sets]
      ..sort((a, b) => ((b.ebayAvg ?? 0) as num)
          .compareTo((a.ebayAvg ?? 0) as num));
    final top3 = sorted.take(3).toList();
    final top3Colors = top3.map((s) => _themeBoxColor(s.theme)).toList();

    return Scaffold(
      backgroundColor: BT.cream,
      body: Column(children: [
        // Header
        Container(
          decoration: const BoxDecoration(
            color: BT.cream,
            border: Border(bottom: BorderSide(color: BT.ink, width: BT.bw)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: BT.white,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: BT.ink, width: BT.bw),
                      boxShadow: BT.shadowSm,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: BT.ink, size: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Share your den', style: BT.display(size: 24)),
              ]),
            ),
          ),
        ),

        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            // A/B/C toggle
            _ModeToggle(mode: _mode, onChanged: (m) => setState(() => _mode = m)),
            const SizedBox(height: 10),

            // Optional photo backdrop -- turns the card into a sticker over
            // your own photo instead of its plain themed background, same
            // helper set_share_screen.dart/collection_share_screen.dart use.
            Row(children: [
              Expanded(child: _PhotoPill(
                icon: _photo == null ? Icons.add_a_photo_outlined : Icons.sync_outlined,
                label: _photo == null ? 'Add a photo' : 'Change photo',
                onTap: _pickPhoto,
              )),
              if (_photo != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _photo = null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: BT.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: BT.ink, width: BT.bw),
                    ),
                    child: const Icon(Icons.close, size: 15, color: BT.ink),
                  ),
                ),
              ],
            ]),
            const SizedBox(height: 12),

            FormatToggle(format: _format, onChanged: (f) => setState(() => _format = f)),
            const SizedBox(height: 16),

            // Capturable card. FittedBox scales the card down to fit the
            // screen in the PREVIEW, but the RepaintBoundary still captures
            // at full resolution.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: RepaintBoundary(
                key: _boundaryKey,
                child: _photo == null
                    ? FixedRatioCanvas(
                        format: _format,
                        card: _ShareCard(
                          state: state,
                          earned: earned,
                          top3: top3,
                          top3Colors: top3Colors,
                          mode: _mode,
                          sets: col.count,
                          sealed: col.sealedCount,
                          market: col.totalMarket,
                          byTheme: col.byTheme,
                        ),
                      )
                    : PhotoBackdropCard(
                        photo: _photo,
                        format: _format,
                        // Robinhood-style: just floating typography, no card
                        // background of its own -- genuinely needs the scrim
                        // (PhotoBackdropCard's default) for legibility.
                        card: _DenMinimalSticker(earnedCount: earned.length),
                      ),
              ),
            ),

            const SizedBox(height: 12),
            Text('This image will be shared. Your stats update automatically.',
                style: BT.mono(size: 9, color: BT.tx3),
                textAlign: TextAlign.center),
          ]),
        )),

        // Share button
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
            child: GestureDetector(
              onTap: _sharing ? null : _share,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: BT.yellow,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: BT.ink, width: BT.bw),
                  boxShadow: BT.shadow,
                ),
                child: _sharing
                    ? const Center(child: SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(BT.ink))))
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.ios_share, color: BT.ink, size: 20),
                        const SizedBox(width: 8),
                        Text('Share my den',
                            style: BT.body(size: 16, color: BT.ink)),
                      ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Photo backdrop pill ─────────────────────────────────────────────────────
class _PhotoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PhotoPill({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: BT.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BT.ink, width: BT.bw),
        boxShadow: BT.shadowSm,
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 15, color: BT.ink),
        const SizedBox(width: 6),
        Text(label, style: BT.mono(size: 10, color: BT.ink)),
      ]),
    ),
  );
}

// ── Photo-backdrop sticker: Robinhood-style minimal ──────────────────────────
// No card background, no border -- just typography floating on the photo,
// relying on PhotoBackdropCard's own scrim for legibility (unlike Set's slab
// or Collection's glass panel, which supply their own contrast). The Den has
// no $ or ROI to headline, so the trophy count fills the same "one big
// number" role instead.
class _DenMinimalSticker extends StatelessWidget {
  final int earnedCount;
  const _DenMinimalSticker({required this.earnedCount});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // No logo mark up here -- the standardized footer below already
      // carries the icon + "Made with BrikStax", so this stays plain text
      // to avoid showing the mark twice in one small sticker.
      Text('MY DEN', style: BT.mono(size: 9, color: Colors.white.withOpacity(.8))),
      const SizedBox(height: 2),
      Text('$earnedCount', style: BT.display(size: 44, color: BT.yellow)),
      Text('TROPHIES EARNED',
          style: BT.mono(size: 9, color: Colors.white.withOpacity(.75))),
      const SizedBox(height: 10),
      MadeWithBrikStax(textColor: Colors.white.withOpacity(.75), iconSize: 12),
    ],
  );
}

// ── A/B/C toggle ──────────────────────────────────────────────────────────────
class _ModeToggle extends StatelessWidget {
  final DenShareMode mode;
  final ValueChanged<DenShareMode> onChanged;
  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget seg(DenShareMode m, String label) {
      final on = mode == m;
      return Expanded(child: GestureDetector(
        onTap: () => onChanged(m),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: on ? BT.yellow : BT.white,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: BT.ink, width: BT.bw),
            boxShadow: on ? null : BT.shadowSm,
          ),
          child: Text(label, textAlign: TextAlign.center,
              style: BT.mono(size: 10, color: BT.ink)),
        ),
      ));
    }
    return Row(children: [
      seg(DenShareMode.clean, 'Clean'),
      const SizedBox(width: 8),
      seg(DenShareMode.stats, '+ Stats'),
      const SizedBox(width: 8),
      seg(DenShareMode.trophies, '+ Trophies'),
    ]);
  }
}

// ── The composed share card ───────────────────────────────────────────────────
class _ShareCard extends StatelessWidget {
  final AvatarState state;
  final Set<String> earned;
  final List<dynamic> top3;
  final List<Color> top3Colors;
  final DenShareMode mode;
  final int sets, sealed;
  final double market;
  final Map<String, int> byTheme;
  const _ShareCard({
    required this.state,
    required this.earned,
    required this.top3,
    required this.top3Colors,
    required this.mode,
    required this.sets,
    required this.sealed,
    required this.market,
    required this.byTheme,
  });

  static String _fmt(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    // Fixed CARD width so the captured image is consistent. The scene fills
    // this exact width (no gutter), and the avatar is positioned by ratios so
    // it can't overflow. ClipRect guarantees nothing spills out of the scene.
    const double cardW = 504;        // card == scene width, always
    const double sceneW = cardW;
    final double pxd = sceneW / 72;  // exact pixel size (no flooring drift)
    final double sceneH = pxd * 48;  // keep the 72x48 room ratio

    // Avatar: left-anchored at the same grid coordinates as den_scene.dart's
    // scene (was centered here, which didn't match -- the two screens need
    // to agree on where the avatar sits since backgrounds reserve a clear
    // strip for it on one side, not down the middle). Formula now lives in
    // ground_accessory.dart's denAvatarRect(), shared with den_scene.dart so
    // the two can't drift apart.
    final avatarRect = denAvatarRect(pxd);

    final themes = byTheme.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topThemes = themes.take(3).toList();

    return SizedBox(
      width: cardW,
      child: Container(
        decoration: BoxDecoration(
          color: BT.cream,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BT.ink, width: BT.bw),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Header
          Container(
            width: double.infinity,
            color: BT.yellow,
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 11),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const BrikStaxMark(size: 28),
              const SizedBox(height: 4),
              Text('MY DEN', style: BT.mono(size: 10, color: BT.ink.withOpacity(.6))),
            ]),
          ),

          // The den scene — ClipRect prevents ANY overflow past the scene box
          ClipRect(
            child: SizedBox(
              width: sceneW,
              height: sceneH,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  if (bgArt.denImageAsset(state.backgroundId) case final asset?)
                    Positioned.fill(
                      child: Image.asset(asset, fit: BoxFit.cover),
                    ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: DenPainter(
                        bgId: state.backgroundId,
                        earned: earned,
                        top3Colors: top3Colors,
                        frame: 0,
                      ),
                    ),
                  ),
                  Positioned(
                    left: avatarRect.left,
                    top: avatarRect.top,
                    child: AvatarWidget(
                      state: state,
                      size: avatarRect.size,
                      animated: false,
                      showBackground: false,
                      // Rendered as its own layer below instead -- see
                      // brick_den.dart's matching comment.
                      showGroundAccessory: false,
                    ),
                  ),
                  if (groundAccessoryOf(state) case final acc?)
                    // Static frame 0 (default) since this is a captured
                    // snapshot, not a live animated view -- shared with
                    // den_scene.dart via ground_accessory.dart.
                    groundAccessoryWidget(accessory: acc, pxd: pxd),
                  ...denHudWidgets(pxd: pxd, earned: earned),
                ],
              ),
            ),
          ),

        // ── Stats (B + C) ──────────────────────────────────────────────
        if (mode != DenShareMode.clean) ...[
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            decoration: BoxDecoration(
              color: BT.white,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: BT.ink, width: BT.bw),
            ),
            child: Row(children: [
              _stat(sets.toString(), 'SETS'),
              _divider(),
              _stat(sealed.toString(), 'SEALED'),
              _divider(),
              _stat(market > 0 ? '\$${_fmt(market)}' : '—', 'MARKET',
                  color: BT.green),
            ]),
          ),
        ],

        // ── Trophies (C only) ──────────────────────────────────────────
        if (mode == DenShareMode.trophies) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Column(children: _denTopTrophies(earned).map((t) =>
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: BT.white,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: BT.ink, width: 1.5),
                ),
                child: Row(children: [
                  const Text('🏆', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(t.$1, style: BT.body(size: 12))),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: t.$3.withOpacity(.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: t.$3, width: 1.5),
                    ),
                    child: Text(t.$2, style: BT.mono(size: 8, color: BT.ink)),
                  ),
                ]),
              ),
            ).toList()),
          ),
        ],

        // ── Theme chips (B + C) ────────────────────────────────────────
        if (mode != DenShareMode.clean && topThemes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Wrap(
              spacing: 7, runSpacing: 7, alignment: WrapAlignment.center,
              children: topThemes.map((e) {
                final label = e.key.split(' > ').first;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: BT.yellowBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: BT.ink, width: 1.5),
                  ),
                  child: Text('$label · ${e.value}',
                      style: BT.mono(size: 9, color: BT.ink)),
                );
              }).toList(),
            ),
          ),

        // Footer / watermark
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Center(child: MadeWithBrikStax()),
        ),
        ]),
      ),
    );
  }

  Widget _stat(String value, String label, {Color? color}) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
      child: Column(children: [
        Text(value, style: BT.display(size: 19, color: color ?? BT.ink),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 1),
        Text(label, style: BT.mono(size: 8, color: BT.tx3)),
      ]),
    ),
  );

  Widget _divider() => Container(width: BT.bw, height: 42, color: BT.ink);
}

// ── Trophy tiers (ported, minimal) ────────────────────────────────────────────
// Returns up to 3 earned trophies as (label, tierLabel, color).
List<(String, String, Color)> _denTopTrophies(Set<String> earned) {
  const fams = [
    ('📦 Collection', 'sets_10', 'sets_50', 'legendary_sets'),
    ('🔒 Sealed Vault', 'sealed_5', 'sealed_10', 'sealed_25'),
    ('💰 Portfolio', 'value_1k', 'value_10k', 'legendary_portfolio'),
    ('📈 ROI Master', 'roi_50', 'roi_200', 'roi_500'),
  ];
  const bronze = Color(0xFFCD7F32);
  const silver = Color(0xFFC0C0C0);
  const gold   = Color(0xFFFFD700);

  final out = <(String, String, Color)>[];
  for (final f in fams) {
    if (earned.contains(f.$4)) {
      out.add((f.$1, 'Gold', gold));
    } else if (earned.contains(f.$3)) {
      out.add((f.$1, 'Silver', silver));
    } else if (earned.contains(f.$2)) {
      out.add((f.$1, 'Bronze', bronze));
    }
  }
  return out.take(3).toList();
}

// ── Theme box color (ported from brick_den) ───────────────────────────────────
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

// ── Den palette ──────────────────────────────────────────────────────────────
// Reads bgArt.bgPalettes directly now, matching den_scene.dart's own
// implementation exactly, instead of a hand-ported hardcoded switch. That
// switch had drifted onto ids from an earlier, retired background catalog
// (bg_twinsuns/bg_stardust/bg_neoncity/bg_tallgrass/bg_dojo/bg_space/
// bg_yellow/bg_shelf/bg_podium -- none of which exist in the current
// 52-entry catalog), so every real current id except bg_skyline/bg_volcano
// fell through to one generic fallback color. Invisible for 48 of 52
// backgrounds (hasImage skips painting these colors entirely once real
// photo art exists), but for the 4 procedural-only ids that still need
// this -- bg_workbench/bg_snowfield/bg_maproom/bg_shadowrealm -- it meant
// the shared Den image rendered the wrong wall/floor colors compared to
// what's actually shown live in the Den, which already read the real map.
(Color, Color, Color) _denPalette(String? bgId) {
  final p = bgArt.bgPalettes[bgId] ?? bgArt.bgPalettes['bg_cream']!;
  return (p.denWall, p.denFloor, p.accent);
}

// ── Public den painter (self-contained port of _DenPainter) ───────────────────
class DenPainter extends CustomPainter {
  final String?     bgId;
  final Set<String> earned;
  final List<Color> top3Colors;
  final int         frame;
  const DenPainter({
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
      canvas.drawRect(Rect.fromLTWH(gx * px, gy * px, px - 0.3, px - 0.3), p);
    }
    void block(int x0, int x1, int y0, int y1, Color c) {
      for (int y = y0; y <= y1; y++) {
        for (int x = x0; x <= x1; x++) dot(x, y, c);
      }
    }
    void solid(int x0, int x1, int y0, int y1, Color c) {
      p.color = c;
      canvas.drawRect(Rect.fromLTWH(
          x0 * px, y0 * px, (x1 - x0 + 1) * px, (y1 - y0 + 1) * px), p);
    }

    final (wall, floor, accent) = _denPalette(bgId);
    final wallD  = Color.lerp(wall, Colors.black, .3)!;
    final wallL  = Color.lerp(wall, Colors.white, .08)!;
    final floorD = Color.lerp(floor, Colors.black, .3)!;

    // A real generated scene (Image.asset, painted just behind this canvas)
    // already supplies the wall/floor/window/theme-decor art — skip the
    // matching procedural strokes and just draw the dynamic HUD on top.
    final hasImage = bgArt.denImageAsset(bgId) != null;

    if (!hasImage) {
      solid(0, 71, 0, 35, wall);
      solid(0, 71, 36, 47, floor);
      solid(0, 71, 36, 36, wallD);
      for (int x = 4; x < 72; x += 10) { dot(x, 40, floorD); dot(x + 5, 44, floorD); }

      _drawThemeWall(dot, block, accent, wallD, wallL);

      // lamp
      block(35, 35, 0, 2, wallD);
      block(33, 37, 3, 4, accent);
      if (frame % 2 == 0) {
        dot(32, 5, accent.withOpacity(.35));
        dot(38, 5, accent.withOpacity(.35));
        dot(35, 5, accent.withOpacity(.5));
      }
    }

    // Badges, trophy shelf + trophies, and the legendary_all diamond used
    // to draw here -- moved to real images rendered as Positioned widgets
    // (see denHudWidgets in den_hud.dart, spliced into this card's Stack
    // in _ShareCard.build()), shared with den_scene.dart's matching swap.

    // showcase boxes — skipped entirely once hasImage, not just their
    // pedestal, same as den_scene.dart's matching fix: they're flat
    // procedural cubes that read as leftover debug boxes against real
    // photo art regardless of what's done to the pedestal/highlight around
    // them.
    for (int i = 0; i < 3 && !hasImage; i++) {
      final hasItem = i < top3Colors.length;
      final x0 = 44 + i * 9;
      solid(x0, x0 + 4, 39, 44, floorD);
      solid(x0, x0 + 4, 39, 39, Color.lerp(floorD, Colors.white, .14)!);
      if (hasItem) {
        final c = top3Colors[i];
        block(x0, x0 + 4, 33, 38, c);
        block(x0, x0 + 4, 33, 33, Color.lerp(c, Colors.white, .35)!);
        dot(x0 + 1, 35, Color.lerp(c, Colors.white, .2)!);
      } else {
        dot(x0 + 2, 37, wallD);
      }
    }

    // rug — centered under the minifig. Skipped once hasImage, same as
    // brick_den.dart's matching fix: against real photo art the dash
    // texture reads as disconnected boxes floating on the floor rather
    // than a rug.
    if (!hasImage) {
      solid(28, 44, 44, 46, Color.lerp(floor, accent, .16)!);
      for (int x = 30; x < 44; x += 4) dot(x, 45, accent.withOpacity(.3));
    }
  }

  void _drawThemeWall(
      void Function(int, int, Color) dot,
      void Function(int, int, int, int, Color) block,
      Color accent, Color wallD, Color wallL) {
    // Static (frame 0) versions of the animated walls — good enough for a still.
    switch (bgId) {
      case 'bg_space':
        for (final pos in [(4,12),(15,18),(24,10),(33,20),(10,26),(27,28),(2,22)]) {
          dot(pos.$1, pos.$2, const Color(0xFF88FF44));
        }
        block(14, 17, 12, 14, const Color(0xFFAB47BC));
        dot(12, 13, const Color(0xFFE1BEE7)); dot(19, 13, const Color(0xFFE1BEE7));
        break;
      case 'bg_yellow':
        for (int y = 12; y < 34; y += 6) {
          for (int x = 2; x < 38; x += 7) {
            block(x, x + 1, y, y + 1, const Color(0xFF2A1F00));
            dot(x, y, const Color(0xFF3A2C00));
          }
        }
        break;
      default:
        // Try the shared scene-2 library (covers most backgrounds), else stars.
        bgArt.drawDenSceneDetails(dot, bgId, 0); {
          for (final pos in [(6,12),(18,16),(28,10),(34,22),(12,26)]) {
            dot(pos.$1, pos.$2, Colors.white.withOpacity(.35));
          }
        }
    }
  }

  @override
  bool shouldRepaint(covariant DenPainter old) =>
      old.frame != frame || old.bgId != bgId ||
      old.earned.length != earned.length ||
      old.top3Colors.length != top3Colors.length;
}