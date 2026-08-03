// lib/modules/avatar/widgets/ground_accessory.dart
//
// Shared Den-scene layout: where the whole avatar figure sits in the scene,
// and where the equipped item renders as its own independent floor object
// (bypassing AvatarWidget's own inline item band -- "beside the figure" and
// "on the floor in front of the shelf" are different reference frames, see
// avatar_widget.dart's showGroundAccessory doc). Both den_scene.dart and
// den_share_screen.dart import this rather than hand-duplicating the
// numbers, so the two can't drift out of sync with each other (they
// otherwise deliberately don't depend on one another).
//
// Post pixel-art cutover: groundAccessoryOf() resolves state.itemId against
// the pixel catalog now (data/pixel_cosmetics.dart), not the old sprite
// catalog's ground-placement accessories, which were retired along with the
// rest of that figure system.
import 'package:flutter/material.dart';
import '../data/pixel_cosmetics.dart';
import '../models/avatar_state.dart';

/// Resolves the equipped item to its cosmetic entry, or null if nothing's
/// equipped. Every pixel item renders as a Den floor object this way (none
/// of them have a "held in hand" pose designed yet, see PixelAvatarWidget's
/// file header), so there's no placement-type filtering the way the old
/// sprite catalog needed.
PixelCosmetic? groundAccessoryOf(AvatarState state) =>
    state.itemId == null ? null : pixelCosmeticsById[state.itemId];

// ── Tunable Den placement ───────────────────────────────────────────────
//
// Two objects, both shared across every avatar/item shown in the Den (not
// per-cosmetic like PixelCosmetic.offsetX/offsetY/scale on the compositor
// itself) -- moving "the avatar" here moves every user's figure in the Den
// the same way, moving "the item" moves every equipped item the same way.
// Tuned live via DenLayoutTunerScreen (dev-only, Settings > Developer,
// same gate as PixelItemTunerScreen) and baked in here by hand afterward,
// same workflow as the per-item tuner.
//
// Base geometry these offsets/scale apply on top of:
//   avatar: size = pxd*36, left = pxd*5, top = pxd*43 - size*.99
//   item:   left = pxd*30, top = pxd*30, width = pxd*19.5, height = pxd*16.5
// (pxd = one grid unit of the Den's 72x48 room grid.)
const double _denAvatarOffsetX = 3.08, _denAvatarOffsetY = 4.57, _denAvatarScale = 1.409;
const double _denItemOffsetX = -6.36, _denItemOffsetY = -0.80, _denItemScale = 1.000;

/// Runtime-only live overrides, used exclusively by DenLayoutTunerScreen to
/// preview unsaved adjustments through the REAL DenSceneContent widget
/// (which reads AchievementService/CollectionProvider directly rather than
/// accepting props, so there's no prop-drilling path for an override --
/// this global is the alternative). `generation` increments on every edit
/// so DenSceneContent's already-running animation ticker can notice a
/// change and rebuild promptly instead of waiting for its own next frame-
/// index change (up to ~450ms away).
///
/// DELIBERATELY NOT PERSISTED ACROSS APP RESTARTS (unlike the per-item
/// tuner's SharedPreferences use) and DELIBERATELY CLEARED in
/// DenLayoutTunerScreen.dispose(): every field here being non-null affects
/// EVERY Den render in the whole app (BrickDenScreen, the Avatar Editor's
/// Den tab, DenShareScreen), not just the tuner screen's own preview --
/// leaving a stale override set would silently shift Den rendering
/// everywhere until the app restarted. Real values only ever reach
/// production by being copied out and hand-baked into the consts above,
/// same as the per-item tuner.
class DenLayoutTuning {
  DenLayoutTuning._();
  static double? avatarOffsetX, avatarOffsetY, avatarScale;
  static double? itemOffsetX, itemOffsetY, itemScale;
  static int generation = 0;

  static void clear() {
    avatarOffsetX = avatarOffsetY = avatarScale = null;
    itemOffsetX = itemOffsetY = itemScale = null;
    generation++;
  }
}

/// The whole avatar figure's box in the Den scene: size (square) + left/top.
/// Both den_scene.dart and den_share_screen.dart call this instead of
/// hand-computing the same formula.
({double left, double top, double size}) denAvatarRect(double pxd) {
  final baseSize = pxd * 36;
  final baseLeft = pxd * 5;
  final baseTop  = pxd * 43 - baseSize * .99;

  final scale   = DenLayoutTuning.avatarScale   ?? _denAvatarScale;
  final offsetX = DenLayoutTuning.avatarOffsetX ?? _denAvatarOffsetX;
  final offsetY = DenLayoutTuning.avatarOffsetY ?? _denAvatarOffsetY;

  final size = baseSize * scale;
  return (
    left: baseLeft - (size - baseSize) / 2 + offsetX * pxd,
    top:  baseTop  - (size - baseSize) / 2 + offsetY * pxd,
    size: size,
  );
}

/// The equipped item's box in the Den scene, positioned against the
/// shelf/table in the background art independent of avatarSize -- resizing
/// the figure doesn't drag the item along with it. [frame] is accepted for
/// call-site compatibility with the old sprite-animation cadence
/// (den_scene.dart's _accFrame) but unused: pixel items are single static
/// images, no per-frame animation exists for this catalog yet.
Widget groundAccessoryWidget({
  required PixelCosmetic accessory,
  required double pxd,
  int frame = 0,
}) {
  final baseLeft = pxd * 30, baseTop = pxd * 30;
  final baseW = pxd * 19.5, baseH = pxd * 16.5;

  final scale   = DenLayoutTuning.itemScale   ?? _denItemScale;
  final offsetX = DenLayoutTuning.itemOffsetX ?? _denItemOffsetX;
  final offsetY = DenLayoutTuning.itemOffsetY ?? _denItemOffsetY;

  final w = baseW * scale, h = baseH * scale;
  return Positioned(
    left: baseLeft - (w - baseW) / 2 + offsetX * pxd,
    top:  baseTop  - (h - baseH) / 2 + offsetY * pxd,
    width: w, height: h,
    child: Image.asset(
      accessory.assetPath,
      fit: BoxFit.contain, filterQuality: FilterQuality.medium,
    ),
  );
}
