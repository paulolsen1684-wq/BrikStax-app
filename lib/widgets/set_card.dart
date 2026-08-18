// lib/widgets/set_card.dart — BrikStax Brick UI set card
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/lego_set.dart';
import '../theme/app_theme.dart';
import 'atoms.dart';

class SetCard extends StatelessWidget {
  final LegoSet set;
  const SetCard({super.key, required this.set});

  @override
  Widget build(BuildContext context) {
    final ebay = set.ebayAvg;
    final roi  = set.roi;
    final tc   = themeColor(set.theme ?? '');

    return Container(
      decoration: BoxDecoration(
        color: BT.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BT.ink, width: BT.bw),
        boxShadow: BT.shadow,
      ),
      child: Row(children: [
        // Theme color stripe
        Container(
          width: 7,
          decoration: BoxDecoration(
            color: tc,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
          ),
        ),

        // Image
        Container(
          width: 68, height: 68,
          decoration: BoxDecoration(
            color: BT.cream,
            border: Border(right: BorderSide(color: BT.ink, width: BT.bw)),
          ),
          child: set.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: set.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _imgPlaceholder(),
                  errorWidget: (_, __, ___) => _imgPlaceholder(),
                )
              : _imgPlaceholder(),
        ),

        // Body
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(11, 9, 8, 9),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Row 1: name + condition
              Row(children: [
                Expanded(
                  child: Text(
                    set.name.isEmpty ? set.num : set.name,
                    style: BT.body(size: 13, weight: FontWeight.w800),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                CondBadge(set.status, small: true),
              ]),

              const SizedBox(height: 2),

              // Row 2: meta
              Text(
                [
                  set.num,
                  if (set.year != null) '${set.year}',
                  if (set.pieces != null) '${set.pieces} pcs',
                  if (set.qty > 1) '×${set.qty}',
                ].join(' · '),
                style: BT.mono(size: 9),
              ),

              const SizedBox(height: 5),

              // Row 3: theme + extras + source
              Wrap(spacing: 4, runSpacing: 3, children: [
                if (set.theme != null)
                  ThemeBadge(theme: set.theme!.split(' > ').first, compact: true),
                if (set.status == 'open' && set.openExtras.hasAnything)
                  ExtrasBadge(set.openExtras, compact: true),
                if (set.purchaseSource.earnsInsiderPoints)
                  SourceBadge(source: set.purchaseSource, compact: true),
              ]),

              const SizedBox(height: 5),

              // Row 4: prices + ROI -- the price cluster (Paid/MSRP/eBay)
              // used to sit in a plain Row with only a Spacer for slack, so
              // on a narrow-enough screen (confirmed via a real device's
              // cover/outer display) it hard-overflowed past the ROI badge
              // with nowhere to give. Expanded+FittedBox lets the whole
              // cluster scale down together instead -- same layout/size on
              // any normal screen, no data hidden, just shrinks as a unit
              // if it doesn't fit, rather than overflowing.
              Row(children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (set.paid != null)
                        PricePair(label: 'Paid', value: set.paid!),
                      if (set.retail != null) ...[
                        const SizedBox(width: 6),
                        PricePair(label: 'MSRP', value: set.retail!),
                      ],
                      if (ebay != null) ...[
                        const SizedBox(width: 6),
                        PricePair(label: 'eBay', value: ebay, color: BT.green),
                      ],
                    ]),
                  ),
                ),
                const SizedBox(width: 6),
                if (roi != null) RoiBadge(roi)
                 else if (set.purchaseSource == PurchaseSource.gwp) const GwpBadge(),
              ]),
            ]),
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Icon(Icons.chevron_right, color: BT.txMuted, size: 20),
        ),
      ]),
    );
  }

  Widget _imgPlaceholder() => Center(
    child: Icon(Icons.inventory_2_outlined, color: BT.cream3, size: 26),
  );
}
