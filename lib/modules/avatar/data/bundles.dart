// lib/modules/avatar/data/bundles.dart
//
// cosmeticIds point at the pixel catalog now (data/pixel_cosmetics.dart) for
// figure pieces, or the background catalog for the background piece (bg_*,
// unchanged). Remapped from the old retired figure catalog
// (helmet_14/outfit_09/accessory_09 etc., all dead post pixel-art cutover).
// px_torso_icetroopersuit/px_legs_icetrooper are the same "gold set"
// referenced by achievements.dart -- keep in sync if reassigned. Several
// bundles deliberately reuse the same rare/epic pixel ids as each other or
// as an achievement/hidden-theme reward (only 13 rare + 6 epic pixel items
// exist against ~90 total reward slots across all three systems) --
// LootService.unlockOrDupePayout converts an already-owned repeat into
// Briks rather than granting nothing, same as any other dupe.
import '../models/bundle.dart';
class AllBundles {
  AllBundles._();
  static const List<CosmeticBundle> all = [
    CosmeticBundle(
      id: 'bundle_xwing',
      name: 'X-Wing Pilot',
      emoji: '⭐',
      rarity: BundleRarity.rare,
      description: 'Suit up for the rebellion.',
      cosmeticIds: ['px_hat_skyfargoggle', 'px_torso_snowtrekkerparka'],
      unlockCondition: 'Own 5+ Star Wars sets',
    ),
    CosmeticBundle(
      id: 'bundle_ucs',
      name: 'UCS Collector',
      emoji: '🚀',
      rarity: BundleRarity.epic,
      description: 'Only for the most dedicated builders.',
      cosmeticIds: ['px_hat_junglepith', 'px_legs_junglecargo'],
      unlockCondition: 'Own 3+ UCS sets',
    ),
    CosmeticBundle(
      id: 'bundle_castle',
      name: 'Castle Knight',
      emoji: '🏰',
      rarity: BundleRarity.rare,
      description: 'Defend your collection like a fortress.',
      cosmeticIds: ['px_torso_knightarmor', 'px_legs_knightgreaves'],
      unlockCondition: 'Own any Castle theme sets',
    ),
    CosmeticBundle(
      id: 'bundle_viking',
      name: 'Viking Raider',
      emoji: '⚔️',
      rarity: BundleRarity.rare,
      description: 'Pillage the secondary market.',
      cosmeticIds: ['px_hat_fishermanbucket', 'px_torso_fishermanoilskin'],
      unlockCondition: 'Own 25+ sets',
    ),
    CosmeticBundle(
      id: 'bundle_gold',
      name: 'Gold Standard',
      emoji: '✨',
      rarity: BundleRarity.legendary,
      description: 'The full gold treatment.',
      cosmeticIds: ['px_hat_icetrooper', 'px_torso_icetroopersuit', 'px_item_icetrooperscanner'],
      unlockCondition: '\$10,000+ market value',
    ),
    CosmeticBundle(
      id: 'bundle_pearl',
      name: 'Pearl Collector',
      emoji: '👑',
      rarity: BundleRarity.legendary,
      description: 'The ultimate flex. Reserved for elites.',
      cosmeticIds: ['px_legs_icetrooper', 'px_item_alchemistpotionrack', 'px_hat_sandstonewrap', 'px_torso_sandstonetunic', 'bg_prismvoid'],
      unlockCondition: 'Overall ROI 100%+',
    ),
    CosmeticBundle(
      id: 'bundle_space',
      name: 'Space Explorer',
      emoji: '🌌',
      rarity: BundleRarity.epic,
      description: 'To infinity and beyond.',
      cosmeticIds: ['px_hat_spacemanhelmet', 'px_legs_spaceman', 'bg_spacestation'],
      unlockCondition: '\$5,000+ market value',
    ),
    CosmeticBundle(
      id: 'bundle_city',
      name: 'City Officer',
      emoji: '🏙️',
      rarity: BundleRarity.rare,
      description: 'Protect and serve your collection.',
      cosmeticIds: ['px_torso_cityworkervest', 'bg_cream'],
      unlockCondition: 'Own 10+ sets',
    ),
    CosmeticBundle(
      id: 'bundle_master',
      name: 'Master Builder',
      emoji: '🔧',
      rarity: BundleRarity.epic,
      description: 'Built different.',
      cosmeticIds: ['px_torso_builderutility', 'px_hat_cityhardhat', 'bg_glaciercave'],
      unlockCondition: 'Own 50+ sets',
    ),

    // ─────────────────────── Phase-2 theme bundles ───────────────────────
    CosmeticBundle(
      id: 'bundle_spellbound',
      name: 'Spellbound Scholar',
      emoji: '🪄',
      rarity: BundleRarity.epic,
      description: 'Mischief managed.',
      cosmeticIds: ['px_hat_wizardstar', 'px_torso_wizardstarrobe', 'px_legs_wizardstar', 'bg_castlehall'],
      unlockCondition: 'Own 5+ Harry Potter sets',
    ),
    CosmeticBundle(
      id: 'bundle_botanical',
      name: 'Master Gardener',
      emoji: '🌷',
      rarity: BundleRarity.rare,
      description: 'Bloom where you build.',
      cosmeticIds: ['px_hat_gardensun', 'px_torso_gardenoveralls', 'px_item_wateringcan', 'bg_greenhouse'],
      unlockCondition: 'Own 3+ Botanicals sets',
    ),
    CosmeticBundle(
      id: 'bundle_grandprix',
      name: 'Grand Prix Champion',
      emoji: '🏁',
      rarity: BundleRarity.rare,
      description: 'Pole position at every drop.',
      cosmeticIds: ['px_hat_cyclisthelmet', 'px_torso_cyclistjersey', 'px_item_cyclistbike', 'bg_garage'],
      unlockCondition: 'Own 5+ Speed Champions sets',
    ),
    CosmeticBundle(
      id: 'bundle_storm',
      name: 'Storm Master',
      emoji: '🌩️',
      rarity: BundleRarity.epic,
      description: 'Lightning answers your call.',
      cosmeticIds: ['px_hat_icetrooper', 'px_torso_icetroopersuit', 'px_legs_emberbattle', 'bg_shadowrealm'],
      unlockCondition: 'Own 8+ Ninjago sets',
    ),
    CosmeticBundle(
      id: 'bundle_landmark',
      name: 'Master Architect',
      emoji: '🏛️',
      rarity: BundleRarity.epic,
      description: 'Form follows function.',
      cosmeticIds: ['px_hat_junglepith', 'px_torso_junglevest', 'px_item_junglemaptable', 'bg_workshop'],
      unlockCondition: 'Own 3+ Icons or Architecture sets',
    ),
    CosmeticBundle(
      id: 'bundle_frostfall',
      name: 'Aurora Wanderer',
      emoji: '❄️',
      rarity: BundleRarity.legendary,
      description: 'The northern lights, worn as armor.',
      cosmeticIds: ['px_torso_snowtrekkerparka', 'px_legs_snowtrekker', 'px_item_icetrooperscanner', 'bg_snowfield'],
      unlockCondition: 'Own 2+ Winter Village sets',
    ),
    CosmeticBundle(
      id: 'bundle_curio',
      name: 'Curious Inventor',
      emoji: '🔭',
      rarity: BundleRarity.rare,
      description: 'A little magic in every build.',
      cosmeticIds: ['px_item_alchemistcauldron', 'px_hat_sandstonewrap', 'px_item_sandstonetablet', 'bg_attic'],
      unlockCondition: 'Own 3+ Ideas sets',
    ),
  ];
  static Map<String, CosmeticBundle> get byId =>
      { for (final b in all) b.id: b };
}
