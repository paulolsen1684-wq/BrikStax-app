// lib/modules/avatar/avatar_module.dart
//
// Two catalogs now: data/background_cosmetics.dart (backgrounds only,
// renamed 2026-08-12 from sprite_cosmetics.dart) and data/pixel_cosmetics
// .dart (the live figure catalog -- head/hat/torso/legs/item).
// sprite_avatar_widget.dart (the old detailed-crop figure renderer) was
// deleted once nothing referenced it anymore -- avatar_widget.dart wraps
// PixelAvatarWidget for the figure now, background still renders through
// the background catalog's procedural palette lookup.
export 'models/achievement.dart';
export 'models/avatar_state.dart';
export 'models/bundle.dart';
export 'models/loot_roll.dart';
export 'data/background_cosmetics.dart';
export 'data/pixel_cosmetics.dart';
export 'data/achievements.dart';
export 'data/hidden_themes.dart';
export 'data/bundles.dart';
export 'services/achievement_service.dart';
export 'services/avatar_storage.dart';
export 'services/loot_service.dart';
export 'widgets/avatar_widget.dart';
export 'widgets/pixel_avatar_widget.dart';
export 'widgets/achievement_popup.dart';
export 'widgets/avatar_editor.dart';
export 'widgets/dashboard_avatar_card.dart';
export 'widgets/loot_roll_widget.dart';
export 'widgets/daily_claim_screen.dart';
export 'widgets/bundle_popup.dart';
