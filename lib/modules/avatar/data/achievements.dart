// lib/modules/avatar/data/achievements.dart
//
// cosmeticId values point at the pixel catalog now (data/pixel_cosmetics.dart)
// for every figure slot, or the background catalog (background_cosmetics.dart,
// renamed 2026-08-12 from sprite_cosmetics.dart) for the 4 background
// rewards (bg_*) -- backgrounds never moved. Remapped from the old retired
// figure catalog (helmet_18/outfit_09/accessory_01 etc.,
// all dead ids post pixel-art cutover) once the pixel catalog had enough
// items and real rarity data to actually support this. Rarity roughly
// matches how hard the achievement is to earn; thematic name matches are
// opportunistic where the pixel catalog has an obvious fit (the cyclist/
// harbor/knight/jungle/wizard "sets"), not guaranteed for every entry --
// with ~90 reward slots across achievements/hidden themes/bundles pulling
// from a 95-item catalog (only 13 rare, 6 epic), rare/epic-tier ids repeat
// across multiple achievements/themes/bundles by necessity. That's fine:
// unlockOrDupePayout already converts an already-owned repeat into Briks
// instead of granting nothing, same as any other dupe.
//
// px_torso_icetroopersuit / px_legs_icetrooper form the "gold set" (was
// head_18/outfit_18) referenced by achievement_service.dart's legendary_gold
// bonus condition -- keep those two in sync if you reassign them.
import '../models/achievement.dart';

class AllAchievements {
  AllAchievements._();

  static const List<Achievement> all = [

    // ── First steps ────────────────────────────────────────────────────────
    Achievement(
      id: 'first_set',
      name: 'First Brick',
      description: 'Added your first set to BrikStax.',
      emoji: '🧱',
      cosmeticId: 'px_item_camplantern',
      condition: 'Add 1 set',
    ),
    Achievement(
      id: 'first_ebay',
      name: 'Price Check',
      description: 'Fetched your first eBay price.',
      emoji: '💰',
      cosmeticId: 'bg_skyline',
      condition: 'Refresh eBay on any set',
    ),

    // ── Collection size ────────────────────────────────────────────────────
    Achievement(
      id: 'sets_10',
      name: 'Getting Serious',
      description: 'Your collection has grown to 10 sets.',
      emoji: '📦',
      cosmeticId: 'px_hat_fishermanbucket',
      condition: 'Own 10 sets',
    ),
    Achievement(
      id: 'sets_25',
      name: 'Collector',
      description: '25 sets — you\'re committed.',
      emoji: '🏅',
      cosmeticId: 'px_torso_cyclistjersey',
      condition: 'Own 25 sets',
    ),
    Achievement(
      id: 'sets_50',
      name: 'Serious Collector',
      description: '50 sets deep. No going back.',
      emoji: '🥇',
      cosmeticId: 'px_legs_frontierscout',
      condition: 'Own 50 sets',
    ),
    Achievement(
      id: 'sets_100',
      name: 'Century Club',
      description: '100 sets. Legendary status.',
      emoji: '💯',
      cosmeticId: 'px_torso_junglevest',
      condition: 'Own 100 sets',
    ),

    // ── Sealed vault ───────────────────────────────────────────────────────
    Achievement(
      id: 'sealed_5',
      name: 'Vault Starter',
      description: '5 sealed sets. The investment begins.',
      emoji: '🔒',
      cosmeticId: 'px_item_harboranchor',
      condition: 'Own 5 sealed sets',
    ),
    Achievement(
      id: 'sealed_10',
      name: 'Sealed Vault',
      description: '10 sealed sets. You know what you\'re doing.',
      emoji: '🏦',
      cosmeticId: 'px_hat_harborwatch',
      condition: 'Own 10 sealed sets',
    ),
    Achievement(
      id: 'sealed_25',
      name: 'Fort Knox',
      description: '25 sealed sets. Untouchable.',
      emoji: '🛡️',
      cosmeticId: 'px_torso_knightarmor',
      condition: 'Own 25 sealed sets',
    ),

    // ── Portfolio value ────────────────────────────────────────────────────
    Achievement(
      id: 'value_1k',
      name: 'Four Figures',
      description: 'Portfolio market value hit \$1,000.',
      emoji: '💵',
      cosmeticId: 'px_item_cyclistbike',
      condition: '\$1,000+ market value',
    ),
    Achievement(
      id: 'value_5k',
      name: 'High Roller',
      description: 'Portfolio market value hit \$5,000.',
      emoji: '💸',
      cosmeticId: 'px_hat_cityhardhat',
      condition: '\$5,000+ market value',
    ),
    Achievement(
      id: 'value_10k',
      name: 'Five Figures',
      description: '\$10,000 collection. Serious money.',
      emoji: '🏆',
      cosmeticId: 'px_torso_lighthousecoat',
      condition: '\$10,000+ market value',
    ),
    Achievement(
      id: 'value_25k',
      name: 'Investment Grade',
      description: '\$25,000 portfolio. This is a collection.',
      emoji: '💎',
      cosmeticId: 'bg_glaciercave',
      condition: '\$25,000+ market value',
    ),

    // ── ROI ────────────────────────────────────────────────────────────────
    Achievement(
      id: 'roi_50',
      name: 'In the Green',
      description: 'A set in your collection has 50%+ ROI.',
      emoji: '📈',
      cosmeticId: 'px_legs_cyclistshorts',
      condition: 'One set at 50%+ ROI',
    ),
    Achievement(
      id: 'roi_100',
      name: 'Doubled Up',
      description: 'A set has 100%+ ROI. You doubled your money.',
      emoji: '🚀',
      cosmeticId: 'px_torso_icetroopersuit', // gold set: torso
      condition: 'One set at 100%+ ROI',
    ),
    Achievement(
      id: 'roi_200',
      name: 'Triple Digit',
      description: '200%+ ROI on a single set. Extraordinary.',
      emoji: '🌙',
      cosmeticId: 'px_hat_wizardstar',
      condition: 'One set at 200%+ ROI',
    ),
    Achievement(
      id: 'roi_500',
      name: 'Moon Shot',
      description: '500%+ ROI. You found the unicorn.',
      emoji: '🦄',
      cosmeticId: 'px_item_sandstonetablet',
      condition: 'One set at 500%+ ROI',
    ),

    // ── Theme master ───────────────────────────────────────────────────────
    Achievement(
      id: 'theme_starwars',
      name: 'May the Bricks Be With You',
      description: 'Own 5+ Star Wars sets.',
      emoji: '⭐',
      cosmeticId: 'px_hat_skyfargoggle',
      condition: '5+ Star Wars sets',
    ),
    Achievement(
      id: 'theme_ucs',
      name: 'UCS Collector',
      description: 'Own 3+ UCS sets.',
      emoji: '🚀',
      cosmeticId: 'px_hat_junglepith',
      condition: '3+ UCS / Ultimate Collector sets',
    ),
    Achievement(
      id: 'theme_icons',
      name: 'Icons Enthusiast',
      description: 'Own 5+ Icons sets.',
      emoji: '🏛️',
      cosmeticId: 'bg_spacestation',
      condition: '5+ Icons sets',
    ),
    Achievement(
      id: 'theme_technic',
      name: 'Gear Head',
      description: 'Own 5+ Technic sets.',
      emoji: '⚙️',
      cosmeticId: 'px_torso_builderutility',
      condition: '5+ Technic sets',
    ),

    // ── Legendary tier ─────────────────────────────────────────────────────
    Achievement(
      id: 'legendary_all',
      name: 'Master of Bricks',
      description: 'Earned every other achievement.',
      emoji: '👑',
      cosmeticId: 'px_item_alchemistpotionrack',
      condition: 'Earn all other achievements',
    ),
    Achievement(
      id: 'legendary_portfolio',
      name: 'The Vault',
      description: '\$50,000+ portfolio. You are the collection.',
      emoji: '🏰',
      cosmeticId: 'bg_prismvoid',
      condition: '\$50,000+ market value',
    ),
    Achievement(
      id: 'legendary_roi',
      name: 'The One Percent',
      description: 'Overall portfolio ROI above 100%.',
      emoji: '🎯',
      cosmeticId: 'px_legs_icetrooper', // gold set: legs
      condition: 'Overall ROI 100%+',
    ),
    Achievement(
      id: 'legendary_sets',
      name: 'The Collection',
      description: '250 sets. There are no words.',
      emoji: '🌟',
      cosmeticId: 'px_legs_sandstone',
      condition: 'Own 250 sets',
    ),
    Achievement(
      id: 'legendary_gold',
      name: 'All That Glitters',
      description: 'Unlocked the full gold set.',
      emoji: '✨',
      cosmeticId: 'px_hat_icetrooper', // bonus for completing the gold set (torso + legs)
      condition: 'Unlock the Ice Base Trooper torso and legs',
    ),
  ];

  static Map<String, Achievement> get byId =>
      { for (final a in all) a.id: a };
}
