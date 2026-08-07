// lib/theme/app_themes.dart — BrikStax Theme System
import 'package:flutter/material.dart';

// ── Theme IDs ─────────────────────────────────────────────────────────────────
enum BrikTheme {
  classic,
  darkBrick,
  starWars,
  ninjago,
  city,
  botanical,
  icons,
  spaceClassic,
}

// ── Theme metadata (name, emoji, unlock condition) ────────────────────────────
class BrikThemeMeta {
  final BrikTheme id;
  final String    name;
  final String    emoji;
  final String    description;
  final String    unlockCondition;
  final bool      alwaysUnlocked;

  const BrikThemeMeta({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.unlockCondition,
    this.alwaysUnlocked = false,
  });
}

const List<BrikThemeMeta> allThemeMeta = [
  BrikThemeMeta(
    id: BrikTheme.classic,
    name: 'Classic',
    emoji: '🟡',
    description: 'The original BrikStax look. Yellow on cream.',
    unlockCondition: 'Default theme',
    alwaysUnlocked: true,
  ),
  BrikThemeMeta(
    id: BrikTheme.darkBrick,
    name: 'Dark Brick',
    emoji: '🖤',
    description: 'Yellow on pure black. Easy on the eyes.',
    unlockCondition: 'Default dark theme',
    alwaysUnlocked: true,
  ),
  BrikThemeMeta(
    id: BrikTheme.starWars,
    name: 'Star Wars',
    emoji: '⭐',
    description: 'Imperial red and space black. Feel the Force.',
    unlockCondition: 'Own 5+ Star Wars sets',
  ),
  BrikThemeMeta(
    id: BrikTheme.ninjago,
    name: 'NINJAGO',
    emoji: '🥷',
    description: 'Spinjitzu red and storm grey. Ninja go!',
    unlockCondition: 'Own 3+ NINJAGO sets',
  ),
  BrikThemeMeta(
    id: BrikTheme.city,
    name: 'City',
    emoji: '🏙️',
    description: 'Sky blue and city concrete. Urban collector.',
    unlockCondition: 'Own 10+ City sets',
  ),
  BrikThemeMeta(
    id: BrikTheme.botanical,
    name: 'Botanical',
    emoji: '🌿',
    description: 'Leaf green and warm cream. For the plant parent.',
    unlockCondition: 'Own any Botanical Collection set',
  ),
  BrikThemeMeta(
    id: BrikTheme.icons,
    name: 'Icons',
    emoji: '👑',
    description: 'Deep navy and gold. Reserved for serious collectors.',
    unlockCondition: '\$10,000+ portfolio value',
  ),
  BrikThemeMeta(
    id: BrikTheme.spaceClassic,
    name: 'Space Classic',
    emoji: '🚀',
    description: 'Retro space blue and grey. Classic 80s vibes.',
    unlockCondition: 'Own any Classic Space set',
  ),
];

// ── Semantic color palette per theme ─────────────────────────────────────────
class BrikStaxColors extends ThemeExtension<BrikStaxColors> {
  final Color surface, surface2, surface3;
  final Color cardBg, cardBorder;
  final Color primary, primaryDark;
  final Color tx, tx2, tx3, txMuted;
  final Color headerBg, headerBorder;
  final Color navBg, navActive, navInactive;
  final Color inputFill, shadowColor;
  final bool  isDark;

  const BrikStaxColors({
    required this.surface,  required this.surface2,  required this.surface3,
    required this.cardBg,   required this.cardBorder,
    required this.primary,  required this.primaryDark,
    required this.tx,       required this.tx2,
    required this.tx3,      required this.txMuted,
    required this.headerBg, required this.headerBorder,
    required this.navBg,    required this.navActive,    required this.navInactive,
    required this.inputFill, required this.shadowColor,
    this.isDark = false,
  });

  @override
  BrikStaxColors copyWith({
    Color? surface, Color? surface2, Color? surface3,
    Color? cardBg, Color? cardBorder, Color? primary, Color? primaryDark,
    Color? tx, Color? tx2, Color? tx3, Color? txMuted,
    Color? headerBg, Color? headerBorder, Color? navBg,
    Color? navActive, Color? navInactive, Color? inputFill,
    Color? shadowColor, bool? isDark,
  }) => BrikStaxColors(
    surface:      surface      ?? this.surface,
    surface2:     surface2     ?? this.surface2,
    surface3:     surface3     ?? this.surface3,
    cardBg:       cardBg       ?? this.cardBg,
    cardBorder:   cardBorder   ?? this.cardBorder,
    primary:      primary      ?? this.primary,
    primaryDark:  primaryDark  ?? this.primaryDark,
    tx:           tx           ?? this.tx,
    tx2:          tx2          ?? this.tx2,
    tx3:          tx3          ?? this.tx3,
    txMuted:      txMuted      ?? this.txMuted,
    headerBg:     headerBg     ?? this.headerBg,
    headerBorder: headerBorder ?? this.headerBorder,
    navBg:        navBg        ?? this.navBg,
    navActive:    navActive    ?? this.navActive,
    navInactive:  navInactive  ?? this.navInactive,
    inputFill:    inputFill    ?? this.inputFill,
    shadowColor:  shadowColor  ?? this.shadowColor,
    isDark:       isDark       ?? this.isDark,
  );

  @override
  BrikStaxColors lerp(BrikStaxColors? other, double t) {
    if (other == null) return this;
    return BrikStaxColors(
      surface:      Color.lerp(surface,      other.surface,      t)!,
      surface2:     Color.lerp(surface2,     other.surface2,     t)!,
      surface3:     Color.lerp(surface3,     other.surface3,     t)!,
      cardBg:       Color.lerp(cardBg,       other.cardBg,       t)!,
      cardBorder:   Color.lerp(cardBorder,   other.cardBorder,   t)!,
      primary:      Color.lerp(primary,      other.primary,      t)!,
      primaryDark:  Color.lerp(primaryDark,  other.primaryDark,  t)!,
      tx:           Color.lerp(tx,           other.tx,           t)!,
      tx2:          Color.lerp(tx2,          other.tx2,          t)!,
      tx3:          Color.lerp(tx3,          other.tx3,          t)!,
      txMuted:      Color.lerp(txMuted,      other.txMuted,      t)!,
      headerBg:     Color.lerp(headerBg,     other.headerBg,     t)!,
      headerBorder: Color.lerp(headerBorder, other.headerBorder, t)!,
      navBg:        Color.lerp(navBg,        other.navBg,        t)!,
      navActive:    Color.lerp(navActive,    other.navActive,    t)!,
      navInactive:  Color.lerp(navInactive,  other.navInactive,  t)!,
      inputFill:    Color.lerp(inputFill,    other.inputFill,    t)!,
      shadowColor:  Color.lerp(shadowColor,  other.shadowColor,  t)!,
      isDark:       t < 0.5 ? this.isDark : other.isDark,
    );
  }
}

// ── Context extension ─────────────────────────────────────────────────────────
extension BrikStaxThemeX on BuildContext {
  BrikStaxColors get bt =>
      Theme.of(this).extension<BrikStaxColors>() ?? BrikColors.classic;
  bool get isDark => bt.isDark;
}

// ── All color palettes ────────────────────────────────────────────────────────
class BrikColors {
  BrikColors._();

  static const classic = BrikStaxColors(
    surface:      Color(0xFFF2EFE9),
    surface2:     Color(0xFFE8E4DC),
    surface3:     Color(0xFFDDD8CE),
    cardBg:       Color(0xFFFFFFFF),
    cardBorder:   Color(0xFF0A0907),
    primary:      Color(0xFFFFCB00),
    primaryDark:  Color(0xFFE6B800),
    tx:           Color(0xFF0A0907),
    tx2:          Color(0xFF555555),
    tx3:          Color(0xFF888888),
    txMuted:      Color(0xFFB0A898),
    headerBg:     Color(0xFFF2EFE9),
    headerBorder: Color(0xFF0A0907),
    navBg:        Color(0xFFFFFFFF),
    navActive:    Color(0xFF0A0907),
    navInactive:  Color(0xFF888888),
    inputFill:    Color(0xFFFFFFFF),
    shadowColor:  Color(0xFF0A0907),
  );

  static const darkBrick = BrikStaxColors(
    surface:      Color(0xFF121212),
    surface2:     Color(0xFF1E1E1E),
    surface3:     Color(0xFF2A2A2A),
    cardBg:       Color(0xFF1E1E1E),
    cardBorder:   Color(0xFF333333),
    primary:      Color(0xFFFFCB00),
    primaryDark:  Color(0xFFE6B800),
    tx:           Color(0xFFEDEDED),
    tx2:          Color(0xFFBBBBBB),
    tx3:          Color(0xFF999999),
    txMuted:      Color(0xFF666666),
    headerBg:     Color(0xFF0A0907),
    headerBorder: Color(0xFFFFCB00),
    navBg:        Color(0xFF0A0907),
    navActive:    Color(0xFFFFCB00),
    navInactive:  Color(0xFF777777),
    inputFill:    Color(0xFF1E1E1E),
    shadowColor:  Color(0xFF000000),
    isDark:       true,
  );

  static const starWars = BrikStaxColors(
    surface:      Color(0xFF0D0D0F),  // Deep space black
    surface2:     Color(0xFF1A1A1F),
    surface3:     Color(0xFF252530),
    cardBg:       Color(0xFF1A1A1F),
    cardBorder:   Color(0xFFCC0000),  // Imperial red border
    primary:      Color(0xFFCC0000),  // Imperial red
    primaryDark:  Color(0xFF990000),
    tx:           Color(0xFFE8E8E8),
    tx2:          Color(0xFFAAAAAA),
    tx3:          Color(0xFF777777),
    txMuted:      Color(0xFF555555),
    headerBg:     Color(0xFF0D0D0F),
    headerBorder: Color(0xFFCC0000),
    navBg:        Color(0xFF0D0D0F),
    navActive:    Color(0xFFCC0000),
    navInactive:  Color(0xFF555555),
    inputFill:    Color(0xFF1A1A1F),
    shadowColor:  Color(0xFFCC0000),
    isDark:       true,
  );

  static const ninjago = BrikStaxColors(
    surface:      Color(0xFF1A1A1A),  // Storm grey dark
    surface2:     Color(0xFF242424),
    surface3:     Color(0xFF303030),
    cardBg:       Color(0xFF242424),
    cardBorder:   Color(0xFFE53935),  // Spinjitzu red
    primary:      Color(0xFFE53935),
    primaryDark:  Color(0xFFC62828),
    tx:           Color(0xFFEEEEEE),
    tx2:          Color(0xFFBBBBBB),
    tx3:          Color(0xFF888888),
    txMuted:      Color(0xFF555555),
    headerBg:     Color(0xFF111111),
    headerBorder: Color(0xFFE53935),
    navBg:        Color(0xFF111111),
    navActive:    Color(0xFFE53935),
    navInactive:  Color(0xFF666666),
    inputFill:    Color(0xFF242424),
    shadowColor:  Color(0xFFE53935),
    isDark:       true,
  );

  static const city = BrikStaxColors(
    surface:      Color(0xFFF0F4F8),  // Light city concrete
    surface2:     Color(0xFFE2E8F0),
    surface3:     Color(0xFFCBD5E1),
    cardBg:       Color(0xFFFFFFFF),
    cardBorder:   Color(0xFF1565C0),  // City blue
    primary:      Color(0xFF1565C0),
    primaryDark:  Color(0xFF0D47A1),
    tx:           Color(0xFF1A202C),
    tx2:          Color(0xFF4A5568),
    tx3:          Color(0xFF718096),
    txMuted:      Color(0xFFA0AEC0),
    headerBg:     Color(0xFF1565C0),
    headerBorder: Color(0xFF0D47A1),
    navBg:        Color(0xFFFFFFFF),
    navActive:    Color(0xFF1565C0),
    navInactive:  Color(0xFF718096),
    inputFill:    Color(0xFFFFFFFF),
    shadowColor:  Color(0xFF1565C0),
  );

  static const botanical = BrikStaxColors(
    surface:      Color(0xFFF5F7F0),  // Warm botanical cream
    surface2:     Color(0xFFEBEFE3),
    surface3:     Color(0xFFD8E0CC),
    cardBg:       Color(0xFFFFFFFF),
    cardBorder:   Color(0xFF2E7D32),  // Leaf green
    primary:      Color(0xFF2E7D32),
    primaryDark:  Color(0xFF1B5E20),
    tx:           Color(0xFF1A2E1A),
    tx2:          Color(0xFF3D5A3D),
    tx3:          Color(0xFF6B8C6B),
    txMuted:      Color(0xFFA5BBA5),
    headerBg:     Color(0xFF2E7D32),
    headerBorder: Color(0xFF1B5E20),
    navBg:        Color(0xFFFFFFFF),
    navActive:    Color(0xFF2E7D32),
    navInactive:  Color(0xFF6B8C6B),
    inputFill:    Color(0xFFFFFFFF),
    shadowColor:  Color(0xFF2E7D32),
  );

  static const icons = BrikStaxColors(
    surface:      Color(0xFF0F1629),  // Deep collector navy
    surface2:     Color(0xFF1A2540),
    surface3:     Color(0xFF243050),
    cardBg:       Color(0xFF1A2540),
    cardBorder:   Color(0xFFB8860B),  // Antique gold
    primary:      Color(0xFFB8860B),
    primaryDark:  Color(0xFF8B6508),
    tx:           Color(0xFFE8D5A3),  // Warm parchment
    tx2:          Color(0xFFBBA875),
    tx3:          Color(0xFF8B7B55),
    txMuted:      Color(0xFF5A4E35),
    headerBg:     Color(0xFF0A0F1C),
    headerBorder: Color(0xFFB8860B),
    navBg:        Color(0xFF0A0F1C),
    navActive:    Color(0xFFB8860B),
    navInactive:  Color(0xFF5A4E35),
    inputFill:    Color(0xFF1A2540),
    shadowColor:  Color(0xFFB8860B),
    isDark:       true,
  );

  static const spaceClassic = BrikStaxColors(
    surface:      Color(0xFF1A1F2E),  // Retro space dark blue
    surface2:     Color(0xFF242B3D),
    surface3:     Color(0xFF2E3750),
    cardBg:       Color(0xFF242B3D),
    cardBorder:   Color(0xFF4D7CC7),  // Classic space blue
    primary:      Color(0xFF4D7CC7),
    primaryDark:  Color(0xFF3A63A8),
    tx:           Color(0xFFE0E8FF),
    tx2:          Color(0xFFAABBDD),
    tx3:          Color(0xFF7788AA),
    txMuted:      Color(0xFF445566),
    headerBg:     Color(0xFF111622),
    headerBorder: Color(0xFF4D7CC7),
    navBg:        Color(0xFF111622),
    navActive:    Color(0xFF4D7CC7),
    navInactive:  Color(0xFF445566),
    inputFill:    Color(0xFF242B3D),
    shadowColor:  Color(0xFF4D7CC7),
    isDark:       true,
  );

  static BrikStaxColors forTheme(BrikTheme t) => switch (t) {
    BrikTheme.classic      => classic,
    BrikTheme.darkBrick    => darkBrick,
    BrikTheme.starWars     => starWars,
    BrikTheme.ninjago      => ninjago,
    BrikTheme.city         => city,
    BrikTheme.botanical    => botanical,
    BrikTheme.icons        => icons,
    BrikTheme.spaceClassic => spaceClassic,
  };
}
