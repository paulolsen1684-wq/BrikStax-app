// lib/modules/avatar/data/background_cosmetics.dart
//
// The live, load-bearing catalog for all 52 avatar backgrounds. Renamed
// 2026-08-12 from sprite_cosmetics.dart (BackgroundCosmetic/CosmeticRarity
// were SpriteCosmetic/SpriteRarity) -- the old name was a real source of
// confusion, not just an aesthetic one: it read as legacy/dead leftover
// code from the retired figure catalog, when it was actually this file's
// entire live purpose. The figure catalog this file used to ALSO hold
// (helmet/head/outfit/accessory -- ~130 detailed-crop PNG entries) was
// retired wholesale in favor of the ground-up pixel-art system
// (data/pixel_cosmetics.dart, widgets/pixel_avatar_widget.dart). Backgrounds
// stayed here on purpose: none of the pixel-art batch is background art,
// backgrounds render through an entirely separate image/palette path
// (backgrounds_art.dart), and there was no reason to touch a system that
// wasn't part of the cutover.
//
// Same 2026-08-12 pass also removed the last leftovers from the retired
// figure catalog -- the CosmeticSlot values (helmet/head/outfit/accessory,
// now just `background`) and the AccessoryPlacement/HeadCoverage enums +
// BackgroundCosmetic.placement/coverage/outfitWidthScale/frames fields no
// catalog entry (all 52 are `background`) had used since the cutover.
// Confirmed nothing referenced them before deleting -- see git history if
// any of this is ever needed for reference.
//
// CosmeticRarity/CosmeticRarityX are named generically, not "Background*",
// since they're the shared rarity scale both catalogs use -- PixelRarityX
// bridges onto this same enum (.asCosmeticRarity) rather than each catalog
// keeping its own parallel color/label/Brik-value system.
//
// assetPath is unused for background entries -- rendering goes through
// backgrounds_art.dart's palette/image lookup by id, not Image.asset.
// description carries flavor text ("Something stirs at midnight.") shown
// in the loot roll popup.

import 'package:flutter/material.dart';

enum CosmeticSlot { background }
enum CosmeticRarity { common, uncommon, rare, epic, legendary }

extension CosmeticRarityX on CosmeticRarity {
  Color get color => switch (this) {
    CosmeticRarity.common => const Color(0xFF9AA0A3),
    CosmeticRarity.uncommon => const Color(0xFF4CAF50),
    CosmeticRarity.rare => const Color(0xFF4A90D9),
    CosmeticRarity.epic => const Color(0xFFA855F7),
    CosmeticRarity.legendary => const Color(0xFFFFD23F),
  };
  String get label => switch (this) {
    CosmeticRarity.common => 'Common',
    CosmeticRarity.uncommon => 'Uncommon',
    CosmeticRarity.rare => 'Rare',
    CosmeticRarity.epic => 'Epic',
    CosmeticRarity.legendary => 'Legendary',
  };
}

class BackgroundCosmetic {
  final String id;
  final String name;
  final CosmeticSlot slot;
  final String assetPath;
  final CosmeticRarity rarity;

  // When true AND not yet unlocked, the catalog grid (_BgTile in
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

  const BackgroundCosmetic({
    required this.id,
    required this.name,
    required this.slot,
    required this.assetPath,
    required this.rarity,
    this.isSecret = false,
    this.description,
  });
}

const List<BackgroundCosmetic> allBackgroundCosmetics = [
  // ═══ BACKGROUNDS ═══
  // Migrated from the old models/cosmetic.dart + data/cosmetics.dart
  // (background-only Cosmetic/CosmeticSlot/CosmeticRarity model, now
  // deleted) so the whole avatar system has one cosmetic model instead of
  // two. assetPath is unused for this slot -- rendering still goes through
  // backgrounds_art.dart's bgPalettes/denImageAsset(id), looked up by the
  // same id used here, not through Image.asset(assetPath) the way every
  // other slot renders. bg_cream is the starter default (see
  // AvatarState.defaults and loot_service.dart's _starterIds).
  BackgroundCosmetic(id: 'bg_cream', name: 'Plain Cream', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.common, description: 'The default backdrop.'),
  BackgroundCosmetic(id: 'bg_skyline', name: 'City Skyline', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.common, description: 'Downtown at dusk.'),
  BackgroundCosmetic(id: 'bg_garage', name: 'Garage', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.common, description: 'Home base for builds.'),
  BackgroundCosmetic(id: 'bg_backyard', name: 'Backyard', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.common, description: 'Where it all started.'),
  BackgroundCosmetic(id: 'bg_track', name: 'Track', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.common, description: 'Race day.'),
  BackgroundCosmetic(id: 'bg_greenhouse', name: 'Greenhouse', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.uncommon, description: 'Growing things, and collections.'),
  BackgroundCosmetic(id: 'bg_workshop', name: 'Workshop', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.uncommon, description: 'Gears and grease.'),
  BackgroundCosmetic(id: 'bg_reef', name: 'Reef', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.uncommon, description: 'Down among the coral.'),
  BackgroundCosmetic(id: 'bg_snowfield', name: 'Snowfield', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.uncommon, description: 'Quiet and frozen.'),
  BackgroundCosmetic(id: 'bg_graveyard', name: 'Graveyard', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.rare, description: 'Something stirs at midnight.'),
  BackgroundCosmetic(id: 'bg_spacestation', name: 'Space Station', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.rare, description: 'Orbiting above it all.'),
  BackgroundCosmetic(id: 'bg_castlehall', name: 'Castle Hall', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.rare, description: 'Banners and stone.'),
  BackgroundCosmetic(id: 'bg_volcano', name: 'Volcano', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.epic, description: 'The ground itself glows.'),
  BackgroundCosmetic(id: 'bg_shadowrealm', name: 'Shadow Realm', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.epic, description: 'Somewhere between here and there.'),
  BackgroundCosmetic(id: 'bg_prismvoid', name: 'Prism Void', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.legendary, description: 'Every color, all at once, forever.'),

  BackgroundCosmetic(id: 'bg_meadow', name: 'Meadow', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.common, description: 'A quiet place to spread out a build.'),
  BackgroundCosmetic(id: 'bg_pier', name: 'Pier', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.common, description: 'Sets and salt air.'),
  BackgroundCosmetic(id: 'bg_attic', name: 'Attic', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.common, description: 'Where the old sets live.'),
  BackgroundCosmetic(id: 'bg_carnival', name: 'Carnival', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.common, description: 'Lights, prizes, and trades.'),
  BackgroundCosmetic(id: 'bg_desertdunes', name: 'Desert Dunes', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.common, description: 'Dry heat, distant horizon.'),
  BackgroundCosmetic(id: 'bg_sunfadedroom', name: 'Sun-Faded Room', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.uncommon, description: 'Light through old curtains.'),
  BackgroundCosmetic(id: 'bg_clocktower', name: 'Clocktower', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.uncommon, description: 'Every gear in motion.'),
  BackgroundCosmetic(id: 'bg_mosswood', name: 'Moss Wood', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.uncommon, description: 'Quiet and overgrown.'),
  BackgroundCosmetic(id: 'bg_huntinglodge', name: 'Hunting Lodge', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.uncommon, description: 'Trophies from past hunts.'),
  BackgroundCosmetic(id: 'bg_palecrypt', name: 'Pale Crypt', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.rare, description: 'Something rare rests here.'),
  BackgroundCosmetic(id: 'bg_sandstonetemple', name: 'Sandstone Temple', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.rare, description: 'Ancient halls, older bricks.'),
  BackgroundCosmetic(id: 'bg_jadejungle', name: 'Jade Jungle', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.rare, description: 'Deep green and humid.'),
  BackgroundCosmetic(id: 'bg_glaciercave', name: 'Glacier Cave', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.epic, description: 'Blue ice, perfect silence.'),
  BackgroundCosmetic(id: 'bg_wraithmanor', name: 'Wraith Manor', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.epic, description: 'Something watches from the halls.'),
  BackgroundCosmetic(id: 'bg_novaskies', name: 'Nova Skies', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.legendary, description: 'The whole sky, lit at once.'),

  BackgroundCosmetic(id: 'bg_azurearena', name: 'Azure Arena', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.common, description: 'Where the Azure Blade gets its practice.'),
  BackgroundCosmetic(id: 'bg_verdantgrove', name: 'Verdant Grove', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.common, description: 'A quiet clearing for the Verdant Blade.'),
  BackgroundCosmetic(id: 'bg_emberpit', name: 'Ember Pit', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.uncommon, description: 'The Crimson Blade runs hot here too.'),
  BackgroundCosmetic(id: 'bg_twilightring', name: 'Twilight Ring', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.rare, description: "The Violet Blade's favorite hour."),
  BackgroundCosmetic(id: 'bg_twinspires', name: 'Twin Spires', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.epic, description: 'Built for a duelist with Twin Blades.'),
  BackgroundCosmetic(id: 'bg_prismcolosseum', name: 'Prism Colosseum', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.legendary, description: "Every color of the Prism Blade, all at once."),
  BackgroundCosmetic(id: 'bg_fishingdock', name: 'Fishing Dock', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.common, description: 'The pole never leaves this spot.'),
  BackgroundCosmetic(id: 'bg_tackleshed', name: 'Tackle Shed', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.uncommon, description: 'Every lure has its hook.'),
  BackgroundCosmetic(id: 'bg_trophypier', name: 'Trophy Pier', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.rare, description: 'Where the Prize Catch got weighed in.'),
  BackgroundCosmetic(id: 'bg_sortingroom', name: 'Sorting Room', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.common, description: 'The Brick Box empties out here.'),
  BackgroundCosmetic(id: 'bg_workbench', name: 'Workbench', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.uncommon, description: "The Sorting Tray's home base."),
  BackgroundCosmetic(id: 'bg_inspectiondesk', name: 'Inspection Desk', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.rare, description: 'Where the Loupe earns its keep.'),
  BackgroundCosmetic(id: 'bg_goldenhall', name: 'Golden Hall', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.legendary, description: 'Built to display exactly one Golden Brick.'),
  BackgroundCosmetic(id: 'bg_wizardsstudy', name: "Wizard's Study", slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.uncommon, description: "The Spellbook's reading room."),
  BackgroundCosmetic(id: 'bg_enchantersalcove', name: "Enchanter's Alcove", slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.rare, description: "The Crystal Wand hums when it's near."),
  BackgroundCosmetic(id: 'bg_runechamber', name: 'Rune Chamber', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.epic, description: 'The Rune Orb never stops turning here.'),
  BackgroundCosmetic(id: 'bg_observatory', name: 'Observatory', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.uncommon, description: "The Telescope's permanent post."),
  BackgroundCosmetic(id: 'bg_maproom', name: 'Map Room', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.rare, description: 'Every Star Map ever charted.'),
  BackgroundCosmetic(id: 'bg_meteorcrater', name: 'Meteor Crater', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.epic, description: 'Where the Comet Shard actually landed.'),
  BackgroundCosmetic(id: 'bg_bathtime', name: 'Bath Time', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.common, description: "The Rubber Duck's natural habitat."),
  BackgroundCosmetic(id: 'bg_coffeenook', name: 'Coffee Nook', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.common, description: 'The Coffee Mug never actually leaves.'),
  BackgroundCosmetic(id: 'bg_displaycase', name: 'Display Case', slot: CosmeticSlot.background, assetPath: '', rarity: CosmeticRarity.rare, description: 'Where the First Edition Tag stays mint.'),
];

Map<String, BackgroundCosmetic> get backgroundCosmeticsById =>
    { for (final c in allBackgroundCosmetics) c.id: c };
