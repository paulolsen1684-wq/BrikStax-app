// lib/modules/avatar/widgets/brik_shop.dart
import 'package:flutter/material.dart';
import '../data/sprite_cosmetics.dart' as sprite;
import '../services/loot_service.dart';
import 'loot_roll_widget.dart';
import '../../../theme/app_theme.dart';

/// The Brik Shop — spend Briks on a guaranteed roll of a chosen rarity.
/// Uncommon = 2, Rare = 4, Epic = 8, Legendary = 16. Two dupes of a tier
/// always buy one roll of the tier above.
class BrikShop extends StatefulWidget {
  const BrikShop({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const BrikShop(),
    );
  }

  @override
  State<BrikShop> createState() => _BrikShopState();
}

class _BrikShopState extends State<BrikShop> {
  bool _buying = false;

  static const _offers = [
    (sprite.SpriteRarity.uncommon,  'Uncommon Roll',  Color(0xFF2E7D32)),
    (sprite.SpriteRarity.rare,      'Rare Roll',      Color(0xFF006CB7)),
    (sprite.SpriteRarity.epic,      'Epic Roll',      Color(0xFF8B00FF)),
    (sprite.SpriteRarity.legendary, 'Legendary Roll', Color(0xFFFFCB00)),
  ];

  Future<void> _buy(sprite.SpriteRarity rarity) async {
    if (_buying) return;
    setState(() => _buying = true);
    final result = await LootService.instance.buyGuaranteedRoll(rarity);
    setState(() => _buying = false);
    if (result != null && mounted) {
      await LootRollWidget.show(context, result.roll);
      if (mounted) setState(() {}); // refresh balance + remaining counts
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = LootService.instance;

    return Container(
      decoration: const BoxDecoration(
        color: BT.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: BT.ink, width: BT.bw)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewPadding.bottom + 20,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // grab handle
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 8),
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: BT.cream3,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Header: title + balance
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(children: [
            Text('Brik Shop', style: BT.display(size: 22)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: BT.ink,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('🧱', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                Text('${svc.briks}',
                    style: BT.display(size: 16, color: BT.yellow)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Guaranteed rolls — no dupes, ever.',
                style: BT.mono(size: 10, color: BT.tx3)),
          ),
        ),
        const SizedBox(height: 14),

        // Offers
        ..._offers.map((offer) {
          final rarity    = offer.$1;
          final label     = offer.$2;
          final color     = offer.$3;
          final cost      = LootService.brikCost(rarity);
          final remaining = svc.remainingOfRarity(rarity);
          final afford    = svc.briks >= cost;
          final enabled   = afford && remaining > 0 && !_buying;

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: GestureDetector(
              onTap: enabled ? () => _buy(rarity) : null,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: enabled ? BT.white : BT.cream2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: enabled ? color : BT.cream3,
                    width: enabled ? 2 : BT.bw,
                  ),
                  boxShadow: enabled
                      ? [BoxShadow(color: color.withOpacity(.3),
                          offset: const Offset(3, 3))]
                      : [],
                ),
                child: Row(children: [
                  // rarity swatch
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: color.withOpacity(enabled ? .15 : .06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: enabled ? color : BT.cream3, width: 2),
                    ),
                    child: Center(child: Text('🧱',
                        style: TextStyle(fontSize: 18,
                            color: enabled ? null : BT.txMuted))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: BT.body(size: 15,
                              color: enabled ? BT.ink : BT.txMuted)),
                      Text(
                        remaining > 0
                            ? '$remaining left to collect'
                            : 'All collected!',
                        style: BT.mono(size: 9,
                            color: enabled ? BT.tx3 : BT.txMuted),
                      ),
                    ],
                  )),
                  // price tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: enabled ? color : BT.cream3,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: enabled ? BT.ink : BT.cream3,
                          width: BT.bw),
                    ),
                    child: Text('🧱 $cost',
                        style: BT.body(size: 13,
                            color: enabled
                                ? (rarity == sprite.SpriteRarity.legendary
                                    ? BT.ink : Colors.white)
                                : BT.txMuted)),
                  ),
                ]),
              ),
            ),
          );
        }),

        const SizedBox(height: 4),
        Text('Earn Briks from daily claims and duplicate rolls',
            style: BT.mono(size: 9, color: BT.tx3)),
      ]),
    );
  }
}
