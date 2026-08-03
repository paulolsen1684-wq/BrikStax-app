// lib/modules/avatar/models/bundle.dart
import 'package:flutter/material.dart' show Color;

enum BundleRarity { rare, epic, legendary }

class CosmeticBundle {
  final String       id;
  final String       name;
  final String       description;
  final String       emoji;
  final BundleRarity rarity;
  final List<String> cosmeticIds;
  final String?      unlockCondition;

  const CosmeticBundle({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.rarity,
    required this.cosmeticIds,
    this.unlockCondition,
  });

  String get rarityLabel => switch (rarity) {
    BundleRarity.rare      => 'Rare Bundle',
    BundleRarity.epic      => 'Epic Bundle',
    BundleRarity.legendary => 'Legendary Bundle',
  };

  Color get rarityColor => switch (rarity) {
    BundleRarity.rare      => const Color(0xFF006CB7),
    BundleRarity.epic      => const Color(0xFF8B00FF),
    BundleRarity.legendary => const Color(0xFFFFCB00),
  };
}
