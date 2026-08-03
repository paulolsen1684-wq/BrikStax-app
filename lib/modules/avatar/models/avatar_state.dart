// lib/modules/avatar/models/avatar_state.dart
//
// Figure fields (headId/hatId/torsoId/legsId/itemId) point at the pixel-art
// catalog (data/pixel_cosmetics.dart) now -- the old sprite-crop figure
// system (helmetId/outfitId/accessoryId against sprite_cosmetics.dart) is
// retired. backgroundId is untouched: none of the pixel-art batch is
// background art, so Den backgrounds stay exactly where they were
// (backgrounds_art.dart's procedural palettes, catalog entries still in
// sprite_cosmetics.dart).
//
// The old field names (helmetId/outfitId/accessoryId) are gone from
// toJson/fromJson on purpose -- an existing save's JSON simply won't have
// keys matching the new field names, so it decodes straight to defaults
// with no migration code needed. This is deliberate: existing testers'
// figure state resets when this ships, decided knowingly rather than
// half-migrated.

class AvatarState {
  final String? headId;
  final String? hatId;
  final String? torsoId;
  final String? legsId;
  final String? itemId;
  final String? backgroundId;

  final Set<String> unlockedIds;
  final Set<String> earnedIds;

  const AvatarState({
    this.headId,
    this.hatId,
    this.torsoId,
    this.legsId,
    this.itemId,
    this.backgroundId,
    this.unlockedIds  = const {},
    this.earnedIds    = const {},
  });

  AvatarState copyWith({
    String?      headId,
    String?      hatId,
    String?      torsoId,
    String?      legsId,
    String?      itemId,
    String?      backgroundId,
    Set<String>? unlockedIds,
    Set<String>? earnedIds,
    bool         clearHat  = false,
    bool         clearItem = false,
  }) => AvatarState(
    headId:       headId       ?? this.headId,
    hatId:        clearHat  ? null : hatId  ?? this.hatId,
    torsoId:      torsoId      ?? this.torsoId,
    legsId:       legsId       ?? this.legsId,
    itemId:       clearItem ? null : itemId ?? this.itemId,
    backgroundId: backgroundId ?? this.backgroundId,
    unlockedIds:  unlockedIds  ?? this.unlockedIds,
    earnedIds:    earnedIds    ?? this.earnedIds,
  );

  Map<String, dynamic> toJson() => {
    'headId':       headId,
    'hatId':        hatId,
    'torsoId':      torsoId,
    'legsId':       legsId,
    'itemId':       itemId,
    'backgroundId': backgroundId,
    'unlockedIds':  unlockedIds.toList(),
    'earnedIds':    earnedIds.toList(),
  };

  factory AvatarState.fromJson(Map<String, dynamic> j) => AvatarState(
    headId:       j['headId']       as String?,
    hatId:        j['hatId']        as String?,
    torsoId:      j['torsoId']      as String?,
    legsId:       j['legsId']       as String?,
    itemId:       j['itemId']       as String?,
    backgroundId: j['backgroundId'] as String?,
    unlockedIds:  Set<String>.from(j['unlockedIds']  as List? ?? []),
    earnedIds:    Set<String>.from(j['earnedIds']    as List? ?? []),
  );

  // Only what's actually equipped by default starts unlocked -- everything
  // else in the pixel catalog must be earned through loot_service.dart's
  // reward pool now (see its rarityOf/_rewardPool). This used to unlock the
  // WHOLE catalog (every pixel item, since there was no loot economy
  // pointing at it yet) -- that placeholder is gone now that one exists;
  // starterIds here is the thing loot_service.dart's pool excludes so
  // nobody "wins" the item they already start with, same as the background
  // catalog's _starterIds always worked. Keep the two lists in sync by hand
  // if the actual starter figure ever changes.
  static const starterIds = {
    'px_head_01', 'px_torso_graysweater', 'px_legs_bluejeans', 'bg_cream',
  };

  static AvatarState get defaults => const AvatarState(
    headId:       'px_head_01',
    torsoId:      'px_torso_graysweater',
    legsId:       'px_legs_bluejeans',
    backgroundId: 'bg_cream',
    unlockedIds:  starterIds,
    earnedIds:    {},
  );
}
