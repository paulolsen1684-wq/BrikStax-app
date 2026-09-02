// lib/models/wishlist_item.dart
// A set the user WANTS (not owns). Lighter than LegoSet. Tracks a target price
// and the latest known market price so we can alert when it's a good time to buy.
import '../models/lego_set.dart' show PricePoint;

class WishlistItem {
  final String   id;
  final String   num;          // set number
  final String   name;
  final String?  imageUrl;
  final String?  theme;
  final double?  retailPrice;
  final double?  targetPrice;  // "alert me at or below this"
  final double?  currentPrice; // last fetched market value
  final DateTime? lastChecked;
  final List<PricePoint> priceHistory;
  final bool     notifyOnTarget; // alert when <= targetPrice
  final bool     notifyOnDrop;   // alert on a significant drop
  final DateTime addedAt;

  const WishlistItem({
    required this.id,
    required this.num,
    this.name = '',
    this.imageUrl,
    this.theme,
    this.retailPrice,
    this.targetPrice,
    this.currentPrice,
    this.lastChecked,
    this.priceHistory = const [],
    this.notifyOnTarget = true,
    this.notifyOnDrop = false,
    required this.addedAt,
  });

  // ── Computed ──────────────────────────────────────────────────────────────

  /// True if the current price meets the user's target.
  bool get atOrBelowTarget {
    if (targetPrice == null || currentPrice == null) return false;
    return currentPrice! <= targetPrice!;
  }

  /// 0..1 progress from retail down to target (how close to the goal price).
  /// 1.0 means we've reached/passed target.
  double? get progressToTarget {
    if (targetPrice == null || currentPrice == null || retailPrice == null) {
      return null;
    }
    final span = retailPrice! - targetPrice!;
    if (span <= 0) return atOrBelowTarget ? 1.0 : 0.0;
    final drop = retailPrice! - currentPrice!;
    final p = drop / span;
    if (p < 0) return 0.0;
    if (p > 1) return 1.0;
    return p;
  }

  /// Dollars still needed to fall to reach target (>=0), or null.
  double? get amountAboveTarget {
    if (targetPrice == null || currentPrice == null) return null;
    final diff = currentPrice! - targetPrice!;
    return diff < 0 ? 0 : diff;
  }

  /// % discount off retail at the current price.
  int? get percentOffRetail {
    if (retailPrice == null || currentPrice == null || retailPrice == 0) {
      return null;
    }
    return ((1 - currentPrice! / retailPrice!) * 100).round();
  }

  // ── Serialization (JSON, like LegoSet) ─────────────────────────────────────

  factory WishlistItem.fromJson(Map<String, dynamic> j) {
    List<PricePoint> ph(dynamic raw) {
      if (raw == null) return const [];
      return (raw as List)
          .map((e) => PricePoint.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return WishlistItem(
      id:            j['id']   as String? ?? j['num'] as String? ?? '',
      num:           j['num']  as String? ?? '',
      name:          j['name'] as String? ?? '',
      imageUrl:      j['img']  as String?,
      theme:         j['theme'] as String?,
      retailPrice:   (j['retail']  as dynamic)?.toDouble(),
      targetPrice:   (j['target']  as dynamic)?.toDouble(),
      currentPrice:  (j['current'] as dynamic)?.toDouble(),
      lastChecked:   j['checked'] != null
          ? DateTime.fromMillisecondsSinceEpoch(j['checked'] as int)
          : null,
      priceHistory:  ph(j['ph']),
      notifyOnTarget: j['nTarget'] as bool? ?? true,
      notifyOnDrop:   j['nDrop']   as bool? ?? false,
      addedAt:       j['added'] != null
          ? DateTime.fromMillisecondsSinceEpoch(j['added'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id':      id,
    'num':     num,
    'name':    name,
    'img':     imageUrl,
    'theme':   theme,
    'retail':  retailPrice,
    'target':  targetPrice,
    'current': currentPrice,
    'checked': lastChecked?.millisecondsSinceEpoch,
    'ph':      priceHistory.map((p) => p.toJson()).toList(),
    'nTarget': notifyOnTarget,
    'nDrop':   notifyOnDrop,
    'added':   addedAt.millisecondsSinceEpoch,
  };

  WishlistItem copyWith({
    String?   name,
    String?   imageUrl,
    String?   theme,
    double?   retailPrice,
    double?   targetPrice,
    double?   currentPrice,
    DateTime? lastChecked,
    List<PricePoint>? priceHistory,
    bool?     notifyOnTarget,
    bool?     notifyOnDrop,
  }) => WishlistItem(
    id:            id,
    num:           num,
    name:          name           ?? this.name,
    imageUrl:      imageUrl        ?? this.imageUrl,
    theme:         theme          ?? this.theme,
    retailPrice:   retailPrice    ?? this.retailPrice,
    targetPrice:   targetPrice    ?? this.targetPrice,
    currentPrice:  currentPrice   ?? this.currentPrice,
    lastChecked:   lastChecked    ?? this.lastChecked,
    priceHistory:  priceHistory   ?? this.priceHistory,
    notifyOnTarget: notifyOnTarget ?? this.notifyOnTarget,
    notifyOnDrop:   notifyOnDrop   ?? this.notifyOnDrop,
    addedAt:       addedAt,
  );
}
