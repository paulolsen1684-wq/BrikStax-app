// lib/modules/avatar/data/hidden_themes.dart
// Tiered "hidden theme" challenges. Each theme has 1-4 tiers of increasing
// difficulty. Lower tiers accept ANY matching set; higher tiers require
// VERIFIED sets (scan-backed once the scanner is live; all sets count as
// verified until then). Completing a tier grants a reward cosmetic id.
//
// Difficulty drives rarity feel:
//   bronze  → easy, any sets      → common pixel item
//   silver  → moderate, any sets  → uncommon pixel item
//   gold    → hard, VERIFIED sets → rare pixel item
//   diamond → elite, VERIFIED + high count → epic pixel item
//
// rewardCosmetic points at the pixel catalog (data/pixel_cosmetics.dart) for
// every tier except ht_metropolis's gold, which stayed a background
// (bg_skyline, still a valid sprite-catalog id). Remapped from the old
// retired sprite figure catalog (accessory_02/helmet_09/outfit_16 etc., all
// dead post pixel-art cutover). Only 13 rare and 6 epic pixel items exist,
// so gold/diamond tiers across this file's 10 themes necessarily repeat a
// handful of ids -- unlockOrDupePayout converts an already-owned repeat to
// Briks instead of granting nothing, same as any other dupe.

enum ThemeTier { bronze, silver, gold, diamond }

class HiddenThemeTier {
  final ThemeTier tier;
  final int       required;       // count needed
  final bool      verifiedOnly;   // gate on verified sets
  final String    rewardCosmetic; // cosmetic id granted on completion
  const HiddenThemeTier({
    required this.tier,
    required this.required,
    required this.verifiedOnly,
    required this.rewardCosmetic,
  });
}

class HiddenTheme {
  final String id;
  final String name;
  final String emoji;
  final String hint;            // shown while still locked/hidden
  final List<String> needles;   // theme/subtheme substrings (lowercase)
  final List<HiddenThemeTier> tiers;
  const HiddenTheme({
    required this.id,
    required this.name,
    required this.emoji,
    required this.hint,
    required this.needles,
    required this.tiers,
  });

  int get maxRequired => tiers.isEmpty ? 0 : tiers.last.required;
}

class HiddenThemes {
  HiddenThemes._();

  static const List<HiddenTheme> all = [
    HiddenTheme(
      id: 'ht_galactic',
      name: 'Galactic Archive',
      emoji: '🌌',
      hint: 'A long time ago, in a collection far, far away...',
      needles: ['star wars'],
      tiers: [
        HiddenThemeTier(tier: ThemeTier.bronze,  required: 3,  verifiedOnly: false, rewardCosmetic: 'px_hat_cyclisthelmet'),
        HiddenThemeTier(tier: ThemeTier.silver,  required: 8,  verifiedOnly: false, rewardCosmetic: 'px_hat_tidepoolhood'),
        HiddenThemeTier(tier: ThemeTier.gold,    required: 15, verifiedOnly: true,  rewardCosmetic: 'px_hat_sandstonewrap'),
        HiddenThemeTier(tier: ThemeTier.diamond, required: 25, verifiedOnly: true,  rewardCosmetic: 'px_legs_emberbattle'),
      ],
    ),
    HiddenTheme(
      id: 'ht_spellbound',
      name: 'Forbidden Section',
      emoji: '🪄',
      hint: 'Some books are best kept under lock and key.',
      needles: ['harry potter', 'wizarding'],
      tiers: [
        HiddenThemeTier(tier: ThemeTier.bronze, required: 2, verifiedOnly: false, rewardCosmetic: 'px_hat_bakercap'),
        HiddenThemeTier(tier: ThemeTier.silver, required: 5, verifiedOnly: false, rewardCosmetic: 'px_hat_piratetricorn'),
        HiddenThemeTier(tier: ThemeTier.gold,   required: 9, verifiedOnly: true,  rewardCosmetic: 'px_torso_sandstonetunic'),
      ],
    ),
    HiddenTheme(
      id: 'ht_storm',
      name: 'Storm Temple',
      emoji: '🌩️',
      hint: 'Master the elements, one set at a time.',
      needles: ['ninjago'],
      tiers: [
        HiddenThemeTier(tier: ThemeTier.bronze,  required: 3,  verifiedOnly: false, rewardCosmetic: 'px_hat_spacemanhelmet'),
        HiddenThemeTier(tier: ThemeTier.silver,  required: 6,  verifiedOnly: false, rewardCosmetic: 'px_hat_lighthousecap'),
        HiddenThemeTier(tier: ThemeTier.gold,    required: 10, verifiedOnly: true,  rewardCosmetic: 'px_torso_wizardstarrobe'),
        HiddenThemeTier(tier: ThemeTier.diamond, required: 18, verifiedOnly: true,  rewardCosmetic: 'px_item_icetrooperscanner'),
      ],
    ),
    HiddenTheme(
      id: 'ht_botanical',
      name: 'Secret Garden',
      emoji: '🌷',
      hint: 'Patience. Everything blooms in time.',
      needles: ['botanical'],
      tiers: [
        HiddenThemeTier(tier: ThemeTier.bronze, required: 2, verifiedOnly: false, rewardCosmetic: 'px_torso_campfiresweater'),
        HiddenThemeTier(tier: ThemeTier.silver, required: 4, verifiedOnly: false, rewardCosmetic: 'px_hat_piratebandana'),
        HiddenThemeTier(tier: ThemeTier.gold,   required: 7, verifiedOnly: true,  rewardCosmetic: 'px_legs_junglecargo'),
      ],
    ),
    HiddenTheme(
      id: 'ht_grandprix',
      name: 'Pole Position',
      emoji: '🏁',
      hint: 'Speed is everything.',
      needles: ['speed champions'],
      tiers: [
        HiddenThemeTier(tier: ThemeTier.bronze, required: 3, verifiedOnly: false, rewardCosmetic: 'px_torso_fishermanoilskin'),
        HiddenThemeTier(tier: ThemeTier.silver, required: 6, verifiedOnly: false, rewardCosmetic: 'px_torso_tidepoolvest'),
        HiddenThemeTier(tier: ThemeTier.gold,   required: 10, verifiedOnly: true, rewardCosmetic: 'px_legs_wizardstar'),
      ],
    ),
    HiddenTheme(
      id: 'ht_landmark',
      name: 'Wonders of the World',
      emoji: '🏛️',
      hint: 'Build something that lasts.',
      needles: ['icons', 'architecture', 'creator expert'],
      tiers: [
        HiddenThemeTier(tier: ThemeTier.bronze,  required: 2,  verifiedOnly: false, rewardCosmetic: 'px_torso_porchcardigan'),
        HiddenThemeTier(tier: ThemeTier.silver,  required: 5,  verifiedOnly: false, rewardCosmetic: 'px_torso_harborwatchsuit'),
        HiddenThemeTier(tier: ThemeTier.gold,    required: 10, verifiedOnly: true,  rewardCosmetic: 'px_item_alchemistcauldron'),
        HiddenThemeTier(tier: ThemeTier.diamond, required: 18, verifiedOnly: true,  rewardCosmetic: 'px_torso_icetroopersuit'),
      ],
    ),
    HiddenTheme(
      id: 'ht_curio',
      name: 'Cabinet of Curiosities',
      emoji: '🔭',
      hint: 'The most interesting builds come from the mind.',
      needles: ['ideas'],
      tiers: [
        HiddenThemeTier(tier: ThemeTier.bronze, required: 2, verifiedOnly: false, rewardCosmetic: 'px_torso_bakerapron'),
        HiddenThemeTier(tier: ThemeTier.silver, required: 4, verifiedOnly: false, rewardCosmetic: 'px_torso_snowtrekkerparka'),
        HiddenThemeTier(tier: ThemeTier.gold,   required: 7, verifiedOnly: true,  rewardCosmetic: 'px_item_junglemaptable'),
      ],
    ),
    HiddenTheme(
      id: 'ht_frostfall',
      name: 'Winterfell',
      emoji: '❄️',
      hint: 'Winter is coming. Stock up.',
      needles: ['winter village', 'winter', 'seasonal'],
      tiers: [
        HiddenThemeTier(tier: ThemeTier.bronze, required: 1, verifiedOnly: false, rewardCosmetic: 'px_torso_mailcarrieruniform'),
        HiddenThemeTier(tier: ThemeTier.silver, required: 3, verifiedOnly: false, rewardCosmetic: 'px_torso_piratecoat'),
        HiddenThemeTier(tier: ThemeTier.gold,   required: 5, verifiedOnly: true,  rewardCosmetic: 'px_hat_wizardstar'),
      ],
    ),
    HiddenTheme(
      id: 'ht_technic',
      name: 'The Machine',
      emoji: '⚙️',
      hint: 'Gears within gears within gears.',
      needles: ['technic'],
      tiers: [
        HiddenThemeTier(tier: ThemeTier.bronze, required: 3, verifiedOnly: false, rewardCosmetic: 'px_torso_cityworkervest'),
        HiddenThemeTier(tier: ThemeTier.silver, required: 7, verifiedOnly: false, rewardCosmetic: 'px_torso_piratecrewshirt'),
        HiddenThemeTier(tier: ThemeTier.gold,   required: 12, verifiedOnly: true, rewardCosmetic: 'px_hat_skyfargoggle'),
      ],
    ),
    HiddenTheme(
      id: 'ht_metropolis',
      name: 'Metropolis',
      emoji: '🏙️',
      hint: 'A city is never finished.',
      needles: ['city'],
      tiers: [
        HiddenThemeTier(tier: ThemeTier.bronze, required: 5,  verifiedOnly: false, rewardCosmetic: 'px_torso_gardenoveralls'),
        HiddenThemeTier(tier: ThemeTier.silver, required: 12, verifiedOnly: false, rewardCosmetic: 'px_legs_tidepool'),
        HiddenThemeTier(tier: ThemeTier.gold,   required: 20, verifiedOnly: true,  rewardCosmetic: 'bg_skyline'),
      ],
    ),
  ];

  static Map<String, HiddenTheme> get byId => { for (final t in all) t.id: t };
}
