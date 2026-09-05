// lib/modules/avatar/data/pixel_cosmetics.dart
//
// Catalog for the ground-up pixel-art avatar system -- separate from
// background_cosmetics.dart's BackgroundCosmetic on purpose (that file is
// backgrounds-only now). This is the live figure catalog: head/hat/torso/
// legs/item, rendered through PixelAvatarWidget.
//
// Ids are deliberately NOT the same as background_cosmetics.dart's (head_01
// etc. already means something there) to avoid any risk of collision.
//
// rarity/description are real, load-bearing data now (not just stored
// flavor text): loot_service.dart's reward pool, avatar_editor.dart's
// unlocked/locked grid, and loot_roll_widget.dart's reveal popup all read
// them. Only a handful of starter items (see AvatarState.defaults) start
// unlocked -- everything else must be earned through the loot/reward
// system, same as the background catalog always worked.
import 'package:flutter/material.dart' show Color;
import 'background_cosmetics.dart' show CosmeticRarity, CosmeticRarityX;

enum PixelSlot { head, hat, torso, legs, item }
enum PixelRarity { common, uncommon, rare, epic, legendary }

/// Default paint order for each slot when a cosmetic doesn't override it via
/// PixelCosmetic.zOrder -- back to front, matching pixel_avatar_widget.dart's
/// Z-order comment (legs, head, torso, hat, item) as of pass 11. Kept here
/// rather than duplicated in the widget so PixelItemTunerScreen can read the
/// same numbers a cosmetic's null zOrder actually resolves to.
extension PixelSlotZ on PixelSlot {
  int get defaultZ => switch (this) {
    PixelSlot.legs  => 0,
    PixelSlot.head  => 1,
    PixelSlot.torso => 2,
    PixelSlot.hat   => 3,
    PixelSlot.item  => 4,
  };
}

/// Bridges the pixel catalog's rarity onto CosmeticRarity's existing scale
/// rather than maintaining a second parallel color/label/Brik-value system
/// -- loot_service.dart's economy (brikValue, roll distribution) and any UI
/// styling (rarity color/label) both key off CosmeticRarity already.
extension PixelRarityX on PixelRarity {
  CosmeticRarity get asCosmeticRarity => switch (this) {
    PixelRarity.common    => CosmeticRarity.common,
    PixelRarity.uncommon  => CosmeticRarity.uncommon,
    PixelRarity.rare      => CosmeticRarity.rare,
    PixelRarity.epic      => CosmeticRarity.epic,
    PixelRarity.legendary => CosmeticRarity.legendary,
  };
  Color get color => asCosmeticRarity.color;
  String get label => asCosmeticRarity.label;
}

class PixelCosmetic {
  final String id;
  final String name;
  final PixelSlot slot;
  final String assetPath;
  final PixelRarity rarity;
  final String? description;

  // Optional animation frames for legendary/secret gear (e.g. a chrome
  // shine sweep, an X-Wing engine flicker). Null/empty means the item is
  // static -- renderFrames falls back to [assetPath]. PixelAvatarWidget
  // reads isAnimated to decide whether to run its own frame ticker for that
  // layer at all -- most items are static, so most layers never allocate
  // one. BackgroundCosmetic has no equivalent -- its own frames/
  // renderFrames/isAnimated were removed 2026-08-12 as dead code (no
  // background entry ever set them; rendering for backgrounds never went
  // through Image.asset in the first place).
  final List<String>? frames;

  // Same semantics as BackgroundCosmetic.isSecret: hides the name/preview
  // in the catalog grid until unlocked, and pulls this item into
  // LootService's separate low-odds secret-drop pool instead of the normal
  // tiered roll. Default false since most items are ordinary tiered
  // rewards.
  final bool isSecret;

  // Only obtainable by completing a What's New quest -- excluded from
  // LootService's normal reward pool AND the isSecret drop pool (unlike
  // isSecret alone, which still leaves an item reachable via the rare
  // secret-drop roll). Default false; set true on limited-time quest-only
  // items so they can never drop or be bought in the Brik Shop.
  final bool isQuestExclusive;

  // Per-item nudge on top of the shared slot geometry in pixel_avatar_widget
  // .dart -- the compositor positions every item in a slot with ONE shared
  // formula (e.g. all hats use the same box/anchor), which works until an
  // outlier's own art doesn't match the average. offsetX/offsetY are in the
  // same "unit" system pixel_avatar_widget.dart uses internally (art-pixels
  // on a fixed-height canvas, not screen px); scale multiplies the slot's
  // base width/height, expanding from the item's own center. Default 0/0/1
  // means zero visual change -- every item that hasn't been individually
  // tuned renders exactly like before this field existed. Values are meant
  // to be set here by hand after tuning in PixelItemTunerScreen (dev-only,
  // Settings > Developer), not edited live by real users.
  final double offsetX;
  final double offsetY;
  final double scale;

  // Per-item paint-order override, on top of the slot's own PixelSlotZ
  // .defaultZ -- null (the overwhelming common case) means "paint this item
  // wherever its slot always paints," same as offsetX/offsetY/scale's 0/0/1
  // defaults mean "no positional change." Only needs setting on the rare
  // outlier whose own art doesn't read correctly under its slot's usual
  // order (e.g. a hat whose brim should tuck behind the head instead of the
  // usual hat-over-head). Lower paints first (further back); ties fall back
  // to slot.defaultZ's own relative order. Tuned the same way offsetX/Y/
  // scale are -- live in PixelItemTunerScreen, then hand-copied into the
  // real catalog entry below.
  final int? zOrder;

  const PixelCosmetic({
    required this.id,
    required this.name,
    required this.slot,
    required this.assetPath,
    this.rarity = PixelRarity.common,
    this.description,
    this.frames,
    this.isSecret = false,
    this.isQuestExclusive = false,
    this.offsetX = 0,
    this.offsetY = 0,
    this.scale = 1,
    this.zOrder,
  });

  List<String> get renderFrames =>
      (frames != null && frames!.isNotEmpty) ? frames! : [assetPath];

  bool get isAnimated => renderFrames.length > 1;

  /// Effective paint order: this item's own override if it has one,
  /// otherwise its slot's usual position.
  int get effectiveZ => zOrder ?? slot.defaultZ;

  PixelCosmetic copyWith({
    double? offsetX, double? offsetY, double? scale,
    List<String>? frames,
    int? zOrder,
    bool clearZOrder = false,
  }) =>
      PixelCosmetic(
        id: id, name: name, slot: slot, assetPath: assetPath,
        rarity: rarity, description: description,
        frames: frames ?? this.frames, isSecret: isSecret,
        offsetX: offsetX ?? this.offsetX,
        offsetY: offsetY ?? this.offsetY,
        scale: scale ?? this.scale,
        zOrder: clearZOrder ? null : (zOrder ?? this.zOrder),
      );
}

const List<PixelCosmetic> allPixelCosmetics = [
  PixelCosmetic(id: 'px_head_01', name: 'Head 01', slot: PixelSlot.head, assetPath: 'assets/avatar_pixel/heads/head_01.png',
    offsetX: 0.00, offsetY: 0.00, scale: 0.980,
  ),
  PixelCosmetic(id: 'px_head_02', name: 'Head 02', slot: PixelSlot.head, assetPath: 'assets/avatar_pixel/heads/head_02.png'),

  PixelCosmetic(id: 'px_hat_bucket',  name: 'Bucket Hat',    slot: PixelSlot.hat, assetPath: 'assets/avatar_pixel/hats/hat_01_bucket.png', offsetX: -0.29, offsetY: -2.47, scale: 0.849),
  PixelCosmetic(id: 'px_hat_safari',  name: 'Safari Hat',    slot: PixelSlot.hat, assetPath: 'assets/avatar_pixel/hats/hat_02_safari.png',
    offsetX: 0.00, offsetY: 0.00, scale: 0.900,
  ),
  PixelCosmetic(id: 'px_hat_redcap',  name: 'Red Cap',       slot: PixelSlot.hat, assetPath: 'assets/avatar_pixel/hats/hat_03_redcap.png',
    offsetX: -1.25, offsetY: 0.00, scale: 0.800,
  ),
  PixelCosmetic(id: 'px_hat_hardhat', name: 'Hard Hat',      slot: PixelSlot.hat, assetPath: 'assets/avatar_pixel/hats/hat_04_hardhat.png',
    offsetX: 0.00, offsetY: 1.00, scale: 0.900,
  ),
  PixelCosmetic(id: 'px_hat_beanie',  name: 'Beanie',        slot: PixelSlot.hat, assetPath: 'assets/avatar_pixel/hats/hat_05_beanie.png'),

  // Wave 1-3 additions below (~75 images added at once; Wave 4's names went
  // entirely unused -- those images were never actually generated, only
  // Waves 1-3 plus a handful of gaps within them exist as real files).
  // Matched to art by visual content, not by generation order -- a spot
  // check showed file creation order does NOT reliably match wave/list
  // order, so each one was eyeballed against a contact-sheet grid rather
  // than assigned positionally. Several form complete matching sets across
  // hat+torso+legs+item (Ice Base Trooper, Castle Wizard, Harbor Watch,
  // Sandstone Ruins, Tidepool Explorer, Jungle Explorer, Pirate variants) --
  // that cross-slot coherence is what gives the matching confidence, not
  // exhaustive verification of all 75.
  PixelCosmetic(id: 'px_hat_skyfargoggle', name: "Skyfarer's Goggle Cap", slot: PixelSlot.hat, rarity: PixelRarity.rare, description: "Built for reading wind currents no one else can see.", assetPath: 'assets/avatar_pixel/hats/hat_06_skyfargoggle.png', offsetX: 0.07, offsetY: 1.6, scale: 0.753),
  PixelCosmetic(id: 'px_hat_gardensun', name: 'Garden Sun Hat', slot: PixelSlot.hat, rarity: PixelRarity.common, description: 'Passed down through a family of enthusiastic backyard growers.', assetPath: 'assets/avatar_pixel/hats/hat_07_gardensun.png',
    offsetX: 0.00, offsetY: 0.00, scale: 0.800,
  ),
  PixelCosmetic(id: 'px_hat_sandstonewrap', name: 'Sandstone Ruins Wrap', slot: PixelSlot.hat, rarity: PixelRarity.rare, description: 'Once belonged to someone who mapped ruins no map had ever shown.', assetPath: 'assets/avatar_pixel/hats/hat_08_sandstonewrap.png',
    offsetX: 1.87, offsetY: 1.03, scale: 0.880,
  ),
  PixelCosmetic(id: 'px_hat_harborwatch', name: 'Harbor Watch Helmet', slot: PixelSlot.hat, rarity: PixelRarity.uncommon, description: 'Scoured smooth by decades of salt spray.', assetPath: 'assets/avatar_pixel/hats/hat_09_harborwatch.png',
    offsetX: 0.62, offsetY: 13.64, scale: 1.520,
  ),
  PixelCosmetic(id: 'px_hat_tidepoolhood', name: "Tidepool Explorer's Hood", slot: PixelSlot.hat, rarity: PixelRarity.uncommon, description: "Damp more often than dry, and its wearer wouldn't have it any other way.", assetPath: 'assets/avatar_pixel/hats/hat_10_tidepoolhood.png',
    offsetX: -0.12, offsetY: 8.86, scale: 1.360,
  ),
  PixelCosmetic(id: 'px_hat_fishermanbucket', name: "Fisherman's Bucket Hat", slot: PixelSlot.hat, rarity: PixelRarity.common, description: 'Smells like brine no matter how long it sits in the sun.', assetPath: 'assets/avatar_pixel/hats/hat_11_fishermanbucket.png',
    offsetX: 0.00, offsetY: 1.32, scale: 0.680,
  ),
  PixelCosmetic(id: 'px_hat_cyclisthelmet', name: 'Rookie Cyclist Helmet', slot: PixelSlot.hat, rarity: PixelRarity.common, description: 'Still has the price tag mark faintly visible under the paint.', assetPath: 'assets/avatar_pixel/hats/hat_12_cyclisthelmet.png', offsetX: 0.09, offsetY: -0.19, scale: 0.893),
  PixelCosmetic(id: 'px_hat_bakercap', name: "Baker's Cap", slot: PixelSlot.hat, rarity: PixelRarity.common, description: 'Dusted permanently with just a little too much flour.', assetPath: 'assets/avatar_pixel/hats/hat_13_bakercap.png', offsetX: -0.34, offsetY: -3.1, scale: 0.91),
  PixelCosmetic(id: 'px_hat_piratetricorn', name: "Pirate Captain's Tricorn", slot: PixelSlot.hat, rarity: PixelRarity.uncommon, description: "Worn by someone who's never once lost a bet at sea.", assetPath: 'assets/avatar_pixel/hats/hat_14_piratetricorn.png'),
  PixelCosmetic(id: 'px_hat_junglepith', name: "Jungle Explorer's Pith Helmet", slot: PixelSlot.hat, rarity: PixelRarity.rare, description: 'Has survived more vines and dead ends than its wearer likes to admit.', assetPath: 'assets/avatar_pixel/hats/hat_15_junglepith.png',
    offsetX: 0.06, offsetY: 0.42, scale: 0.820,
  ),
  PixelCosmetic(id: 'px_hat_lighthousecap', name: "Lighthouse Keeper's Cap", slot: PixelSlot.hat, rarity: PixelRarity.uncommon, description: 'Worn through countless nights watching for ships that never came.', assetPath: 'assets/avatar_pixel/hats/hat_16_lighthousecap.png',
    offsetX: 0.00, offsetY: 0.00, scale: 0.860,
  ),
  PixelCosmetic(id: 'px_hat_cityhardhat', name: "City Worker's Hard Hat", slot: PixelSlot.hat, rarity: PixelRarity.common, description: 'Dented in all the places that matter.', assetPath: 'assets/avatar_pixel/hats/hat_17_cityhardhat.png',
    offsetX: 0.12, offsetY: 1.52, scale: 0.920,
  ),
  PixelCosmetic(id: 'px_hat_piratebandana', name: 'Pirate Crew Bandana', slot: PixelSlot.hat, rarity: PixelRarity.uncommon, description: "Tied the same way it's been tied for a hundred voyages.", assetPath: 'assets/avatar_pixel/hats/hat_18_piratebandana.png',
    offsetX: 1.68, offsetY: 4.08, scale: 0.740,
  ),
  PixelCosmetic(id: 'px_hat_wizardstar', name: "Castle Wizard's Star Hat", slot: PixelSlot.hat, rarity: PixelRarity.rare, description: 'The stars stitched on it are said to shift position when no one\'s watching.', assetPath: 'assets/avatar_pixel/hats/hat_19_wizardstar.png',
    offsetX: 1.31, offsetY: -3.60, scale: 1.520,
  ),
  PixelCosmetic(id: 'px_hat_icetrooper', name: 'Ice Base Trooper Helmet', slot: PixelSlot.hat, rarity: PixelRarity.epic, description: 'Rated for cold that would stop most expeditions before they started.', assetPath: 'assets/avatar_pixel/hats/hat_20_icetrooper.png',
    offsetX: -0.06, offsetY: 9.15, scale: 1.320,
  ),
  PixelCosmetic(id: 'px_hat_spacemanhelmet', name: 'Classic Spaceman Helmet', slot: PixelSlot.hat, rarity: PixelRarity.common, description: 'Standard issue for anyone brave enough to leave the launchpad.', assetPath: 'assets/avatar_pixel/hats/hat_21_spacemanhelmet.png',
    // zOrder was tuned to 4 (item's own defaultZ) -- ties, and the sort's
    // insertion-index tiebreak resolved that tie right back to hat's normal
    // behind-item position, making the override a silent no-op. Bumped to 5
    // (strictly above item's 4) to actually deliver what tying at 4 was
    // clearly reaching for: paint in front of an equipped item.
    offsetX: 0.13, offsetY: 7.39, scale: 1.500, zOrder: 5,
  ),

  // Legendary/secret tier -- first entries with real animation frames
  // (PixelCosmetic.frames/renderFrames/isAnimated). A matched "Chrome"
  // legendary set across all four figure slots (hat/torso/legs/item), each
  // a 4-frame shine sweep. Torso (Chrome Jacket) and legs (Chrome Greaves)
  // were pulled 2026-08-25 (couldn't get their positioning/scale to read
  // right) for a redo -- torso came back 2026-08-26 with new art (see its
  // own entry, down in the torso section, for detail); legs is still
  // pending, re-add it here once new art exists for it too. The X-Wing
  // item down in the items section is the first isSecret pixel entry,
  // 8 frames.
  PixelCosmetic(
    id: 'px_hat_legendarychrome', name: 'Chrome Helmet', slot: PixelSlot.hat,
    rarity: PixelRarity.legendary,
    description: 'Polished so bright it doubles as a mirror on parade day.',
    assetPath: 'assets/avatar_pixel/hats/legendary_chromehelmet_f1.png',
    frames: [
      'assets/avatar_pixel/hats/legendary_chromehelmet_f1.png',
      'assets/avatar_pixel/hats/legendary_chromehelmet_f2.png',
      'assets/avatar_pixel/hats/legendary_chromehelmet_f3.png',
      'assets/avatar_pixel/hats/legendary_chromehelmet_f4.png',
    ],
    offsetX: -0.25, offsetY: 4.75, scale: 1.160,
  ),

  PixelCosmetic(id: 'px_torso_yellowjacket', name: 'Yellow Jacket',  slot: PixelSlot.torso, assetPath: 'assets/avatar_pixel/torsos/torso_01_yellowjacket.png',
    offsetX: -0.28, offsetY: 0.44, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_torso_plaid',        name: 'Plaid Flannel',  slot: PixelSlot.torso, assetPath: 'assets/avatar_pixel/torsos/torso_02_plaid.png'),
  PixelCosmetic(id: 'px_torso_graysweater',  name: 'Gray Sweater',   slot: PixelSlot.torso, assetPath: 'assets/avatar_pixel/torsos/torso_03_graysweater.png',
    offsetX: -0.28, offsetY: -0.19, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_torso_overalls',     name: 'Green Overalls', slot: PixelSlot.torso, assetPath: 'assets/avatar_pixel/torsos/torso_04_overalls.png',
    offsetX: -0.23, offsetY: 2.39, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_torso_redvest',      name: 'Red Vest',       slot: PixelSlot.torso, assetPath: 'assets/avatar_pixel/torsos/torso_05_redvest.png',
    offsetX: -0.17, offsetY: 2.39, scale: 1.000,
  ),

  PixelCosmetic(id: 'px_torso_sandstonetunic', name: 'Sandstone Ruins Tunic', slot: PixelSlot.torso, rarity: PixelRarity.rare, description: 'Sun-bleached from seasons spent somewhere the map insisted was empty.', assetPath: 'assets/avatar_pixel/torsos/torso_06_sandstonetunic.png',
    offsetX: -0.11, offsetY: 2.57, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_torso_builderutility', name: "Builder's Utility Jacket", slot: PixelSlot.torso, rarity: PixelRarity.common, description: 'Pockets deep enough to hold a whole handful of loose pieces.', assetPath: 'assets/avatar_pixel/torsos/torso_07_builderutility.png',
    offsetX: 0.17, offsetY: 1.88, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_torso_cyclistjersey', name: 'Rookie Cyclist Jersey', slot: PixelSlot.torso, rarity: PixelRarity.common, description: 'Still smells new, still a little too stiff.', assetPath: 'assets/avatar_pixel/torsos/torso_08_cyclistjersey.png',
    offsetX: -0.11, offsetY: 1.70, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_torso_campfiresweater', name: 'Campfire Sweater', slot: PixelSlot.torso, rarity: PixelRarity.common, description: "Smells faintly of woodsmoke no matter how many times it's washed.", assetPath: 'assets/avatar_pixel/torsos/torso_09_campfiresweater.png',
    offsetX: -0.28, offsetY: 1.70, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_torso_tidepoolvest', name: "Tidepool Explorer's Vest", slot: PixelSlot.torso, rarity: PixelRarity.uncommon, description: 'Its pockets have held more curious little shells than anyone can remember.', assetPath: 'assets/avatar_pixel/torsos/torso_10_tidepoolvest.png'),
  PixelCosmetic(id: 'px_torso_harborwatchsuit', name: 'Harbor Watch Suit', slot: PixelSlot.torso, rarity: PixelRarity.uncommon, description: 'Built for someone who trusts the sea more than dry land.', assetPath: 'assets/avatar_pixel/torsos/torso_11_harborwatchsuit.png'),
  PixelCosmetic(id: 'px_torso_fishermanoilskin', name: "Fisherman's Oilskin Jacket", slot: PixelSlot.torso, rarity: PixelRarity.common, description: 'Waterproof in theory, character-building in practice.', assetPath: 'assets/avatar_pixel/torsos/torso_12_fishermanoilskin.png'),
  PixelCosmetic(id: 'px_torso_snowtrekkerparka', name: 'Snow Trekker Parka', slot: PixelSlot.torso, rarity: PixelRarity.uncommon, description: "Has weathered blizzards its owner would rather forget.", assetPath: 'assets/avatar_pixel/torsos/torso_13_snowtrekkerparka.png',
    offsetX: -0.11, offsetY: 2.26, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_torso_porchcardigan', name: "Porch Sitter's Cardigan", slot: PixelSlot.torso, rarity: PixelRarity.common, description: 'Soft from years of being exactly the right amount of warm.', assetPath: 'assets/avatar_pixel/torsos/torso_14_porchcardigan.png'),
  PixelCosmetic(id: 'px_torso_bakerapron', name: "Baker's Apron", slot: PixelSlot.torso, rarity: PixelRarity.common, description: 'Never fully clean, always ready for one more batch.', assetPath: 'assets/avatar_pixel/torsos/torso_15_bakerapron.png',
    offsetX: 0.11, offsetY: -0.31, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_torso_mailcarrieruniform', name: 'City Mailcarrier Uniform', slot: PixelSlot.torso, rarity: PixelRarity.common, description: 'Crisp at 8 AM, a little less crisp by noon.', assetPath: 'assets/avatar_pixel/torsos/torso_16_mailcarrieruniform.png',
    offsetX: -0.23, offsetY: 1.00, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_torso_cityworkervest', name: "City Worker's Vest", slot: PixelSlot.torso, rarity: PixelRarity.common, description: 'Reflective enough to be seen from three blocks away.', assetPath: 'assets/avatar_pixel/torsos/torso_17_cityworkervest.png',
    offsetX: -0.17, offsetY: 0.94, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_torso_lighthousecoat', name: "Lighthouse Keeper's Coat", slot: PixelSlot.torso, rarity: PixelRarity.uncommon, description: 'Heavy enough to withstand a storm that never seems to end.', assetPath: 'assets/avatar_pixel/torsos/torso_18_lighthousecoat.png',
    offsetX: -0.45, offsetY: 1.57, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_torso_gardenoveralls', name: 'Garden Overalls Top', slot: PixelSlot.torso, rarity: PixelRarity.common, description: 'Stained green at the knees from an honest day\'s work.', assetPath: 'assets/avatar_pixel/torsos/torso_19_gardenoveralls.png', offsetX: -0.38, offsetY: -0.05, scale: 0.912),
  PixelCosmetic(id: 'px_torso_piratecoat', name: "Pirate Captain's Coat", slot: PixelSlot.torso, rarity: PixelRarity.uncommon, description: 'Gold buttons polished, reputation slightly less so.', assetPath: 'assets/avatar_pixel/torsos/torso_20_piratecoat.png', offsetX: 0.32, offsetY: -1.4, scale: 0.946),
  PixelCosmetic(id: 'px_torso_piratecrewshirt', name: 'Pirate Crew Shirt', slot: PixelSlot.torso, rarity: PixelRarity.uncommon, description: 'Salt-stiff and proud of it.', assetPath: 'assets/avatar_pixel/torsos/torso_21_piratecrewshirt.png', offsetX: 0, offsetY: -0.19, scale: 0.885),
  PixelCosmetic(id: 'px_torso_knightarmor', name: "Castle Knight's Armor", slot: PixelSlot.torso, rarity: PixelRarity.uncommon, description: "Bears a scratch from a duel that's grown taller in the retelling.", assetPath: 'assets/avatar_pixel/torsos/torso_22_knightarmor.png', offsetX: -0.32, offsetY: 1.45, scale: 0.943),
  PixelCosmetic(id: 'px_torso_junglevest', name: "Jungle Explorer's Vest", slot: PixelSlot.torso, rarity: PixelRarity.rare, description: 'Every pocket holds something found and nothing thrown away.', assetPath: 'assets/avatar_pixel/torsos/torso_23_junglevest.png', offsetX: 0.09, offsetY: 1.11, scale: 0.855),
  PixelCosmetic(id: 'px_torso_wizardstarrobe', name: "Castle Wizard's Star Robe", slot: PixelSlot.torso, rarity: PixelRarity.rare, description: 'Its crescent moon glows the faintest bit brighter on clear nights.', assetPath: 'assets/avatar_pixel/torsos/torso_24_wizardstarrobe.png', offsetX: -0.45, offsetY: 0.44, scale: 0.933),
  PixelCosmetic(id: 'px_torso_icetroopersuit', name: 'Ice Base Trooper Suit', slot: PixelSlot.torso, rarity: PixelRarity.epic, description: 'The frost emblem never quite melts, no matter the season.', assetPath: 'assets/avatar_pixel/torsos/torso_25_icetroopersuit.png', offsetX: -0.2, offsetY: 2.28, scale: 1.01),

  // Chrome Jacket redone 2026-08-26 with new art (assets/chestani/, a
  // chrome jacket + wind-blown red scarf, 4 frames) after the original
  // legendary_chrometorso_* art was pulled 2026-08-25 -- see the Legendary/
  // secret tier comment below for the rest of this set's history.
  // offsetX/offsetY/scale re-tuned against the new art via
  // PixelItemTunerScreen and confirmed 2026-08-26 (was a carried-over
  // guess from the old art before that).
  PixelCosmetic(
    id: 'px_torso_legendarychrome', name: 'Chrome Jacket', slot: PixelSlot.torso,
    rarity: PixelRarity.legendary,
    description: "The scarf is just for style -- the shine does all the talking.",
    assetPath: 'assets/chestani/chromtorso1.png',
    frames: [
      'assets/chestani/chromtorso1.png',
      'assets/chestani/chromtorso2.png',
      'assets/chestani/chromtorso3.png',
      'assets/chestani/chromtorso4.png',
    ],
    offsetX: 1.97, offsetY: 3.01, scale: 1.140,
  ),

  PixelCosmetic(id: 'px_legs_bluejeans',  name: 'Blue Jeans',      slot: PixelSlot.legs, assetPath: 'assets/avatar_pixel/legs/legs_01_bluejeans.png',
    offsetX: 0.00, offsetY: 3.96, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_legs_redpants',   name: 'Red Pants',       slot: PixelSlot.legs, assetPath: 'assets/avatar_pixel/legs/legs_02_redpants.png',
    offsetX: 0.00, offsetY: 4.83, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_legs_graysweats', name: 'Gray Sweatpants', slot: PixelSlot.legs, assetPath: 'assets/avatar_pixel/legs/legs_03_graysweats.png',
    offsetX: -0.11, offsetY: 4.77, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_legs_greenshorts',name: 'Green Shorts',    slot: PixelSlot.legs, assetPath: 'assets/avatar_pixel/legs/legs_04_greenshorts.png',
    offsetX: -0.28, offsetY: 3.77, scale: 1.000,
  ),

  PixelCosmetic(id: 'px_legs_harborwatch', name: 'Harbor Watch Trousers', slot: PixelSlot.legs, rarity: PixelRarity.uncommon, description: "Rivets rusted just enough to prove they've earned their keep.", assetPath: 'assets/avatar_pixel/legs/legs_05_harborwatch.png',
    offsetX: -0.17, offsetY: 2.95, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_legs_junglecargo', name: "Jungle Explorer's Cargo Trousers", slot: PixelSlot.legs, rarity: PixelRarity.rare, description: 'Every pocket holds a different half-finished field note.', assetPath: 'assets/avatar_pixel/legs/legs_06_junglecargo.png',
    offsetX: 0.40, offsetY: 2.01, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_legs_sandstone', name: 'Sandstone Ruins Trousers', slot: PixelSlot.legs, rarity: PixelRarity.rare, description: "Carry dust from ruins that most maps swear don't exist.", assetPath: 'assets/avatar_pixel/legs/legs_07_sandstone.png',
    offsetX: 0.74, offsetY: 4.33, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_legs_cyclistshorts', name: 'Rookie Cyclist Shorts', slot: PixelSlot.legs, rarity: PixelRarity.common, description: 'Still adjusting to actually being used for cycling.', assetPath: 'assets/avatar_pixel/legs/legs_08_cyclistshorts.png',
    offsetX: 1.07, offsetY: 4.77, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_legs_cityworker', name: "City Worker's Trousers", slot: PixelSlot.legs, rarity: PixelRarity.common, description: 'The tool loop has never once been empty.', assetPath: 'assets/avatar_pixel/legs/legs_09_cityworker.png',
    offsetX: 0.34, offsetY: 3.89, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_legs_tidepool', name: "Tidepool Explorer's Trousers", slot: PixelSlot.legs, rarity: PixelRarity.uncommon, description: 'Rolled up just enough to keep the hems dry -- usually.', assetPath: 'assets/avatar_pixel/legs/legs_10_tidepool.png',
    offsetX: 0.40, offsetY: 4.21, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_legs_fishermanwaders', name: "Fisherman's Waders", slot: PixelSlot.legs, rarity: PixelRarity.common, description: 'Have stood in more cold water than anyone should willingly choose to.', assetPath: 'assets/avatar_pixel/legs/legs_11_fishermanwaders.png',
    offsetX: -0.11, offsetY: 4.46, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_legs_snowtrekker', name: 'Snow Trekker Trousers', slot: PixelSlot.legs, rarity: PixelRarity.uncommon, description: 'Never quite dries out between expeditions.', assetPath: 'assets/avatar_pixel/legs/legs_12_snowtrekker.png',
    offsetX: 0.06, offsetY: 3.77, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_legs_porchslacks', name: "Porch Sitter's Slacks", slot: PixelSlot.legs, rarity: PixelRarity.common, description: "Comfortable enough to forget you're wearing them.", assetPath: 'assets/avatar_pixel/legs/legs_13_porchslacks.png',
    offsetX: 0.00, offsetY: 4.71, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_legs_bakertrousers', name: "Baker's Trousers", slot: PixelSlot.legs, rarity: PixelRarity.common, description: 'Flour-dusted by 6 AM, every single morning.', assetPath: 'assets/avatar_pixel/legs/legs_14_bakertrousers.png',
    offsetX: 0.23, offsetY: 3.58, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_legs_mailcarrier', name: 'City Mailcarrier Trousers', slot: PixelSlot.legs, rarity: PixelRarity.common, description: 'Pressed each morning, rumpled by the third stop.', assetPath: 'assets/avatar_pixel/legs/legs_15_mailcarrier.png',
    offsetX: 0.00, offsetY: 3.89, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_legs_wizardstar', name: "Castle Wizard's Star Trousers", slot: PixelSlot.legs, rarity: PixelRarity.rare, description: 'The single stitched star has never once faded.', assetPath: 'assets/avatar_pixel/legs/legs_16_wizardstar.png',
    offsetX: -0.23, offsetY: 4.83, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_legs_spaceman', name: 'Classic Spaceman Trousers', slot: PixelSlot.legs, rarity: PixelRarity.common, description: 'Standard-issue, built to survive re-entry and then some.', assetPath: 'assets/avatar_pixel/legs/legs_17_spaceman.png',
    offsetX: 0.51, offsetY: 4.58, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_legs_emberbattle', name: 'Ember Battle Greaves', slot: PixelSlot.legs, rarity: PixelRarity.epic, description: 'Leaves a faint scorch mark on anything they brush against.', assetPath: 'assets/avatar_pixel/legs/legs_18_emberbattle.png',
    offsetX: -0.06, offsetY: 4.65, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_legs_weekenddenim2', name: 'Weekend Denim', slot: PixelSlot.legs, rarity: PixelRarity.common, description: 'Faded just enough to feel like an old friend.', assetPath: 'assets/avatar_pixel/legs/legs_19_weekenddenim2.png',
    offsetX: -0.17, offsetY: 5.34, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_legs_campfire', name: 'Campfire Trousers', slot: PixelSlot.legs, rarity: PixelRarity.common, description: 'Warm enough for chilly nights, sturdy enough for late-night marshmallow duty.', assetPath: 'assets/avatar_pixel/legs/legs_20_campfire.png',
    offsetX: -0.17, offsetY: 4.77, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_legs_piratecrew', name: 'Pirate Crew Trousers', slot: PixelSlot.legs, rarity: PixelRarity.uncommon, description: 'Rolled up out of habit, even on dry land.', assetPath: 'assets/avatar_pixel/legs/legs_21_piratecrew.png',
    offsetX: 0.00, offsetY: 4.46, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_legs_knightgreaves', name: "Castle Knight's Greaves", slot: PixelSlot.legs, rarity: PixelRarity.uncommon, description: "Clank just loud enough to announce who's coming.", assetPath: 'assets/avatar_pixel/legs/legs_22_knightgreaves.png',
    offsetX: -0.17, offsetY: 4.52, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_legs_frontierscout', name: 'Frontier Scout Trousers', slot: PixelSlot.legs, rarity: PixelRarity.uncommon, description: 'Reinforced at the knee from one too many careless landings.', assetPath: 'assets/avatar_pixel/legs/legs_23_frontierscout.png',
    offsetX: 0.11, offsetY: 4.52, scale: 1.000,
  ),
  PixelCosmetic(id: 'px_legs_icetrooper', name: 'Ice Base Trooper Greaves', slot: PixelSlot.legs, rarity: PixelRarity.epic, description: 'Built to keep moving long after the cold should have stopped them.', assetPath: 'assets/avatar_pixel/legs/legs_24_icetrooper.png',
    offsetX: -1.07, offsetY: 3.27, scale: 1.000,
  ),

  PixelCosmetic(id: 'px_item_trophy',     name: 'Trophy',       slot: PixelSlot.item, assetPath: 'assets/avatar_pixel/items/item_01_trophy.png',
    offsetX: -3.17, offsetY: -10.93, scale: 1.280,
  ),
  PixelCosmetic(id: 'px_item_brickstack', name: 'Brick Stack',  slot: PixelSlot.item, assetPath: 'assets/avatar_pixel/items/item_02_brickstack.png',
    offsetX: -5.49, offsetY: -12.31, scale: 1.392,
  ),
  PixelCosmetic(id: 'px_item_wateringcan',name: 'Watering Can', slot: PixelSlot.item, assetPath: 'assets/avatar_pixel/items/item_03_wateringcan.png',
    offsetX: -11.29, offsetY: -12.28, scale: 1.419,
  ),
  PixelCosmetic(id: 'px_item_toolbox',    name: 'Toolbox',      slot: PixelSlot.item, assetPath: 'assets/avatar_pixel/items/item_04_toolbox.png',
    offsetX: -7.01, offsetY: -10.58, scale: 1.246,
  ),

  PixelCosmetic(id: 'px_item_harboranchor', name: 'Harbor Watch Anchor', slot: PixelSlot.item, rarity: PixelRarity.uncommon, description: "Hasn't moved in years, and somehow still feels ready to.", assetPath: 'assets/avatar_pixel/items/item_05_harboranchor.png',
    offsetX: -7.35, offsetY: -18.52, scale: 1.705,
  ),
  PixelCosmetic(id: 'px_item_tidepoolnet', name: "Tidepool Explorer's Net", slot: PixelSlot.item, rarity: PixelRarity.uncommon, description: 'Scooped up more curiosities than complaints.', assetPath: 'assets/avatar_pixel/items/item_06_tidepoolnet.png',
    offsetX: -10.10, offsetY: -24.39, scale: 1.775,
  ),
  PixelCosmetic(id: 'px_item_lighthouselamp', name: "Lighthouse Keeper's Lamp", slot: PixelSlot.item, rarity: PixelRarity.uncommon, description: "Its light has guided more ships home than its keeper will ever know.", assetPath: 'assets/avatar_pixel/items/item_07_lighthouselamp.png',
    offsetX: -5.91, offsetY: -15.82, scale: 1.669,
  ),
  PixelCosmetic(id: 'px_item_camplantern', name: 'Camp Lantern', slot: PixelSlot.item, rarity: PixelRarity.common, description: "Lights the way back to camp long after the fire's gone out.", assetPath: 'assets/avatar_pixel/items/item_08_camplantern.png',
    offsetX: -5.12, offsetY: -12.87, scale: 1.444,
  ),
  PixelCosmetic(id: 'px_item_alchemistcauldron', name: "Alchemist's Cauldron", slot: PixelSlot.item, rarity: PixelRarity.rare, description: "Bubbles occasionally, even when nothing's cooking.", assetPath: 'assets/avatar_pixel/items/item_09_alchemistcauldron.png',
    offsetX: -7.64, offsetY: -15.45, scale: 1.524,
  ),
  PixelCosmetic(id: 'px_item_sandstonetablet', name: 'Sandstone Ruins Tablet', slot: PixelSlot.item, rarity: PixelRarity.rare, description: "Its symbols mean something -- nobody's quite cracked what, yet.", assetPath: 'assets/avatar_pixel/items/item_10_sandstonetablet.png',
    offsetX: -6.73, offsetY: -17.83, scale: 1.621,
  ),
  PixelCosmetic(id: 'px_item_alchemistpotionrack', name: "Alchemist's Potion Rack", slot: PixelSlot.item, rarity: PixelRarity.epic, description: "Three bottles, three colors, one very firm rule about not mixing them.", assetPath: 'assets/avatar_pixel/items/item_11_alchemistpotionrack.png',
    offsetX: -8.71, offsetY: -17.93, scale: 1.640,
  ),
  PixelCosmetic(id: 'px_item_cyclistbike', name: "Rookie Cyclist's Bike", slot: PixelSlot.item, rarity: PixelRarity.common, description: 'Still has that new-bike shine, mostly.', assetPath: 'assets/avatar_pixel/items/item_12_cyclistbike.png',
    offsetX: -11.63, offsetY: -23.77, scale: 1.873,
  ),
  PixelCosmetic(id: 'px_item_fishermanbucket', name: "Fisherman's Bucket", slot: PixelSlot.item, rarity: PixelRarity.common, description: "Has held everything from bait to the world's luckiest catch.", assetPath: 'assets/avatar_pixel/items/item_13_fishermanbucket.png',
    offsetX: -7.55, offsetY: -5.34, scale: 1.075,
  ),
  PixelCosmetic(id: 'px_item_porchrocker', name: "Porch Sitter's Rocking Chair", slot: PixelSlot.item, rarity: PixelRarity.common, description: 'Creaks in exactly the right rhythm for an afternoon nap.', assetPath: 'assets/avatar_pixel/items/item_14_porchrocker.png',
    offsetX: -11.17, offsetY: -17.11, scale: 1.706,
  ),
  PixelCosmetic(id: 'px_item_cityconestack', name: "City Worker's Cone Stack", slot: PixelSlot.item, rarity: PixelRarity.common, description: 'Marks the spot where something is always, always under construction.', assetPath: 'assets/avatar_pixel/items/item_15_cityconestack.png',
    offsetX: -8.34, offsetY: -17.99, scale: 1.649,
  ),
  PixelCosmetic(id: 'px_item_citymailbox', name: "City Mailcarrier's Mailbox", slot: PixelSlot.item, rarity: PixelRarity.common, description: 'Somehow always has one more letter than expected.', assetPath: 'assets/avatar_pixel/items/item_16_citymailbox.png',
    offsetX: -3.96, offsetY: -15.20, scale: 1.571,
  ),
  PixelCosmetic(id: 'px_item_pirateparrot', name: 'Pirate Crew Parrot Perch', slot: PixelSlot.item, rarity: PixelRarity.uncommon, description: 'The parrot has heard every version of every story told on this ship.', assetPath: 'assets/avatar_pixel/items/item_17_pirateparrot.png',
    offsetX: -10.30, offsetY: -21.38, scale: 1.974,
  ),
  PixelCosmetic(id: 'px_item_knightbanner', name: "Castle Knight's Banner Stand", slot: PixelSlot.item, rarity: PixelRarity.uncommon, description: 'Raised only when the cause is worth rallying behind.', assetPath: 'assets/avatar_pixel/items/item_18_knightbanner.png',
    offsetX: -7.64, offsetY: -29.57, scale: 2.414,
  ),
  PixelCosmetic(id: 'px_item_spacemanjetpack', name: 'Classic Spaceman Jetpack Stand', slot: PixelSlot.item, rarity: PixelRarity.common, description: 'Waiting patiently for the next launch window.', assetPath: 'assets/avatar_pixel/items/item_19_spacemanjetpack.png',
    offsetX: -4.84, offsetY: -16.67, scale: 1.486,
  ),
  PixelCosmetic(id: 'px_item_farmyardhay', name: 'Farmyard Hay Bale', slot: PixelSlot.item, rarity: PixelRarity.common, description: 'A perfectly good seat, if no one else claims it first.', assetPath: 'assets/avatar_pixel/items/item_20_farmyardhay.png',
    offsetX: -10.10, offsetY: -19.53, scale: 1.820,
  ),
  PixelCosmetic(id: 'px_item_piratechest', name: "Pirate Captain's Treasure Chest", slot: PixelSlot.item, rarity: PixelRarity.uncommon, description: 'Locked tight, and everyone has their own theory about what\'s inside.', assetPath: 'assets/avatar_pixel/items/item_21_piratechest.png',
    offsetX: -8.17, offsetY: -16.48, scale: 1.663,
  ),
  PixelCosmetic(id: 'px_item_junglemaptable', name: "Jungle Explorer's Map Table", slot: PixelSlot.item, rarity: PixelRarity.rare, description: "The map is only half-finished, and that's exactly the appeal.", assetPath: 'assets/avatar_pixel/items/item_22_junglemaptable.png',
    offsetX: -5.12, offsetY: -18.93, scale: 1.700,
  ),
  PixelCosmetic(id: 'px_item_icetrooperscanner', name: "Ice Base Trooper's Scanner", slot: PixelSlot.item, rarity: PixelRarity.epic, description: "Still picking up readings nobody's quite figured out how to explain.", assetPath: 'assets/avatar_pixel/items/item_23_icetrooperscanner.png',
    offsetX: -6.59, offsetY: -18.49, scale: 1.718,
  ),

  PixelCosmetic(
    id: 'px_item_legendarychrome', name: 'Chrome Trophy', slot: PixelSlot.item,
    rarity: PixelRarity.legendary,
    description: 'Not for any achievement in particular -- just for having it.',
    assetPath: 'assets/avatar_pixel/items/legendary_chrometrophy_f1.png',
    frames: [
      'assets/avatar_pixel/items/legendary_chrometrophy_f1.png',
      'assets/avatar_pixel/items/legendary_chrometrophy_f2.png',
      'assets/avatar_pixel/items/legendary_chrometrophy_f3.png',
      'assets/avatar_pixel/items/legendary_chrometrophy_f4.png',
    ],
    offsetX: -5.11, offsetY: -12.52, scale: 1.454,
  ),

  // First isSecret pixel entry -- hidden from the catalog grid (shows as
  // "???" instead of its name) until unlocked, pulled by LootService's
  // separate low-odds _maybeSecretDrop check rather than the normal
  // tiered roll. rarity still needs a real value even though isSecret
  // items don't roll through the tiered pool -- it's what prices the Brik
  // dupe-payout if this is ever rolled again after already being found.
  PixelCosmetic(
    id: 'px_item_secretxwing', name: 'X-Wing Fighter', slot: PixelSlot.item,
    rarity: PixelRarity.legendary, isSecret: true,
    description: "Nobody remembers unlocking this one. It was just... there, one day.",
    assetPath: 'assets/avatar_pixel/items/secret_xwing_f1.png',
    frames: [
      'assets/avatar_pixel/items/secret_xwing_f1.png',
      'assets/avatar_pixel/items/secret_xwing_f2.png',
      'assets/avatar_pixel/items/secret_xwing_f3.png',
      'assets/avatar_pixel/items/secret_xwing_f4.png',
      'assets/avatar_pixel/items/secret_xwing_f5.png',
      'assets/avatar_pixel/items/secret_xwing_f6.png',
      'assets/avatar_pixel/items/secret_xwing_f7.png',
      'assets/avatar_pixel/items/secret_xwing_f8.png',
    ],
    offsetX: -11.35, offsetY: -100.90, scale: 1.915,
  ),

  // Second isSecret pixel entry -- kept OUT of the weekly-quests batch below
  // on purpose (not isQuestExclusive): this one stays in the normal
  // isSecret pool (reachable only via LootService's rare secret-drop roll,
  // same as the X-Wing above) until a magic code is registered for it in
  // SecretItemCodes.byCode (secret_item_service.dart) -- not done yet,
  // deliberately, since the reveal timing is the point.
  PixelCosmetic(
    id: 'px_item_secretshuttle', name: 'Space Shuttle', slot: PixelSlot.item,
    rarity: PixelRarity.legendary, isSecret: true,
    description: "Docked quietly in orbit, waiting for someone to notice it.",
    assetPath: 'assets/avatar_pixel/items/secret_shuttle_f1.png',
    frames: [
      'assets/avatar_pixel/items/secret_shuttle_f1.png',
      'assets/avatar_pixel/items/secret_shuttle_f2.png',
      'assets/avatar_pixel/items/secret_shuttle_f3.png',
      'assets/avatar_pixel/items/secret_shuttle_f4.png',
      'assets/avatar_pixel/items/secret_shuttle_f5.png',
      'assets/avatar_pixel/items/secret_shuttle_f6.png',
      'assets/avatar_pixel/items/secret_shuttle_f7.png',
      'assets/avatar_pixel/items/secret_shuttle_f8.png',
    ],
    offsetX: -6.29, offsetY: -19.38, scale: 2.000,
  ),

  // ── Weekly Quests (isQuestExclusive) ─────────────────────────────────────
  // Only obtainable via a What's New quest's rewardCosmeticId (see
  // whats_new_service.dart) -- isQuestExclusive already excludes these from
  // LootService's normal reward pool AND the isSecret drop pool (see that
  // field's doc comment above). Scheduling (which week each one is live)
  // is handled entirely on the quest side via quest-admin.html's
  // active_at/ends_at, not here -- these entries just need to exist in the
  // catalog and stay out of the general pool. offsetX/offsetY/scale left at
  // default (0/0/1, untuned) same as every new item historically starts --
  // see PixelItemTunerScreen for fixing outlier positioning once there's a
  // real render to check against. Art dropped in assets/weeklyquests/ and
  // moved here 2026-09-02.
  PixelCosmetic(
    id: 'px_item_quest_pokball', name: 'Poké Ball Charm', slot: PixelSlot.item,
    rarity: PixelRarity.epic, isQuestExclusive: true,
    assetPath: 'assets/avatar_pixel/items/item_quest_pokball.png',
    // Repositioned onto the chest (large negative offsets) to read as a worn
    // charm/pendant, but zOrder:1 left it painting behind torso(2)/hat(3) --
    // defeating the point, since it'd render hidden. Bumped to 5 (above
    // every other slot's default) so it actually sits in front once moved
    // onto the body.
    offsetX: -41.48, offsetY: -15.52, scale: 1.300, zOrder: 5,
  ),
  PixelCosmetic(
    id: 'px_item_quest_energy', name: 'Energy Charm', slot: PixelSlot.item,
    rarity: PixelRarity.epic, isQuestExclusive: true,
    assetPath: 'assets/avatar_pixel/items/item_quest_energy.png',
    offsetX: -48.03, offsetY: -140.47, scale: 8.000, zOrder: -1,
  ),
  PixelCosmetic(
    id: 'px_item_quest_jackolantern', name: "Jack-o'-Lantern Charm", slot: PixelSlot.item,
    rarity: PixelRarity.epic, isQuestExclusive: true,
    assetPath: 'assets/avatar_pixel/items/item_quest_jackolantern.png',
    offsetX: -10.35, offsetY: -44.59, scale: 4.000,
  ),
  PixelCosmetic(
    id: 'px_item_quest_pokebolt', name: 'Lightning Charm', slot: PixelSlot.item,
    rarity: PixelRarity.epic, isQuestExclusive: true,
    assetPath: 'assets/avatar_pixel/items/item_quest_pokebolt.png',
    offsetX: -45.72, offsetY: -120.26, scale: 6.000, zOrder: -5,
  ),
  PixelCosmetic(
    id: 'px_item_quest_bags', name: 'Shopping Spree Bags', slot: PixelSlot.item,
    rarity: PixelRarity.epic, isQuestExclusive: true,
    assetPath: 'assets/avatar_pixel/items/item_quest_bags.png',
    // Same fix as the Poké Ball Charm above: repositioned onto the body but
    // zOrder:0 left it behind torso/hat. Bumped to 5 for the same reason.
    offsetX: -57.38, offsetY: -10.59, scale: 1.840, zOrder: 5,
  ),
  PixelCosmetic(
    id: 'px_item_quest_pot', name: 'Potted Sprout', slot: PixelSlot.item,
    rarity: PixelRarity.epic, isQuestExclusive: true,
    assetPath: 'assets/avatar_pixel/items/item_quest_pot.png',
    offsetX: -7.73, offsetY: -51.02, scale: 4.420,
  ),
  PixelCosmetic(
    id: 'px_item_quest_pineapple', name: 'Pineapple House Charm', slot: PixelSlot.item,
    rarity: PixelRarity.epic, isQuestExclusive: true,
    assetPath: 'assets/avatar_pixel/items/item_quest_pineapple.png',
    offsetX: -8.67, offsetY: -59.70, scale: 4.600,
  ),
  PixelCosmetic(
    id: 'px_torso_quest_cloak', name: "Traveler's Cloak", slot: PixelSlot.torso,
    rarity: PixelRarity.epic, isQuestExclusive: true,
    assetPath: 'assets/avatar_pixel/torsos/torso_quest_cloak.png',
    offsetX: -0.12, offsetY: -10.94, scale: 2.640, zOrder: 5,
  ),
  PixelCosmetic(
    id: 'px_torso_quest_brickcon', name: 'BrickCon Badge Tee', slot: PixelSlot.torso,
    rarity: PixelRarity.epic, isQuestExclusive: true,
    assetPath: 'assets/avatar_pixel/torsos/torso_quest_brickcon.png',
    // zOrder:0 (tied with legs' default) accidentally reversed the
    // catalog-wide "torso paints over head" rule for this one shirt --
    // no evidence this was intentional (offsetX/Y are both untouched at 0
    // too), so dropped entirely to fall back to torso's own defaultZ(2),
    // matching every other torso item's normal behavior.
    offsetX: 0.00, offsetY: 0.00, scale: 1.500,
  ),
  // Two art passes on the same shirt concept -- both kept as separate,
  // independently schedulable items rather than picking one, since which
  // (if either) actually gets used in a live quest is a scheduling call
  // made in quest-admin.html, not here.
  PixelCosmetic(
    id: 'px_torso_quest_genconshirt', name: 'BrikStax Con Tee', slot: PixelSlot.torso,
    rarity: PixelRarity.epic, isQuestExclusive: true,
    assetPath: 'assets/avatar_pixel/torsos/torso_quest_genconshirt.png',
    offsetX: 0.19, offsetY: 3.95, scale: 1.220,
  ),
  PixelCosmetic(
    id: 'px_torso_quest_genconshirt_alt', name: 'BrikStax Con Tee (Brick Logo)', slot: PixelSlot.torso,
    rarity: PixelRarity.epic, isQuestExclusive: true,
    assetPath: 'assets/avatar_pixel/torsos/torso_quest_genconshirt_alt.png',
    offsetX: 0.00, offsetY: 3.00, scale: 1.180,
  ),
];

List<PixelCosmetic> pixelCosmeticsForSlot(PixelSlot slot) =>
    allPixelCosmetics.where((c) => c.slot == slot).toList();

Map<String, PixelCosmetic> get pixelCosmeticsById =>
    { for (final c in allPixelCosmetics) c.id: c };
