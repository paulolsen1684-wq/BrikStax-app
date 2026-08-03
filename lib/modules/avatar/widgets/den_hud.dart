// lib/modules/avatar/widgets/den_hud.dart
//
// Real image assets for the Den's HUD (theme badges, trophy shelf, the 4
// per-category trophies, the legendary_all diamond) -- replaces the old
// blocky pixel-grid CustomPainter drawing for just these elements. Both
// den_scene.dart's _DenPainter and den_share_screen.dart's DenPainter
// still draw the wall/floor procedural fallback, theme wall decor, and
// showcase boxes on their own Canvas -- only these four HUD elements moved
// to real art, since those are the ones that draw regardless of hasImage
// (an earned badge/trophy/diamond shows up even over a real photo
// backdrop, unlike the wall/floor which only draws when there's no photo).
//
// Shared by both screens (same reason ground_accessory.dart is shared) so
// their HUD positions/tinting can't drift apart from each other.
//
// Trophy/diamond art is a single NEUTRAL white/light-gray source image,
// tinted at render time via Image.asset's color+colorBlendMode rather than
// shipping a separate colored file per tier -- same trick already used for
// the dynamically-colored brick icons in loot_roll_widget.dart/daily_claim
// _screen.dart. Badges are fully-colored source art instead (each badge's
// color is its fixed identity, not a tier it can be earned at), so no
// tinting there.
//
// Locked/unearned slots simply don't render now -- no gray "locked
// hardware" placeholder. The old procedural version drew a cheap flat gray
// block for that; there's no neutral "locked" art for these yet, and empty
// shelf space reads fine either way. Add a locked-state asset later if
// that's missed.
import 'package:flutter/material.dart';

const String _hudBase = 'assets/den_hud';

class DenBadge {
  final String achievementId, assetPath;
  const DenBadge(this.achievementId, this.assetPath);
}

const List<DenBadge> denBadges = [
  DenBadge('theme_starwars', '$_hudBase/badge_galactic.png'),
  DenBadge('theme_ucs',      '$_hudBase/badge_ucs.png'),
  DenBadge('theme_icons',    '$_hudBase/badge_icons.png'),
  DenBadge('theme_technic',  '$_hudBase/badge_technic.png'),
];

class DenTrophyFamily {
  final String bronzeId, silverId, goldId, assetPath;
  const DenTrophyFamily(this.bronzeId, this.silverId, this.goldId, this.assetPath);
}

const List<DenTrophyFamily> denTrophyFamilies = [
  DenTrophyFamily('sets_10',  'sets_50',   'legendary_sets',       '$_hudBase/trophy_collection.png'),
  DenTrophyFamily('sealed_5', 'sealed_10', 'sealed_25',            '$_hudBase/trophy_sealedvault.png'),
  DenTrophyFamily('value_1k', 'value_10k', 'legendary_portfolio',  '$_hudBase/trophy_portfolio.png'),
  DenTrophyFamily('roi_50',   'roi_200',   'roi_500',              '$_hudBase/trophy_roimaster.png'),
];

/// Null means not earned at any tier -- caller skips rendering entirely.
Color? denTrophyTierColor(Set<String> earned, DenTrophyFamily f) {
  if (earned.contains(f.goldId))   return const Color(0xFFFFD700);
  if (earned.contains(f.silverId)) return const Color(0xFFC0C0C0);
  if (earned.contains(f.bronzeId)) return const Color(0xFFCD7F32);
  return null;
}

const _diamondColor = Color(0xFFAAEEFF);

/// All Den HUD Positioned widgets (badges, trophy shelf + trophies,
/// diamond) for the current [earned] achievement set, in [pxd]-unit scene
/// coordinates (the same 72x48 grid den_scene.dart/den_share_screen.dart
/// already use for everything else). Caller splices this into its own
/// Stack alongside the wall/floor image, CustomPaint, avatar, and ground
/// accessory. Grid coordinates below are carried over unchanged from the
/// original procedural drawing, so the swap to real art didn't need new
/// position tuning.
List<Widget> denHudWidgets({required double pxd, required Set<String> earned}) {
  final widgets = <Widget>[];

  // Badges: x0 = 4 + i*8, columns x0..x0+4 (5 wide), rows 3..8 (6 tall).
  for (var i = 0; i < denBadges.length; i++) {
    final b = denBadges[i];
    if (!earned.contains(b.achievementId)) continue;
    final x0 = 4 + i * 8;
    widgets.add(Positioned(
      left: x0 * pxd, top: 3 * pxd,
      width: 5 * pxd, height: 6 * pxd,
      child: Image.asset(b.assetPath,
          fit: BoxFit.contain, filterQuality: FilterQuality.medium),
    ));
  }

  // Shelf: columns 40..69 (30 wide), rows 22..24 (3 tall) -- only when at
  // least one family has earned a tier, matching the old "why show an
  // empty shelf" gating.
  final anyTrophy = denTrophyFamilies.any((f) => denTrophyTierColor(earned, f) != null);
  if (anyTrophy) {
    widgets.add(Positioned(
      left: 40 * pxd, top: 22 * pxd,
      width: 30 * pxd, height: 3 * pxd,
      child: Image.asset('$_hudBase/shelf.png',
          fit: BoxFit.fill, filterQuality: FilterQuality.medium),
    ));
  }

  // Trophies: x0 = 41 + i*7, columns x0..x0+4 (5 wide), rows 15..21 (7
  // tall). Neutral art tinted per earned tier.
  for (var i = 0; i < denTrophyFamilies.length; i++) {
    final f = denTrophyFamilies[i];
    final color = denTrophyTierColor(earned, f);
    if (color == null) continue;
    final x0 = 41 + i * 7;
    widgets.add(Positioned(
      left: x0 * pxd, top: 15 * pxd,
      width: 5 * pxd, height: 7 * pxd,
      child: Image.asset(f.assetPath,
          color: color, colorBlendMode: BlendMode.srcIn,
          fit: BoxFit.contain, filterQuality: FilterQuality.medium),
    ));
  }

  // Diamond (legendary_all): columns 63..67 (5 wide), rows 5..9 (5 tall).
  // Neutral art tinted icy cyan.
  if (earned.contains('legendary_all')) {
    widgets.add(Positioned(
      left: 63 * pxd, top: 5 * pxd,
      width: 5 * pxd, height: 5 * pxd,
      child: Image.asset('$_hudBase/diamond.png',
          color: _diamondColor, colorBlendMode: BlendMode.srcIn,
          fit: BoxFit.contain, filterQuality: FilterQuality.medium),
    ));
  }

  return widgets;
}
