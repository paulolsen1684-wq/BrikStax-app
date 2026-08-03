// lib/modules/avatar/data/backgrounds_art.dart
// Redesigned BACKGROUND slot — covers BOTH render contexts that share these
// ids: the avatar's circular backdrop, and the Brick Den's room scene.
// Each entry defines one palette + a couple of scene accents used in both.

import 'package:flutter/material.dart';

class BgPalette {
  final Color avatarBg;   // avatar circle fill
  final Color denWall;    // den back wall
  final Color denFloor;   // den floor
  final Color accent;     // shared accent color for scene details
  const BgPalette(this.avatarBg, this.denWall, this.denFloor, this.accent);
}

const Map<String, BgPalette> bgPalettes = {
  'bg_cream':       BgPalette(Color(0xFF1a1a2e), Color(0xFFF5F0E6), Color(0xFFE8DCC8), Color(0xFFFFD700)),
  'bg_skyline':      BgPalette(Color(0xFF102A43), Color(0xFF1B3A57), Color(0xFF0D2036), Color(0xFFFFD740)),
  'bg_garage':       BgPalette(Color(0xFF1C1C1C), Color(0xFF2A2A2A), Color(0xFF171717), Color(0xFFFFB300)),
  'bg_backyard':     BgPalette(Color(0xFF173B1E), Color(0xFF1F4D28), Color(0xFF123317), Color(0xFF9CCC65)),
  'bg_track':        BgPalette(Color(0xFF2B1B10), Color(0xFF3A2416), Color(0xFF1F140C), Color(0xFFE53935)),
  'bg_greenhouse':   BgPalette(Color(0xFF0E2620), Color(0xFF15382F), Color(0xFF0A1D18), Color(0xFF9CCC65)),
  'bg_workshop':     BgPalette(Color(0xFF2E1F14), Color(0xFF3D2A1B), Color(0xFF20150D), Color(0xFFB0BEC5)),
  'bg_reef':         BgPalette(Color(0xFF062330), Color(0xFF0A3244), Color(0xFF041A24), Color(0xFF4DD0E1)),
  'bg_snowfield':    BgPalette(Color(0xFF1C2A33), Color(0xFF2C4356), Color(0xFF16232C), Color(0xFFECEFF1)),
  'bg_graveyard':    BgPalette(Color(0xFF0E1518), Color(0xFF17211F), Color(0xFF090E10), Color(0xFF9CCC65)),
  'bg_spacestation': BgPalette(Color(0xFF0d1b0d), Color(0xFF12261F), Color(0xFF081109), Color(0xFF88FF44)),
  'bg_castlehall':   BgPalette(Color(0xFF1A0E08), Color(0xFF2A180C), Color(0xFF120A05), Color(0xFFC9A13B)),
  'bg_volcano':      BgPalette(Color(0xFF1C1A16), Color(0xFF2E1F14), Color(0xFF120D08), Color(0xFFFF6D00)),
  'bg_shadowrealm':  BgPalette(Color(0xFF12181C), Color(0xFF1D262C), Color(0xFF0A0E10), Color(0xFF9C27B0)),
  'bg_prismvoid':    BgPalette(Color(0xFF0A0E20), Color(0xFF12163A), Color(0xFF060814), Color(0xFFFFFFFF)),

  // Wave 2
  'bg_meadow':         BgPalette(Color(0xFF1B4D2E), Color(0xFF255C39), Color(0xFF123420), Color(0xFF9CCC65)),
  'bg_pier':           BgPalette(Color(0xFF0D3B4F), Color(0xFF154C63), Color(0xFF082733), Color(0xFF4DD0E1)),
  'bg_attic':          BgPalette(Color(0xFF2E1F14), Color(0xFF3D2A1B), Color(0xFF20150D), Color(0xFFC9A13B)),
  'bg_carnival':       BgPalette(Color(0xFF4A0E2E), Color(0xFF5C1638), Color(0xFF2E081C), Color(0xFFFFD740)),
  'bg_desertdunes':    BgPalette(Color(0xFF6B4A2A), Color(0xFF7D5A38), Color(0xFF4A331C), Color(0xFFFFCC80)),
  'bg_sunfadedroom':   BgPalette(Color(0xFF4A3F2E), Color(0xFF5C4E3A), Color(0xFF332A1E), Color(0xFFFFE0B2)),
  'bg_clocktower':     BgPalette(Color(0xFF2A2018), Color(0xFF3A2C20), Color(0xFF1A130D), Color(0xFFC9A13B)),
  'bg_mosswood':       BgPalette(Color(0xFF16281A), Color(0xFF1E3624), Color(0xFF0D1A10), Color(0xFF7CB342)),
  'bg_huntinglodge':   BgPalette(Color(0xFF2E1B12), Color(0xFF3D2518), Color(0xFF1C110A), Color(0xFF6D4C41)),
  'bg_palecrypt':      BgPalette(Color(0xFF2A2A2E), Color(0xFF38383E), Color(0xFF1A1A1E), Color(0xFFE0E0E0)),
  'bg_sandstonetemple':BgPalette(Color(0xFF4A3A22), Color(0xFF5C4A2E), Color(0xFF332614), Color(0xFFD9BE8C)),
  'bg_jadejungle':      BgPalette(Color(0xFF0E2E18), Color(0xFF163C22), Color(0xFF081C0E), Color(0xFF66BB6A)),
  'bg_glaciercave':    BgPalette(Color(0xFF0E2A3A), Color(0xFF163A4E), Color(0xFF081A26), Color(0xFF81D4FA)),
  'bg_wraithmanor':    BgPalette(Color(0xFF1E1428), Color(0xFF2A1C38), Color(0xFF120C1A), Color(0xFF9575CD)),
  'bg_novaskies':      BgPalette(Color(0xFF0A0E20), Color(0xFF12163A), Color(0xFF060814), Color(0xFF00E5FF)),

  // Wave 3 — inspired by the accessory expansion
  'bg_azurearena':       BgPalette(Color(0xFF0D2B3E), Color(0xFF15405A), Color(0xFF081A26), Color(0xFF29B6F6)),
  'bg_verdantgrove':     BgPalette(Color(0xFF163420), Color(0xFF1F4A2C), Color(0xFF0D2015), Color(0xFF66BB6A)),
  'bg_emberpit':         BgPalette(Color(0xFF3A1810), Color(0xFF4E2416), Color(0xFF240E08), Color(0xFFE53935)),
  'bg_twilightring':     BgPalette(Color(0xFF2A123A), Color(0xFF3A1A4E), Color(0xFF180A22), Color(0xFF9C27B0)),
  'bg_twinspires':       BgPalette(Color(0xFF2E2A1C), Color(0xFF3E3626), Color(0xFF1C1810), Color(0xFFFF7043)),
  'bg_prismcolosseum':   BgPalette(Color(0xFF1A1A2E), Color(0xFF24243E), Color(0xFF10101C), Color(0xFFFFD93D)),

  'bg_fishingdock':      BgPalette(Color(0xFF163040), Color(0xFF204458), Color(0xFF0C1E28), Color(0xFFCFD8DC)),
  'bg_tackleshed':       BgPalette(Color(0xFF2E2216), Color(0xFF3E3020), Color(0xFF1C140C), Color(0xFF546E7A)),
  'bg_trophypier':       BgPalette(Color(0xFF123840), Color(0xFF1A4C56), Color(0xFF0A2226), Color(0xFFFFD700)),

  'bg_sortingroom':      BgPalette(Color(0xFF3A2E1E), Color(0xFF4E3E2A), Color(0xFF241A10), Color(0xFFE53935)),
  'bg_workbench':        BgPalette(Color(0xFF2E2418), Color(0xFF3E3222), Color(0xFF1C160E), Color(0xFF90A4AE)),
  'bg_inspectiondesk':   BgPalette(Color(0xFF3A2E18), Color(0xFF4E3E22), Color(0xFF241A0E), Color(0xFF4FC3F7)),
  'bg_goldenhall':       BgPalette(Color(0xFF1A1408), Color(0xFF2E2410), Color(0xFF100C04), Color(0xFFFFD700)),

  'bg_wizardsstudy':     BgPalette(Color(0xFF1E1430), Color(0xFF2A1E42), Color(0xFF120C1E), Color(0xFF9575CD)),
  'bg_enchantersalcove': BgPalette(Color(0xFF241638), Color(0xFF32204C), Color(0xFF160E20), Color(0xFFE1BEE7)),
  'bg_runechamber':      BgPalette(Color(0xFF160E20), Color(0xFF20142E), Color(0xFF0C0814), Color(0xFF9C27B0)),

  'bg_observatory':      BgPalette(Color(0xFF0A0E22), Color(0xFF12183A), Color(0xFF060A16), Color(0xFFE1F5FE)),
  'bg_maproom':          BgPalette(Color(0xFF3A3018), Color(0xFF4E4222), Color(0xFF241E0E), Color(0xFFD32F2F)),
  'bg_meteorcrater':     BgPalette(Color(0xFF241C14), Color(0xFF34281A), Color(0xFF140F0A), Color(0xFFFF7043)),

  'bg_bathtime':         BgPalette(Color(0xFF163038), Color(0xFF20434C), Color(0xFF0C1E22), Color(0xFFFFEB3B)),
  'bg_coffeenook':       BgPalette(Color(0xFF2E2016), Color(0xFF3E2C1E), Color(0xFF1C130C), Color(0xFFECEFF1)),
  'bg_displaycase':      BgPalette(Color(0xFF1E262E), Color(0xFF2A343E), Color(0xFF10161C), Color(0xFFC9A13B)),
};

// bg_* ids with real generated Den art at assets/avatar/dens/<id>.png. Ids
// missing from this set (bg_workbench, bg_snowfield, bg_maproom,
// bg_shadowrealm as of this writing) have no art yet and keep falling back
// to the procedural wall/floor painter in brick_den.dart / den_share_screen.dart.
const Set<String> bgImageIds = {
  'bg_cream', 'bg_skyline', 'bg_garage', 'bg_backyard', 'bg_track', 'bg_meadow',
  'bg_pier', 'bg_attic', 'bg_carnival', 'bg_desertdunes', 'bg_azurearena',
  'bg_verdantgrove', 'bg_fishingdock', 'bg_sortingroom', 'bg_bathtime',
  'bg_coffeenook', 'bg_greenhouse', 'bg_workshop', 'bg_reef', 'bg_sunfadedroom',
  'bg_clocktower', 'bg_mosswood', 'bg_huntinglodge', 'bg_tackleshed',
  'bg_wizardsstudy', 'bg_observatory', 'bg_emberpit', 'bg_graveyard',
  'bg_spacestation', 'bg_castlehall', 'bg_palecrypt', 'bg_sandstonetemple',
  'bg_jadejungle', 'bg_twilightring', 'bg_trophypier', 'bg_inspectiondesk',
  'bg_enchantersalcove', 'bg_displaycase', 'bg_volcano', 'bg_glaciercave',
  'bg_wraithmanor', 'bg_twinspires', 'bg_runechamber', 'bg_meteorcrater',
  'bg_prismvoid', 'bg_novaskies', 'bg_prismcolosseum', 'bg_goldenhall',
};

/// Asset path for a bg_id's generated Den art, or null when there isn't one
/// yet (caller should keep using the procedural wall/floor painter).
String? denImageAsset(String? bgId) =>
    (bgId != null && bgImageIds.contains(bgId))
        ? 'assets/avatar/dens/$bgId.png'
        : null;

/// Avatar circle background details — a handful of accent dots per theme.
void drawAvatarBgDetails(void Function(int, int, Color) dot, String? id, int frame) {
  final p = bgPalettes[id];
  if (p == null) return;
  switch (id) {
    case 'bg_spacestation':
      for (final pos in [(2, 2), (16, 3), (9, 1)]) dot(pos.$1, pos.$2, p.accent);
      break;
    case 'bg_volcano':
      final lava = frame % 2 == 0 ? p.accent : const Color(0xFFFFAB40);
      dot(2, 24, lava);
      break;
    case 'bg_shadowrealm':
      final glow = frame % 2 == 0 ? p.accent : const Color(0xFF6A1B9A);
      dot(16, 4, glow);
      break;
    case 'bg_prismvoid':
      const cycle = [Color(0xFFFF6B6B), Color(0xFFFFD93D), Color(0xFF6BCB77), Color(0xFF4D96FF)];
      dot(3 + frame * 3, 2, cycle[frame]);
      break;
    case 'bg_glaciercave':
      final frost = frame % 2 == 0 ? p.accent : Colors.white;
      dot(2, 3, frost);
      break;
    case 'bg_wraithmanor':
      final glow2 = frame % 2 == 0 ? p.accent : const Color(0xFF7C4DFF);
      dot(16, 2, glow2);
      break;
    case 'bg_novaskies':
      const novaCycle = [Color(0xFF00E5FF), Color(0xFFFF4081), Color(0xFFFFEA00), Color(0xFF76FF03)];
      dot(3 + frame * 3, 1, novaCycle[frame]);
      break;
    case 'bg_twinspires':
      final ember = frame % 2 == 0 ? p.accent : const Color(0xFF4D96FF);
      dot(2, 3, p.accent);
      dot(16, 2, ember);
      break;
    case 'bg_prismcolosseum':
      const cycle = [Color(0xFFFF6B6B), Color(0xFFFFD93D), Color(0xFF6BCB77), Color(0xFF4D96FF)];
      dot(9, 1, cycle[frame]);
      dot(2, 3, cycle[(frame + 2) % 4]);
      break;
    case 'bg_goldenhall':
      final shine = frame % 2 == 0 ? p.accent : const Color(0xFFFFF176);
      dot(9, 1, shine);
      break;
    case 'bg_runechamber':
      final rune = frame % 2 == 0 ? p.accent : const Color(0xFFE1BEE7);
      dot(2, 2, rune);
      dot(16, 3, rune);
      break;
    case 'bg_meteorcrater':
      final glow3 = frame % 2 == 0 ? p.accent : const Color(0xFFFFAB40);
      dot(9, 2, glow3);
      break;
    case 'bg_azurearena':
      dot(2, 2, p.accent); dot(16, 2, p.accent); // twin banner glints
      break;
    case 'bg_verdantgrove':
      for (final pos in [(2, 3), (16, 2), (9, 1)]) dot(pos.$1, pos.$2, p.accent); // leaf dapples
      break;
    case 'bg_emberpit':
      final ember2 = frame % 2 == 0 ? p.accent : const Color(0xFFFFAB40);
      dot(9, 3, ember2);
      break;
    case 'bg_twilightring':
      final dusk = frame % 2 == 0 ? p.accent : const Color(0xFF6A1B9A);
      dot(2, 2, dusk); dot(16, 3, dusk);
      break;
    case 'bg_fishingdock':
      dot(2, 4, p.accent); // gull silhouette
      break;
    case 'bg_tackleshed':
      dot(9, 2, p.accent);
      break;
    case 'bg_trophypier':
      final shine2 = frame % 2 == 0 ? p.accent : const Color(0xFFFFF176);
      dot(9, 1, shine2);
      break;
    case 'bg_sortingroom':
      const studColors = [Color(0xFFE53935), Color(0xFF1976D2), Color(0xFF43A047)];
      for (int i = 0; i < 3; i++) dot(2 + i * 6, 2, studColors[i]); // scattered bricks
      break;
    case 'bg_workbench':
      dot(9, 1, p.accent);
      break;
    case 'bg_inspectiondesk':
      dot(9, 2, p.accent);
      break;
    case 'bg_wizardsstudy':
      final candle = frame % 2 == 0 ? p.accent : const Color(0xFFFFF176);
      dot(2, 2, candle);
      break;
    case 'bg_enchantersalcove':
      final hum = frame % 2 == 0 ? p.accent : const Color(0xFFF3E5F5);
      dot(9, 2, hum);
      break;
    case 'bg_observatory':
      for (final pos in [(2, 1), (9, 2), (16, 1)]) dot(pos.$1, pos.$2, p.accent); // stars
      break;
    case 'bg_maproom':
      dot(9, 3, p.accent);
      break;
    case 'bg_bathtime':
      for (int i = 0; i < 3; i++) dot(2 + i * 6, 3, Colors.white); // bubbles
      break;
    case 'bg_coffeenook':
      dot(9, 1, p.accent); dot(9, 2, p.accent); // steam
      break;
    case 'bg_displaycase':
      dot(9, 1, p.accent);
      break;

    // ── Wave 1 & 2 backgrounds that never got custom art ───────────────
    case 'bg_cream':
      dot(2, 2, Colors.white); dot(16, 2, Colors.white); // soft sparkle
      break;
    case 'bg_skyline':
      for (int gy = 0; gy <= 4; gy++) dot(2, gy, p.accent); // lit window column
      dot(16, 2, p.accent);
      break;
    case 'bg_garage':
      dot(2, 3, p.accent); dot(3, 3, p.accent); // toolbox glint
      break;
    case 'bg_backyard':
      dot(9, 0, const Color(0xFFFFD700)); // sun
      dot(2, 4, p.accent);
      break;
    case 'bg_track':
      dot(2, 2, Colors.white); dot(3, 2, const Color(0xFF1a1a1a)); // checkered flag hint
      break;
    case 'bg_greenhouse':
      dot(2, 2, p.accent); dot(16, 3, p.accent);
      break;
    case 'bg_workshop':
      dot(9, 1, p.accent);
      break;
    case 'bg_reef':
      for (final pos in [(2, 3), (16, 2), (9, 1)]) dot(pos.$1, pos.$2, p.accent); // bubbles
      break;
    case 'bg_snowfield':
      final flake = frame % 2 == 0 ? Colors.white : p.accent;
      dot(2 + frame, 1, flake); // drifting snowflake
      break;
    case 'bg_graveyard':
      dot(2, 3, const Color(0xFF9E9E9E)); // distant headstone
      break;
    case 'bg_castlehall':
      dot(2, 1, p.accent); dot(16, 1, p.accent); // banner tops
      break;
    case 'bg_meadow':
      const petal = Color(0xFFF48FB1);
      dot(2, 3, petal); dot(16, 2, const Color(0xFFFFEB3B)); // flower + butterfly
      break;
    case 'bg_pier':
      dot(2, 4, p.accent); // gull
      break;
    case 'bg_attic':
      dot(16, 1, const Color(0xFF9E9E9E)); // cobweb corner
      break;
    case 'bg_carnival':
      final bulb = frame % 2 == 0 ? p.accent : const Color(0xFFFFEB3B);
      dot(2, 1, bulb); dot(9, 0, bulb); dot(16, 1, bulb); // string lights
      break;
    case 'bg_desertdunes':
      dot(16, 1, const Color(0xFFFFD700)); // sun over the dunes
      break;
    case 'bg_sunfadedroom':
      dot(9, 2, p.accent);
      break;
    case 'bg_clocktower':
      dot(9, 1, p.accent); // clock face glint
      break;
    case 'bg_mosswood':
      dot(2, 2, p.accent); dot(16, 3, p.accent);
      break;
    case 'bg_huntinglodge':
      dot(9, 2, p.accent); // antler glint
      break;
    case 'bg_palecrypt':
      final candle = frame % 2 == 0 ? p.accent : const Color(0xFFFFE082);
      dot(9, 1, candle);
      break;
    case 'bg_sandstonetemple':
      dot(2, 1, p.accent); dot(16, 1, p.accent); // pillar tops
      break;
    case 'bg_jadejungle':
      for (final pos in [(2, 2), (16, 2), (9, 0)]) dot(pos.$1, pos.$2, p.accent); // vine leaves
      break;

    default:
      dot(2, 2, p.accent);
      dot(16, 3, p.accent);
  }
}

// ── Den scene shape helpers ─────────────────────────────────────────────
// Every background below is built from these — real silhouettes with
// width AND height variation, not single-column lines. This replaces an
// earlier pass where most props were thin 1-2px bars that read as poles
// rather than their subject.

/// A skyline/structure profile: buildings of varied width and height
/// sharing one ground line. Works for cities, temples, colosseums, halls.
void _buildingProfile(void Function(int, int, Color) dot,
    List<(int, int, int)> buildings, Color base, Color dark, {int groundRow = 34}) {
  for (final b in buildings) {
    final (x0, w, h) = b;
    for (int gx = x0; gx < x0 + w; gx++) {
      for (int gy = groundRow - h; gy < groundRow; gy++) {
        dot(gx, gy, (gx + gy) % 5 == 0 ? dark : base);
      }
    }
  }
}

/// A tapering fan/blob cluster — coral, bushes, canopies, mushrooms.
void _blobCluster(void Function(int, int, Color) dot,
    int cx, int baseRow, Color hi, Color lo, {List<int> widths = const [5, 7, 6, 3]}) {
  for (int i = 0; i < widths.length; i++) {
    final w = widths[i];
    final gy = baseRow - (widths.length - i);
    for (int gx = cx - w ~/ 2; gx <= cx + w ~/ 2; gx++) {
      dot(gx, gy, i.isEven ? hi : lo);
    }
  }
}

/// A tree: trunk plus a canopy blob on top.
void _tree(void Function(int, int, Color) dot,
    int cx, Color trunk, Color canopyHi, Color canopyLo, {int groundRow = 34, int trunkHeight = 8}) {
  for (int gy = groundRow - trunkHeight; gy < groundRow; gy++) {
    dot(cx, gy, trunk);
    dot(cx + 1, gy, trunk);
  }
  _blobCluster(dot, cx, groundRow - trunkHeight + 2, canopyHi, canopyLo, widths: const [6, 8, 7, 4]);
}

/// Two flanking pillars/archway sides.
void _archPillars(void Function(int, int, Color) dot,
    int leftX, int rightX, int topY, int botY, Color color, {Color? cap}) {
  for (int gy = topY; gy <= botY; gy++) {
    for (int w = 0; w < 3; w++) { dot(leftX + w, gy, color); dot(rightX - w, gy, color); }
  }
  if (cap != null) {
    for (int w = 0; w < 3; w++) { dot(leftX + w, topY - 1, cap); dot(rightX - w, topY - 1, cap); }
  }
}

/// Scattered stars/sparkles, optionally blinking with frame.
void _starfield(void Function(int, int, Color) dot,
    List<(int, int)> positions, Color color, {Color? blink, int frame = 0}) {
  for (int i = 0; i < positions.length; i++) {
    final pos = positions[i];
    final c = (blink != null && (i + frame) % 3 == 0) ? blink : color;
    dot(pos.$1, pos.$2, c);
  }
}

/// A row of small evenly-spaced props (tools, bottles, books, lights).
void _propRow(void Function(int, int, Color) dot, int y, int x0, int x1, int spacing, Color color) {
  for (int gx = x0; gx <= x1; gx += spacing) dot(gx, y, color);
}

/// A vertical hanging strand (vine, icicle, banner, rope, chain).
void _hangingStrand(void Function(int, int, Color) dot, int x, int topY, int botY, Color color) {
  for (int gy = topY; gy <= botY; gy++) dot(x, gy, color);
}

/// A low floor-level clutter row (grass, rubble, pebbles, bricks).
void _floorClutter(void Function(int, int, Color) dot, int y, int x0, int x1, int spacing, Color color) {
  for (int gx = x0; gx <= x1; gx += spacing) dot(gx, y, color);
}

/// Den room scene details — wall/floor already painted by the den painter
/// using [bgPalettes]; this adds real themed silhouettes per background,
/// built from the shape helpers above so every scene has actual form.
void drawDenSceneDetails(void Function(int, int, Color) dot, String? id, int frame) {
  final p = bgPalettes[id];
  if (p == null) return;
  switch (id) {
    case 'bg_cream':
      _starfield(dot, const [(8, 6), (34, 4), (60, 7), (46, 10)], Colors.white);
      break;

    case 'bg_skyline':
      _buildingProfile(dot, const [
        (2, 6, 20), (9, 4, 12), (14, 8, 24), (23, 5, 16),
        (29, 7, 28), (37, 4, 10), (42, 9, 26), (52, 5, 14),
        (58, 8, 22), (67, 4, 12),
      ], const Color(0xFF455A64), const Color(0xFF37474F));
      _starfield(dot, const [(4, 20), (16, 14), (31, 12), (44, 16), (60, 20), (10, 8), (53, 10)],
          p.accent, blink: const Color(0xFFFFD740), frame: frame);
      break;

    case 'bg_garage':
      _propRow(dot, 10, 10, 50, 10, p.accent); // pegboard hooks
      _propRow(dot, 16, 10, 50, 10, const Color(0xFF616161));
      for (int gy = 26; gy <= 34; gy++) { dot(58, gy, const Color(0xFF212121)); dot(59, gy, const Color(0xFF212121)); } // tire stack
      dot(58, 24, const Color(0xFF9E9E9E)); dot(59, 24, const Color(0xFF9E9E9E)); // hubcap glint
      break;

    case 'bg_backyard':
      _floorClutter(dot, 20, 4, 68, 6, const Color(0xFF6D4C41)); // fence line
      _tree(dot, 12, const Color(0xFF5D4037), const Color(0xFF7CB342), const Color(0xFF558B2F), trunkHeight: 10);
      _tree(dot, 60, const Color(0xFF5D4037), const Color(0xFF9CCC65), const Color(0xFF7CB342), trunkHeight: 8);
      _floorClutter(dot, 34, 6, 66, 3, p.accent); // grass tufts
      break;

    case 'bg_track':
      _propRow(dot, 6, 8, 60, 8, Colors.white);
      _propRow(dot, 6, 12, 64, 8, const Color(0xFF1a1a1a)); // checkered banner
      for (int gy = 30; gy <= 35; gy++) { dot(34, gy, const Color(0xFF1a1a1a)); dot(38, gy, const Color(0xFF1a1a1a)); } // tire marks
      break;

    case 'bg_greenhouse':
      for (final cx in [12, 26, 46, 60]) {
        _blobCluster(dot, cx, 33, const Color(0xFF7CB342), const Color(0xFF558B2F), widths: const [4, 5, 3]);
      }
      for (int gy = 4; gy <= 26; gy += 4) { dot(20, gy, const Color(0xFFB3E5FC)); dot(52, gy, const Color(0xFFB3E5FC)); } // glass pane lines
      break;

    case 'bg_workshop':
      _propRow(dot, 24, 8, 60, 8, p.accent); // tool row on the bench
      _propRow(dot, 26, 12, 56, 12, const Color(0xFF90A4AE));
      break;

    case 'bg_reef':
      _blobCluster(dot, 14, 34, const Color(0xFFFF7043), const Color(0xFFE64A19));
      _blobCluster(dot, 30, 35, const Color(0xFFEC407A), const Color(0xFFC2185B));
      _blobCluster(dot, 56, 34, const Color(0xFFFFA726), const Color(0xFFE65100));
      _starfield(dot, const [(20, 10), (44, 6), (32, 14), (50, 18)], p.accent); // rising bubbles
      break;

    case 'bg_snowfield':
      _buildingProfile(dot, const [(6, 12, 6), (24, 16, 8), (46, 14, 5), (62, 10, 7)], Colors.white, const Color(0xFFE1F5FE)); // snow drifts
      final flake = frame % 2 == 0 ? Colors.white : p.accent;
      _starfield(dot, [(10 + frame * 8, 6), (30 - frame * 4, 10), (50 + frame * 3, 4)], flake);
      break;

    case 'bg_graveyard':
      for (final cx in [16, 34, 52]) {
        for (int gy = 26; gy <= 32; gy++) { dot(cx, gy, const Color(0xFF757575)); dot(cx + 1, gy, const Color(0xFF757575)); }
        dot(cx, 25, const Color(0xFF9E9E9E)); dot(cx + 1, 25, const Color(0xFF9E9E9E)); // headstone tops
      }
      break;

    case 'bg_spacestation':
      _starfield(dot, const [(4, 4), (60, 6), (34, 2), (18, 10), (48, 12)], p.accent);
      for (int gy = 8; gy <= 24; gy++) dot(36, gy, const Color(0xFF37474F)); // porthole column
      dot(36, 14, p.accent);
      break;

    case 'bg_castlehall':
      _archPillars(dot, 8, 64, 4, 30, p.accent, cap: const Color(0xFFC9A13B));
      _hangingStrand(dot, 20, 6, 18, const Color(0xFFC62828)); // banner
      _hangingStrand(dot, 52, 6, 18, const Color(0xFFC62828));
      break;

    case 'bg_volcano':
      final lava = frame % 2 == 0 ? p.accent : const Color(0xFFFFAB40);
      _buildingProfile(dot, const [(10, 20, 10), (34, 26, 16), (60, 16, 8)], const Color(0xFF3E2723), const Color(0xFF1C1410));
      _floorClutter(dot, 30, 14, 60, 8, lava); // lava veins on the slope
      break;

    case 'bg_shadowrealm':
      final wisp = frame % 2 == 0 ? p.accent : const Color(0xFF6A1B9A);
      _starfield(dot, [(20 + frame * 4, 14), (50 - frame * 3, 20), (35, 8)], wisp);
      break;

    case 'bg_prismvoid':
      const cycle = [Color(0xFFFF6B6B), Color(0xFFFFD93D), Color(0xFF6BCB77), Color(0xFF4D96FF)];
      for (int gx = 4; gx <= 68; gx += 8) dot(gx, 2 + (gx ~/ 8) % 3 * 2, cycle[(frame + gx ~/ 8) % 4]);
      break;

    case 'bg_meadow':
      for (final cx in [10, 24, 44, 58]) {
        _blobCluster(dot, cx, 34, const Color(0xFFF48FB1), const Color(0xFFE91E8C), widths: const [3, 4, 2]);
      }
      dot(40, 12, const Color(0xFFFFEB3B)); dot(41, 11, const Color(0xFF1a1a1a)); // butterfly
      break;

    case 'bg_pier':
      _floorClutter(dot, 34, 4, 68, 8, const Color(0xFF6D4C41)); // dock planks
      _floorClutter(dot, 30, 6, 66, 10, p.accent); // water ripple
      _hangingStrand(dot, 30, 10, 20, const Color(0xFF6D4C41)); // hanging lantern line
      dot(30, 20, const Color(0xFFFFD54F));
      break;

    case 'bg_attic':
      dot(64, 4, const Color(0xFF9E9E9E)); dot(63, 5, const Color(0xFF9E9E9E)); dot(65, 6, const Color(0xFF9E9E9E)); // cobweb corner
      for (final x0 in [8, 16]) {
        for (int gy = 26; gy <= 34; gy++) {
          for (int gx = x0; gx < x0 + 6; gx++) dot(gx, gy, const Color(0xFF8D6E63));
        }
      }
      break;

    case 'bg_carnival':
      final bulb = frame % 2 == 0 ? p.accent : const Color(0xFFFFEB3B);
      _propRow(dot, 4, 6, 66, 8, bulb); // string lights across the ceiling
      _archPillars(dot, 30, 42, 6, 24, const Color(0xFFE53935), cap: Colors.white); // striped tent
      break;

    case 'bg_desertdunes':
      _floorClutter(dot, 32, 0, 72, 3, const Color(0xFFD9BE8C)); // dune curve
      for (int gy = 24; gy <= 30; gy++) dot(58, gy, const Color(0xFF558B2F)); // cactus
      dot(56, 26, const Color(0xFF558B2F)); dot(60, 27, const Color(0xFF558B2F));
      dot(66, 6, const Color(0xFFFFD700)); // sun
      break;

    case 'bg_sunfadedroom':
      for (int gy = 6; gy <= 26; gy++) { dot(50, gy, const Color(0xFF8D6E63)); dot(51, gy, const Color(0xFF8D6E63)); } // curtain
      for (int gx = 18; gx <= 42; gx++) dot(gx, 10, p.accent); // light beam
      break;

    case 'bg_clocktower':
      for (int gy = 6; gy <= 22; gy++) { dot(28, gy, p.accent); dot(44, gy, p.accent); } // clock frame sides
      for (int gx = 28; gx <= 44; gx++) { dot(gx, 6, p.accent); dot(gx, 22, p.accent); }
      dot(36, 14, const Color(0xFF1a1a1a)); dot(36, 10, const Color(0xFF1a1a1a)); // hands
      break;

    case 'bg_mosswood':
      _tree(dot, 14, const Color(0xFF3E2723), const Color(0xFF558B2F), const Color(0xFF33691E), trunkHeight: 12);
      _tree(dot, 36, const Color(0xFF3E2723), const Color(0xFF689F38), const Color(0xFF33691E), trunkHeight: 16);
      _tree(dot, 58, const Color(0xFF3E2723), const Color(0xFF558B2F), const Color(0xFF33691E), trunkHeight: 10);
      _floorClutter(dot, 34, 8, 64, 5, p.accent); // moss patches
      break;

    case 'bg_huntinglodge':
      for (int gx = 24; gx <= 48; gx += 4) dot(gx, 8, const Color(0xFFD9BE8C)); // mounted antlers
      dot(28, 6, const Color(0xFFD9BE8C)); dot(44, 6, const Color(0xFFD9BE8C));
      final fire = frame % 2 == 0 ? const Color(0xFFFF6D00) : const Color(0xFFFFAB40);
      _blobCluster(dot, 36, 34, fire, const Color(0xFFBF360C), widths: const [4, 6, 3]); // fireplace
      break;

    case 'bg_palecrypt':
      _archPillars(dot, 14, 58, 4, 28, const Color(0xFF3a3a3a), cap: const Color(0xFF5a5a5a));
      final candle = frame % 2 == 0 ? p.accent : const Color(0xFFFFE082);
      dot(36, 26, candle); dot(36, 25, candle);
      break;

    case 'bg_sandstonetemple':
      _buildingProfile(dot, const [(10, 6, 28), (30, 6, 32), (56, 6, 28)], p.accent, const Color(0xFF8A7040));
      dot(31, 16, const Color(0xFF3E2723)); dot(34, 16, const Color(0xFF3E2723)); // carved marks
      break;

    case 'bg_jadejungle':
      _hangingStrand(dot, 10, 2, 20, p.accent); _hangingStrand(dot, 62, 2, 18, p.accent); // hanging vines
      for (final pos in [(20, 24), (50, 20), (36, 28)]) {
        _blobCluster(dot, pos.$1, pos.$2 + 4, const Color(0xFF66BB6A), const Color(0xFF388E3C), widths: const [4, 5, 3]);
      }
      break;

    case 'bg_glaciercave':
      final frost = frame % 2 == 0 ? p.accent : Colors.white;
      _buildingProfile(dot, const [(8, 10, 22), (46, 14, 26), (64, 8, 16)], const Color(0xFF4FC3F7), const Color(0xFF0288D1));
      dot(14, 8, frost); dot(52, 6, frost);
      break;

    case 'bg_wraithmanor':
      final glow2 = frame % 2 == 0 ? p.accent : const Color(0xFF7C4DFF);
      _archPillars(dot, 20, 52, 4, 26, const Color(0xFF2A1C38), cap: glow2);
      dot(36, 14, glow2);
      break;

    case 'bg_novaskies':
      const novaCycle = [Color(0xFF00E5FF), Color(0xFFFF4081), Color(0xFFFFEA00), Color(0xFF76FF03)];
      for (int gx = 6; gx <= 60; gx += 12) dot(gx, 4, novaCycle[frame]); // sky streaks
      _starfield(dot, const [(14, 8), (30, 6), (50, 10), (60, 6)], Colors.white);
      break;

    case 'bg_azurearena':
      _archPillars(dot, 10, 62, 6, 24, p.accent, cap: const Color(0xFF0277BD));
      break;
    case 'bg_verdantgrove':
      _tree(dot, 14, const Color(0xFF3E2723), const Color(0xFF66BB6A), const Color(0xFF388E3C), trunkHeight: 12);
      _tree(dot, 58, const Color(0xFF3E2723), const Color(0xFF66BB6A), const Color(0xFF388E3C), trunkHeight: 10);
      break;
    case 'bg_emberpit':
      final ember2 = frame % 2 == 0 ? p.accent : const Color(0xFFFFAB40);
      _blobCluster(dot, 36, 34, ember2, const Color(0xFFBF360C), widths: const [6, 8, 6, 3]);
      break;
    case 'bg_twilightring':
      final dusk = frame % 2 == 0 ? p.accent : const Color(0xFF6A1B9A);
      _archPillars(dot, 16, 56, 8, 26, dusk);
      break;
    case 'bg_twinspires':
      for (int gy = 4; gy <= 30; gy++) { dot(8, gy, p.accent); dot(9, gy, p.accent); dot(62, gy, p.accent); dot(63, gy, p.accent); }
      dot(8, 3, const Color(0xFFFF7043)); dot(62, 3, const Color(0xFFFF7043)); // spire caps
      break;
    case 'bg_prismcolosseum':
      const colCycle = [Color(0xFFFF6B6B), Color(0xFFFFD93D), Color(0xFF6BCB77), Color(0xFF4D96FF)];
      for (int gx = 10; gx <= 60; gx += 10) dot(gx, 6, colCycle[frame]); // banner row
      _archPillars(dot, 6, 66, 8, 30, const Color(0xFF24243E));
      break;

    case 'bg_fishingdock':
      _floorClutter(dot, 34, 4, 68, 8, const Color(0xFF6D4C41)); // dock planks
      _hangingStrand(dot, 30, 10, 20, p.accent); // hanging lantern line
      break;
    case 'bg_tackleshed':
      _propRow(dot, 10, 8, 60, 10, p.accent); // pegboard hooks
      _propRow(dot, 18, 8, 60, 10, const Color(0xFF546E7A));
      break;
    case 'bg_trophypier':
      final shine2 = frame % 2 == 0 ? p.accent : const Color(0xFFFFF176);
      _blobCluster(dot, 36, 20, shine2, const Color(0xFFC9A13B), widths: const [3, 4, 2]); // mounted trophy
      break;

    case 'bg_sortingroom':
      const studColors = [Color(0xFFE53935), Color(0xFF1976D2), Color(0xFF43A047), Color(0xFFFFD700)];
      for (int i = 0; i < 4; i++) {
        for (int gy = 26; gy <= 32; gy++) {
          for (int gx = 10 + i * 14; gx < 16 + i * 14; gx++) dot(gx, gy, studColors[i]); // brick bins
        }
      }
      break;
    case 'bg_workbench':
      _propRow(dot, 28, 8, 64, 6, p.accent); // bench edge tools
      _propRow(dot, 30, 10, 62, 8, const Color(0xFF90A4AE));
      break;
    case 'bg_inspectiondesk':
      for (int gy = 6; gy <= 20; gy++) dot(36, gy, p.accent); // desk lamp beam
      _blobCluster(dot, 36, 26, const Color(0xFFECEFF1), const Color(0xFFB0BEC5), widths: const [3, 4, 2]);
      break;
    case 'bg_goldenhall':
      final shine = frame % 2 == 0 ? p.accent : const Color(0xFFFFF176);
      for (int gy = 6; gy <= 26; gy++) { dot(34, gy, shine); dot(35, gy, shine); dot(36, gy, shine); dot(37, gy, shine); } // central gold pillar
      break;

    case 'bg_wizardsstudy':
      final candle2 = frame % 2 == 0 ? p.accent : const Color(0xFFFFF176);
      for (final x0 in [8, 60]) {
        for (int gy = 4; gy <= 28; gy++) { dot(x0, gy, const Color(0xFF3E2723)); dot(x0 + 4, gy, const Color(0xFF3E2723)); }
      }
      dot(36, 6, candle2); dot(36, 5, candle2);
      break;
    case 'bg_enchantersalcove':
      final hum = frame % 2 == 0 ? p.accent : const Color(0xFFF3E5F5);
      _blobCluster(dot, 36, 20, hum, const Color(0xFF9575CD), widths: const [3, 5, 3]);
      break;
    case 'bg_runechamber':
      final rune = frame % 2 == 0 ? p.accent : const Color(0xFFE1BEE7);
      _starfield(dot, const [(30, 12), (42, 12), (36, 8), (36, 16)], rune);
      break;

    case 'bg_observatory':
      for (int gy = 4; gy <= 26; gy++) { dot(38, gy, p.accent); dot(39, gy, p.accent); } // telescope barrel
      dot(38, 3, Colors.white); dot(39, 3, Colors.white); // eyepiece glint
      _starfield(dot, const [(10, 4), (20, 8), (56, 5), (64, 10)], Colors.white);
      break;
    case 'bg_maproom':
      _propRow(dot, 10, 10, 60, 12, p.accent); // pinned chart markers
      _archPillars(dot, 16, 56, 6, 24, const Color(0xFF4E4222));
      break;
    case 'bg_meteorcrater':
      final glow3 = frame % 2 == 0 ? p.accent : const Color(0xFFFFAB40);
      _floorClutter(dot, 30, 22, 50, 6, glow3); // crater glow floor
      _buildingProfile(dot, const [(14, 10, 8), (48, 14, 10)], const Color(0xFF34281A), const Color(0xFF241C14));
      break;

    case 'bg_bathtime':
      _starfield(dot, const [(8, 4), (24, 3), (40, 5), (56, 3), (64, 6)], Colors.white); // bubbles
      _blobCluster(dot, 36, 34, const Color(0xFFFFEB3B), const Color(0xFFF9A825), widths: const [6, 8, 5]); // duck floatie hint
      break;
    case 'bg_coffeenook':
      for (int gy = 6; gy <= 14; gy++) dot(36, gy, p.accent); // steam column
      _blobCluster(dot, 36, 30, const Color(0xFFECEFF1), const Color(0xFFB0BEC5), widths: const [4, 5, 3]); // mug
      break;
    case 'bg_displaycase':
      _archPillars(dot, 20, 52, 8, 26, p.accent);
      dot(36, 16, const Color(0xFFC9A13B)); // displayed piece glint
      break;

    default:
      dot(6, 10, p.accent);
  }
}
