// lib/modules/avatar/models/achievement.dart

class Achievement {
  final String    id;
  final String    name;
  final String    description;
  final String    emoji;
  final String    cosmeticId;   // What it unlocks
  final String    condition;    // Human-readable condition

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.cosmeticId,
    required this.condition,
  });
}
