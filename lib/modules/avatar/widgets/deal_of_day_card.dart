// lib/modules/avatar/widgets/deal_of_day_card.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/deals_service.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_themes.dart';

/// Dashboard "Deal of the Day" card. Fetches the featured deal from the Worker.
/// Renders nothing while loading or if there's no deal. Includes the required
/// affiliate disclosure tag.
class DealOfDayCard extends StatefulWidget {
  const DealOfDayCard({super.key});
  @override State<DealOfDayCard> createState() => _State();
}

class _State extends State<DealOfDayCard> {
  Deal? _deal;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await DealsService.instance.featured();
    if (mounted) setState(() { _deal = d; _loaded = true; });
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _deal == null) return const SizedBox.shrink();
    final bt  = context.bt;
    final d   = _deal!;
    final off = d.percentOff;

    return GestureDetector(
      onTap: () => _open(d.url),
      child: Container(
        decoration: BoxDecoration(
          color: bt.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: bt.cardBorder, width: BT.bw),
          boxShadow: [BoxShadow(color: bt.shadowColor, offset: const Offset(3, 3))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header strip — stays ink/yellow as brand element
          Container(
            width: double.infinity,
            color: BT.ink,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(children: [
              Text('🔥 DEAL OF THE DAY',
                  style: BT.mono(size: 9, color: BT.yellow)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: BT.yellow.withOpacity(.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('AFFILIATE',
                    style: BT.mono(size: 7, color: BT.yellow)),
              ),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              // Image
              if (d.imageUrl != null)
                Container(
                  width: 64, height: 64,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: bt.cardBorder, width: BT.bw),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(d.imageUrl!, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.image_not_supported,
                              color: bt.txMuted, size: 24)),
                ),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.title, style: BT.body(size: 14, color: bt.tx),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (d.setNum != null)
                    Text('#${d.setNum}${d.retailer != null ? " · ${d.retailer}" : ""}',
                        style: BT.mono(size: 9, color: bt.tx3)),
                  const SizedBox(height: 6),
                  Row(children: [
                    if (d.dealPrice != null)
                      Text('\$${d.dealPrice!.toStringAsFixed(0)}',
                          style: BT.display(size: 18, color: BT.green)),
                    const SizedBox(width: 6),
                    if (d.retailPrice != null && d.dealPrice != null)
                      Text('\$${d.retailPrice!.toStringAsFixed(0)}',
                          style: BT.mono(size: 10, color: bt.txMuted).copyWith(
                              decoration: TextDecoration.lineThrough)),
                    const Spacer(),
                    if (off != null && off > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: BT.greenBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: BT.green, width: BT.bw),
                        ),
                        child: Text('-$off%',
                            style: BT.display(size: 13, color: BT.green)),
                      ),
                  ]),
                  if (d.note != null) ...[
                    const SizedBox(height: 4),
                    Text(d.note!, style: BT.mono(size: 9, color: bt.tx2)),
                  ],
                ],
              )),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Text('BrikStax may earn a commission from this link.',
                style: BT.mono(size: 7, color: bt.txMuted)),
          ),
        ]),
      ),
    );
  }
}
