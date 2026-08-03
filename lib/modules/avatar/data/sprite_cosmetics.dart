// lib/modules/avatar/data/sprite_cosmetics.dart
//
// BACKGROUNDS ONLY now. The figure catalog this file used to hold (helmet/
// head/outfit/accessory -- ~130 detailed-crop PNG entries) was retired
// wholesale in favor of the ground-up pixel-art system (data/pixel_cosmetics.dart,
// widgets/pixel_avatar_widget.dart). Backgrounds stayed here on purpose:
// none of the pixel-art batch is background art, backgrounds render through
// an entirely separate procedural path (backgrounds_art.dart), and there
// was no reason to touch a system that wasn't part of the cutover.
//
// The CosmeticSlot enum below still declares helmet/head/outfit/accessory
// even though no catalog entry uses them anymore -- several switch
// statements elsewhere (achievement_service.dart, bundle_popup.dart,
// achievement_popup.dart, loot_roll_widget.dart, loot_service.dart) match
// exhaustively over this enum and were left as harmless no-ops on those
// cases rather than hunted down one by one. Safe to actually delete the
// unused enum values (and those switch cases) once nothing references them
// -- not done yet, just not urgent since they're unreachable, not wrong.
//
// assetPath is unused for background entries -- rendering goes through
// backgrounds_art.dart's palette/image lookup by id, not Image.asset.
// description carries flavor text ("Something stirs at midnight.") shown
// in the loot roll popup.

import 'package:flutter/material.dart';

enum CosmeticSlot { helmet, head, outfit, accessory, background }
enum SpriteRarity { common, uncommon, rare, epic, legendary }

// Where an accessory renders and what it draws behind/in front of. Only
// meaningful when slot == accessory.
//   held     -- at the hand, drawn in front of everything (sword, mug)
//   ground   -- beside the feet, drawn behind the outfit (pet, potted plant)
//   floating -- hovering near the character, drawn in front (star, halo)
//   worn     -- body-mounted, drawn behind the outfit so edges peek out (backpack)
enum AccessoryPlacement { held, ground, floating, worn }

// Whether a helmet sits on top of the head (default) or covers the whole
// face. Only meaningful when slot == helmet. A `full` helmet hides the
// head layer entirely while equipped -- no partial masking, no mismatch
// risk between head art and a helmet-specific mask shape.
enum HeadCoverage { topper, full }

extension SpriteRarityX on SpriteRarity {
  Color get color => switch (this) {
    SpriteRarity.common => const Color(0xFF9AA0A3),
    SpriteRarity.uncommon => const Color(0xFF4CAF50),
    SpriteRarity.rare => const Color(0xFF4A90D9),
    SpriteRarity.epic => const Color(0xFFA855F7),
    SpriteRarity.legendary => const Color(0xFFFFD23F),
  };
  String get label => switch (this) {
    SpriteRarity.common => 'Common',
    SpriteRarity.uncommon => 'Uncommon',
    SpriteRarity.rare => 'Rare',
    SpriteRarity.epic => 'Epic',
    SpriteRarity.legendary => 'Legendary',
  };
}

class SpriteCosmetic {
  final String id;
  final String name;
  final CosmeticSlot slot;
  final String assetPath;
  final SpriteRarity rarity;

  // Optional animation frames for epic/legendary gear (e.g.
  // ['outfits_19.png', 'outfits_19_f2.png', 'outfits_19_f3.png', 'outfits_19_f4.png']).
  // Null/empty means the item is static -- renderFrames falls back to
  // [assetPath] so nothing needs a frame list until the art actually exists.
  final List<String>? frames;

  // held is the constructor default; every accessory_XX entry currently
  // overrides it to ground (rendered beside the feet, behind the outfit).
  final AccessoryPlacement placement;
  final HeadCoverage coverage;

  // Outfit-only. The 40 outfit crops split into two batches with visibly
  // different body proportions -- slim garments average height-to-width
  // ~1.64 (shoulder-to-feet content height / canvas width), bulky
  // suits/armor/robes average ~1.25 (same silhouette width reads as a
  // shorter body because the costume itself is wider, e.g. shoulder
  // pads/puffy sleeves). sprite_avatar_widget.dart's outfit compositing
  // fits every outfit to the SAME rendered width (see its slot == outfit
  // branch) so the shoulder-to-feet height stays consistent across
  // outfits regardless of neck-margin cropping differences -- but that
  // scheme alone conflates "wider costume" with "shorter body," so a
  // bulky suit ends up looking shrunken (a visible gap under the head)
  // next to a slim one at the same width. This multiplier corrects for
  // that: computed per outfit as target-ratio / (this outfit's own
  // ratio), so bulky outfits render wider (>1.0) and slim ones render
  // slightly narrower (<1.0) until the displayed shoulder-to-feet height
  // matches across the whole catalog.
  //
  // shoulderY itself went through two measurement passes: the first
  // (single-row, 85%-of-max-width, 2px column stride) was too coarse and
  // both over- and under-shot depending on the outfit. The current values
  // come from a full-Y-resolution scan requiring width to hit 88% of max
  // and hold above 80% for 4 more rows (short enough to not overshoot
  // past the true shoulder line into "cape/robe fully flared out"
  // territory the way an earlier 20-row-plateau attempt did for
  // cape-heavy outfits like Golden Minifigure Suit and Dragon Rider's
  // Scale Vest).
  //
  // target-ratio lands the displayed body height at ~92% of the outfit
  // region's own height budget, not 100% -- a small margin against
  // residual shoulderY error so it clips excess neck margin instead of
  // real shoulder content. An earlier pass used 85%, sized to cover the
  // coarser first-pass shoulderY's much larger error; with the refined
  // measurement above that margin was excessive and visibly UNDER-filled
  // outfits that had little or no real neck margin to begin with (e.g.
  // Corduroy Jacket, shoulderY=0 -- there was never ambiguity there to
  // guard against). Still an automated heuristic, not hand-verified per
  // outfit -- if a specific outfit is still visibly off, that one
  // outfit's shoulderY is the thing to re-measure by eye, not this
  // target/margin again. 1.0 for every non-outfit slot (irrelevant there).
  final double outfitWidthScale;

  // When true AND not yet unlocked, the catalog grid (_SpriteTile in
  // avatar_editor.dart) hides the name behind "???" and swaps the padlock
  // for a sparkle icon instead of revealing what it is -- an ordinary
  // locked item still tells you its name/rarity as something to work
  // toward; a secret item is meant to be a genuine surprise the first
  // time it's granted. Has no effect once the id is in unlockedIds.
  final bool isSecret;

  // Background-only flavor text (e.g. "Something stirs at midnight.") shown
  // in the loot roll popup. Null for every non-background slot, which
  // synthesizes its own description ("Rare Helmet" etc.) instead -- see
  // loot_roll_widget.dart's _RewardInfo.resolve.
  final String? description;

  const SpriteCosmetic({
    required this.id,
    required this.name,
    required this.slot,
    required this.assetPath,
    required this.rarity,
    this.frames,
    this.placement = AccessoryPlacement.held,
    this.coverage = HeadCoverage.topper,
    this.outfitWidthScale = 1.0,
    this.isSecret = false,
    this.description,
  });

  List<String> get renderFrames =>
      (frames != null && frames!.isNotEmpty) ? frames! : [assetPath];

  bool get isAnimated => renderFrames.length > 1;
}

const List<SpriteCosmetic> allSpriteCosmetics = [
  // ═══ BACKGROUNDS ═══
  // Migrated from the old models/cosmetic.dart + data/cosmetics.dart
  // (background-only Cosmetic/CosmeticSlot/CosmeticRarity model, now
  // deleted) so the whole avatar system has one cosmetic model instead of
  // two. assetPath is unused for this slot -- rendering still goes through
  // backgrounds_art.dart's bgPalettes/denImageAsset(id), looked up by the
  // same id used here, not through Image.asset(assetPath) the way every
  // other slot renders. bg_cream is the starter default (see
  // AvatarState.defaults and loot_service.dart's _starterIds).
  SpriteCosmetic(id: 'bg_cream', name: 'Plain Cream', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.common, description: 'The default backdrop.'),
  SpriteCosmetic(id: 'bg_skyline', name: 'City Skyline', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.common, description: 'Downtown at dusk.'),
  SpriteCosmetic(id: 'bg_garage', name: 'Garage', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.common, description: 'Home base for builds.'),
  SpriteCosmetic(id: 'bg_backyard', name: 'Backyard', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.common, description: 'Where it all started.'),
  SpriteCosmetic(id: 'bg_track', name: 'Track', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.common, description: 'Race day.'),
  SpriteCosmetic(id: 'bg_greenhouse', name: 'Greenhouse', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.uncommon, description: 'Growing things, and collections.'),
  SpriteCosmetic(id: 'bg_workshop', name: 'Workshop', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.uncommon, description: 'Gears and grease.'),
  SpriteCosmetic(id: 'bg_reef', name: 'Reef', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.uncommon, description: 'Down among the coral.'),
  SpriteCosmetic(id: 'bg_snowfield', name: 'Snowfield', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.uncommon, description: 'Quiet and frozen.'),
  SpriteCosmetic(id: 'bg_graveyard', name: 'Graveyard', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.rare, description: 'Something stirs at midnight.'),
  SpriteCosmetic(id: 'bg_spacestation', name: 'Space Station', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.rare, description: 'Orbiting above it all.'),
  SpriteCosmetic(id: 'bg_castlehall', name: 'Castle Hall', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.rare, description: 'Banners and stone.'),
  SpriteCosmetic(id: 'bg_volcano', name: 'Volcano', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.epic, description: 'The ground itself glows.'),
  SpriteCosmetic(id: 'bg_shadowrealm', name: 'Shadow Realm', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.epic, description: 'Somewhere between here and there.'),
  SpriteCosmetic(id: 'bg_prismvoid', name: 'Prism Void', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.legendary, description: 'Every color, all at once, forever.'),

  SpriteCosmetic(id: 'bg_meadow', name: 'Meadow', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.common, description: 'A quiet place to spread out a build.'),
  SpriteCosmetic(id: 'bg_pier', name: 'Pier', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.common, description: 'Sets and salt air.'),
  SpriteCosmetic(id: 'bg_attic', name: 'Attic', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.common, description: 'Where the old sets live.'),
  SpriteCosmetic(id: 'bg_carnival', name: 'Carnival', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.common, description: 'Lights, prizes, and trades.'),
  SpriteCosmetic(id: 'bg_desertdunes', name: 'Desert Dunes', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.common, description: 'Dry heat, distant horizon.'),
  SpriteCosmetic(id: 'bg_sunfadedroom', name: 'Sun-Faded Room', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.uncommon, description: 'Light through old curtains.'),
  SpriteCosmetic(id: 'bg_clocktower', name: 'Clocktower', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.uncommon, description: 'Every gear in motion.'),
  SpriteCosmetic(id: 'bg_mosswood', name: 'Moss Wood', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.uncommon, description: 'Quiet and overgrown.'),
  SpriteCosmetic(id: 'bg_huntinglodge', name: 'Hunting Lodge', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.uncommon, description: 'Trophies from past hunts.'),
  SpriteCosmetic(id: 'bg_palecrypt', name: 'Pale Crypt', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.rare, description: 'Something rare rests here.'),
  SpriteCosmetic(id: 'bg_sandstonetemple', name: 'Sandstone Temple', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.rare, description: 'Ancient halls, older bricks.'),
  SpriteCosmetic(id: 'bg_jadejungle', name: 'Jade Jungle', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.rare, description: 'Deep green and humid.'),
  SpriteCosmetic(id: 'bg_glaciercave', name: 'Glacier Cave', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.epic, description: 'Blue ice, perfect silence.'),
  SpriteCosmetic(id: 'bg_wraithmanor', name: 'Wraith Manor', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.epic, description: 'Something watches from the halls.'),
  SpriteCosmetic(id: 'bg_novaskies', name: 'Nova Skies', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.legendary, description: 'The whole sky, lit at once.'),

  SpriteCosmetic(id: 'bg_azurearena', name: 'Azure Arena', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.common, description: 'Where the Azure Blade gets its practice.'),
  SpriteCosmetic(id: 'bg_verdantgrove', name: 'Verdant Grove', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.common, description: 'A quiet clearing for the Verdant Blade.'),
  SpriteCosmetic(id: 'bg_emberpit', name: 'Ember Pit', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.uncommon, description: 'The Crimson Blade runs hot here too.'),
  SpriteCosmetic(id: 'bg_twilightring', name: 'Twilight Ring', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.rare, description: "The Violet Blade's favorite hour."),
  SpriteCosmetic(id: 'bg_twinspires', name: 'Twin Spires', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.epic, description: 'Built for a duelist with Twin Blades.'),
  SpriteCosmetic(id: 'bg_prismcolosseum', name: 'Prism Colosseum', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.legendary, description: "Every color of the Prism Blade, all at once."),
  SpriteCosmetic(id: 'bg_fishingdock', name: 'Fishing Dock', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.common, description: 'The pole never leaves this spot.'),
  SpriteCosmetic(id: 'bg_tackleshed', name: 'Tackle Shed', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.uncommon, description: 'Every lure has its hook.'),
  SpriteCosmetic(id: 'bg_trophypier', name: 'Trophy Pier', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.rare, description: 'Where the Prize Catch got weighed in.'),
  SpriteCosmetic(id: 'bg_sortingroom', name: 'Sorting Room', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.common, description: 'The Brick Box empties out here.'),
  SpriteCosmetic(id: 'bg_workbench', name: 'Workbench', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.uncommon, description: "The Sorting Tray's home base."),
  SpriteCosmetic(id: 'bg_inspectiondesk', name: 'Inspection Desk', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.rare, description: 'Where the Loupe earns its keep.'),
  SpriteCosmetic(id: 'bg_goldenhall', name: 'Golden Hall', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.legendary, description: 'Built to display exactly one Golden Brick.'),
  SpriteCosmetic(id: 'bg_wizardsstudy', name: "Wizard's Study", slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.uncommon, description: "The Spellbook's reading room."),
  SpriteCosmetic(id: 'bg_enchantersalcove', name: "Enchanter's Alcove", slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.rare, description: "The Crystal Wand hums when it's near."),
  SpriteCosmetic(id: 'bg_runechamber', name: 'Rune Chamber', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.epic, description: 'The Rune Orb never stops turning here.'),
  SpriteCosmetic(id: 'bg_observatory', name: 'Observatory', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.uncommon, description: "The Telescope's permanent post."),
  SpriteCosmetic(id: 'bg_maproom', name: 'Map Room', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.rare, description: 'Every Star Map ever charted.'),
  SpriteCosmetic(id: 'bg_meteorcrater', name: 'Meteor Crater', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.epic, description: 'Where the Comet Shard actually landed.'),
  SpriteCosmetic(id: 'bg_bathtime', name: 'Bath Time', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.common, description: "The Rubber Duck's natural habitat."),
  SpriteCosmetic(id: 'bg_coffeenook', name: 'Coffee Nook', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.common, description: 'The Coffee Mug never actually leaves.'),
  SpriteCosmetic(id: 'bg_displaycase', name: 'Display Case', slot: CosmeticSlot.background, assetPath: '', rarity: SpriteRarity.rare, description: 'Where the First Edition Tag stays mint.'),
];

Map<String, SpriteCosmetic> get spriteCosmeticsById =>
    { for (final c in allSpriteCosmetics) c.id: c };

List<SpriteCosmetic> spriteCosmeticsForSlot(CosmeticSlot slot) =>
    allSpriteCosmetics.where((c) => c.slot == slot).toList();
