// lib/services/deals_service.dart
// Fetches the curated Deal-of-the-Day list from the BrikStax Worker (/deals),
// caches it in memory for the session, and filters out expired deals.
// Deals carry affiliate links — the UI shows an "Affiliate" disclosure tag.
import 'dart:convert';
import 'package:http/http.dart' as http;

class Deal {
  final String  id;
  final String  title;
  final String? setNum;
  final double? retailPrice;
  final double? dealPrice;
  final String? retailer;
  final String  url;          // affiliate link
  final String? imageUrl;
  final DateTime? expires;
  final bool    featured;
  final String? note;

  const Deal({
    required this.id,
    required this.title,
    required this.url,
    this.setNum,
    this.retailPrice,
    this.dealPrice,
    this.retailer,
    this.imageUrl,
    this.expires,
    this.featured = false,
    this.note,
  });

  /// Percent off, or null if prices missing.
  int? get percentOff {
    if (retailPrice == null || dealPrice == null || retailPrice == 0) return null;
    final pct = (1 - dealPrice! / retailPrice!) * 100;
    return pct.round();
  }

  bool get isExpired =>
      expires != null && DateTime.now().isAfter(expires!);

  factory Deal.fromJson(Map<String, dynamic> j) => Deal(
    id:          j['id']          as String? ?? '',
    title:       j['title']       as String? ?? 'LEGO Deal',
    setNum:      j['setNum']      as String?,
    retailPrice: (j['retailPrice'] as num?)?.toDouble(),
    dealPrice:   (j['dealPrice']   as num?)?.toDouble(),
    retailer:    j['retailer']    as String?,
    url:         j['url']         as String? ?? '',
    imageUrl:    j['imageUrl']    as String?,
    expires:     j['expires'] != null
        ? DateTime.tryParse(j['expires'] as String)
        : null,
    featured:    j['featured']    as bool? ?? false,
    note:        j['note']        as String?,
  );
}

class DealsService {
  DealsService._();
  static final instance = DealsService._();

  // Same Worker as eBay/barcode, /deals path.
  static const String _endpoint =
      'https://brikstax-worker.paul-olsen1684.workers.dev/deals';

  List<Deal>? _cache;
  DateTime?   _fetchedAt;

  /// Returns non-expired deals. Cached for the session (refreshes after 6h).
  Future<List<Deal>> fetch({bool force = false}) async {
    final fresh = _fetchedAt != null &&
        DateTime.now().difference(_fetchedAt!).inHours < 6;
    if (!force && _cache != null && fresh) return _cache!;

    try {
      final res = await http
          .get(Uri.parse(_endpoint))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return _cache ?? [];

      final data  = jsonDecode(res.body) as Map<String, dynamic>;
      final raw   = (data['deals'] as List?) ?? [];
      final deals = raw
          .map((e) => Deal.fromJson(e as Map<String, dynamic>))
          .where((d) => !d.isExpired && d.url.isNotEmpty)
          .toList();

      _cache = deals;
      _fetchedAt = DateTime.now();
      return deals;
    } catch (_) {
      return _cache ?? [];
    }
  }

  /// The single featured "Deal of the Day" (first featured, else first deal).
  Future<Deal?> featured() async {
    final all = await fetch();
    if (all.isEmpty) return null;
    return all.firstWhere((d) => d.featured, orElse: () => all.first);
  }
}
