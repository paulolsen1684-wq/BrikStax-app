// lib/modules/avatar/data/sprite_cosmetics.dart
//
// BACKGROUNDS ONLY now, and still the live, load-bearing catalog for all 52
// of them -- despite the filename, this is not legacy/dead code. The figure
// catalog this file used to hold (helmet/head/outfit/accessory -- ~130
// detailed-crop PNG entries) was retired wholesale in favor of the
// ground-up pixel-art system (data/pixel_cosmetics.dart,
// widgets/pixel_avatar_widget.dart). Backgrounds stayed here on purpose:
// none of the pixel-art batch is background art, backgrounds render through
// an entirely separate image/palette path (backgrounds_art.dart), and there
// was no reason to touch a system that wasn't part of the cutover.
//
// 2026-08-12: removed the last leftovers from the retired figure catalog --
// the CosmeticSlot values (helmet/head/outfit/accessory) and the
// AccessoryPlacement/HeadCoverage enums + SpriteCosmetic.placement/coverage/
// outfitWidthScale/frames fields no catalog entry (all 52 are `background`)
// had used since the cutover. Confirmed nothing referenced them before
// deleting -- see git history if any of this is ever needed for reference.
//
// assetPath is unused for background entries -- rendering goes through
// backgrounds_art.dart's palette/image lookup by id, not Image.asset.
// description carries flavor text ("Something stirs at midnight.") shown
// in the loot roll popup.

import 'package:flutter/material.dart';

enum CosmeticSlot { background }
enum SpriteRarity { common, uncommon, rare, epic, legendary }

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

  // When true AND not yet unlocked, the catalog grid (_SpriteTile in
  // avatar_editor.dart) hides the name behind "???" and swaps the padlock
  // for a sparkle icon instead of revealing what it is -- an ordinary
  // locked item still tells you its name/rarity as something to work
  // toward; a secret item is meant to be a genuine surprise the first
  // time it's granted. Has no effect once the id is in unlockedIds. No
  // background currently sets this true -- the pixel catalog's secret item
  // (px_item_secretxwing) is the only one live right now, see
  // secret_item_service.dart.
  final bool isSecret;

  // Flavor text (e.g. "Something stirs at midnight.") shown in the loot
  // roll popup.
  final String? description;

  const SpriteCosmetic({
    required this.id,
    required this.name,
    required this.slot,
    required this.assetPath,
    required this.rarity,
    this.isSecret = false,
    this.description,
  });
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
