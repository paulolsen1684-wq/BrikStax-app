// lib/models/lego_set.dart
import 'dart:convert';
import 'package:flutter/material.dart' show Color;
import '../services/constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PRICE POINT
// ─────────────────────────────────────────────────────────────────────────────
class PricePoint {
  final DateTime date;
  final double?  avg;
  final double?  median;
  final double?  min;
  final double?  max;
  final int      count;

  const PricePoint({
    required this.date,
    this.avg,
    this.median,
    this.min,
    this.max,
    this.count = 0,
  });

  factory PricePoint.fromJson(Map<String, dynamic> j) => PricePoint(
    date:   DateTime.fromMillisecondsSinceEpoch(j['d'] as int? ?? 0),
    avg:    (j['avg']    as dynamic?)?.toDouble(),
    median: (j['median'] as dynamic?)?.toDouble(),
    min:    (j['min']    as dynamic?)?.toDouble(),
    max:    (j['max']    as dynamic?)?.toDouble(),
    count:  j['cnt']    as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'd':      date.millisecondsSinceEpoch,
    'avg':    avg,
    'median': median,
    'min':    min,
    'max':    max,
    'cnt':    count,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// OPEN SET EXTRAS  (box / manual tracking)
// ─────────────────────────────────────────────────────────────────────────────
class OpenExtras {
  final bool hasBox;
  final bool hasManual;

  const OpenExtras({this.hasBox = false, this.hasManual = false});

  bool get hasAnything => hasBox || hasManual;

  String get label {
    if (hasBox && hasManual) return 'Box + Manual';
    if (hasBox)              return 'Box only';
    if (hasManual)           return 'Manual only';
    return 'No box/manual';
  }

  String get emoji {
    if (hasBox && hasManual) return '📦📖';
    if (hasBox)              return '📦';
    if (hasManual)           return '📖';
    return '✗';
  }

  OpenExtras copyWith({bool? hasBox, bool? hasManual}) => OpenExtras(
    hasBox:    hasBox    ?? this.hasBox,
    hasManual: hasManual ?? this.hasManual,
  );

  factory OpenExtras.fromJson(Map<String, dynamic> j) => OpenExtras(
    hasBox:    j['box']    as bool? ?? false,
    hasManual: j['manual'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {'box': hasBox, 'manual': hasManual};
}

// ─────────────────────────────────────────────────────────────────────────────
// PURCHASE SOURCE
// ─────────────────────────────────────────────────────────────────────────────
enum PurchaseSource {
  legoStore, amazon, target, walmart, ebay, facebook, gift, gwp, other;

  bool   get earnsInsiderPoints => this == PurchaseSource.legoStore;
  String get emoji {
    const m = {
      PurchaseSource.legoStore: '🟡',
      PurchaseSource.amazon:    '🟠',
      PurchaseSource.target:    '🔴',
      PurchaseSource.walmart:   '🔵',
      PurchaseSource.ebay:      '🟢',
      PurchaseSource.facebook:  '🟣',
      PurchaseSource.gift:      '🎁',
      PurchaseSource.gwp:       '⭐',
      PurchaseSource.other:     '⚪',
    };
    return m[this] ?? '⚪';
  }

  String get label {
    const m = {
      PurchaseSource.legoStore: 'LEGO Store / LEGO.com',
      PurchaseSource.amazon:    'Amazon',
      PurchaseSource.target:    'Target',
      PurchaseSource.walmart:   'Walmart',
      PurchaseSource.ebay:      'eBay',
      PurchaseSource.facebook:  'Facebook / Local',
      PurchaseSource.gift:      'Gift',
      PurchaseSource.gwp:       'GWP (Free)',
      PurchaseSource.other:     'Other',
    };
    return m[this] ?? 'Other';
  }

  String get key {
    const m = {
      PurchaseSource.legoStore: 'lego',
      PurchaseSource.amazon:    'amazon',
      PurchaseSource.target:    'target',
      PurchaseSource.walmart:   'walmart',
      PurchaseSource.ebay:      'ebay',
      PurchaseSource.facebook:  'facebook',
      PurchaseSource.gift:      'gift',
      PurchaseSource.gwp:       'gwp',
      PurchaseSource.other:     'other',
    };
    return m[this] ?? 'other';
  }

  static PurchaseSource fromKey(String? key) {
    const m = {
      'lego':     PurchaseSource.legoStore,
      'amazon':   PurchaseSource.amazon,
      'target':   PurchaseSource.target,
      'walmart':  PurchaseSource.walmart,
      'ebay':     PurchaseSource.ebay,
      'facebook': PurchaseSource.facebook,
      'gift':     PurchaseSource.gift,
      'gwp':      PurchaseSource.gwp,
    };
    return m[key] ?? PurchaseSource.other;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME COLORS
// ─────────────────────────────────────────────────────────────────────────────
const Map<String, Color> kThemeColors = {
  'Star Wars':       Color(0xFF3949AB),
  'Technic':         Color(0xFFE65100),
  'City':            Color(0xFF0D47A1),
  'Icons':           Color(0xFF6A1B9A),
  'Ideas':           Color(0xFF00695C),
  'Creator Expert':  Color(0xFF2E7D32),
  'Marvel':          Color(0xFFC62828),
  'DC':              Color(0xFF0A3055),
  'Harry Potter':    Color(0xFF4A148C),
  'Ninjago':         Color(0xFF212121),
  'Minecraft':       Color(0xFF33691E),
  'Speed Champions': Color(0xFFE53935),
  'Architecture':    Color(0xFF263238),
  'Art':             Color(0xFF880E4F),
  'Botanical':       Color(0xFF4CAF50),
  'Disney':          Color(0xFF6A1B9A),
  'Duplo':           Color(0xFFE65100),
  'Friends':         Color(0xFFE91E63),
  'Indiana Jones':   Color(0xFF795548),
  'Avatar':          Color(0xFF004D40),
  'Jurassic World':  Color(0xFF33691E),
  'Super Mario':     Color(0xFFB71C1C),
  'Sonic':           Color(0xFF1565C0),
  'GWP':             Color(0xFF37474F),
  'Seasonal':        Color(0xFF37474F),
};

Color themeColor(String? theme) {
  if (theme == null) return const Color(0xFF37474F);
  for (final entry in kThemeColors.entries) {
    if (theme.toLowerCase().contains(entry.key.toLowerCase())) {
      return entry.value;
    }
  }
  return const Color(0xFF37474F);
}

// ─────────────────────────────────────────────────────────────────────────────
// LEGO SET
// ─────────────────────────────────────────────────────────────────────────────
class LegoSet {
  final String id;

  // Identity
  final String  num;
  final String  name;
  final int?    pieces;
  final int?    year;
  final String? imageUrl;
  final String? theme;
  final String? subtheme;
  final bool    retired;
  final bool    verified;   // scan-verified; defaults true until scanner is live
  // From BrickSet's exitDate field -- often just Dec 31 of the retirement
  // year rather than a precise day (that's frequently the best info even
  // BrickSet has), but plenty precise for month-level tracking. Null means
  // never fetched, not "not retired" -- check `retired` for that.
  final DateTime? exitDate;


  // Collection state
  final String  status;   // 'sealed' | 'open'
  final int     qty;
  final OpenExtras openExtras;

  // Purchase
  final double?         retail;
  final double?         paid;
  final PurchaseSource  purchaseSource;
  final double?         insiderPointsOverride; // null = auto-calc at 5%

  // eBay market data
  final double?         ebaySealed;
  final double?         ebayOpen;
  final DateTime?       ebayFetchedAt;
  final List<PricePoint> phSealed;
  final List<PricePoint> phOpen;
  // True = we DID search and found 0 sealed/open listings (distinct from
  // "never searched", which is just ebaySealed/ebayOpen == null with these
  // flags also false). Lets the UI tell "no data yet" apart from
  // "searched, nothing sold recently" — and warn when a displayed price is
  // borrowed from the wrong condition because of it.
  final bool             sealedZeroResults;
  final bool             openZeroResults;

  // Notes
  final String   notes;
  final DateTime addedAt;

  const LegoSet({
    required this.id,
    required this.num,
    this.name         = '',
    this.pieces,
    this.year,
    this.imageUrl,
    this.theme,
    this.subtheme,
    this.retired      = false,
    this.verified     = true,
    this.exitDate,
    this.status       = 'sealed',
    this.qty          = 1,
    this.openExtras   = const OpenExtras(),
    this.retail,
    this.paid,
    this.purchaseSource = PurchaseSource.other,
    this.insiderPointsOverride,
    this.ebaySealed,
    this.ebayOpen,
    this.ebayFetchedAt,
    this.phSealed     = const [],
    this.phOpen       = const [],
    this.sealedZeroResults = false,
    this.openZeroResults   = false,
    this.notes        = '',
    required this.addedAt,
  });

  // ── Computed ──────────────────────────────────────────────────────────────

  /// Relevant eBay price for this set's condition
  double? get ebayAvg =>
      status == 'sealed' ? (ebaySealed ?? ebayOpen) : (ebayOpen ?? ebaySealed);

  /// True when ebayAvg is being sourced from the WRONG condition because no
  /// comps exist for this set's actual status. The UI should flag this
  /// instead of silently presenting it as an apples-to-apples ROI.
  bool get ebayAvgIsFallback {
    if (status == 'sealed') {
      return ebaySealed == null && ebayOpen != null;
    } else {
      return ebayOpen == null && ebaySealed != null;
    }
  }

  /// True if we've actively searched for this set's condition and come up
  /// empty (as opposed to simply never having checked).
  bool get relevantConditionHasZeroResults =>
      status == 'sealed' ? sealedZeroResults : openZeroResults;

  /// Insider points earned (auto or override)
  double? get insiderPoints {
    if (!purchaseSource.earnsInsiderPoints || paid == null) return null;
    return insiderPointsOverride ?? (paid! * K.insiderPointsRate);
  }

  /// True cost after Insider points
  double? get effectivePaid {
    if (paid == null) return null;
    return paid! - (insiderPoints ?? 0);
  }

  /// ROI vs effective paid
  double? get roi {
    final basis = effectivePaid ?? paid;
    final market = ebayAvg;
    if (basis == null || basis == 0 || market == null) return null;
    return (market - basis) / basis * 100;
  }

  double? get vsRetail {
    if (paid == null || retail == null) return null;
    return paid! - retail!;
  }

  double? get sealedPremium {
    if (ebaySealed == null || ebayOpen == null) return null;
    return ebaySealed! - ebayOpen!;
  }

  /// Trend % from first to last price point
  double? get trendPct {
    final ph = status == 'sealed' ? phSealed : phOpen;
    if (ph.length < 2) return null;
    final first = ph.first.avg;
    final last  = ph.last.avg;
    if (first == null || last == null || first == 0) return null;
    return (last - first) / first * 100;
  }

  /// Whether eBay data is stale
  bool get ebayIsStale {
    if (ebayFetchedAt == null) return true;
    return DateTime.now().difference(ebayFetchedAt!).inDays >= K.ebayStaleAfterDays;
  }

  Color get themeColorValue => themeColor(theme);

  /// Months elapsed since this set retired, or null if we don't have a
  /// retirement date (never fetched from BrickSet) or it hasn't retired yet.
  int? get monthsSinceRetirement {
    if (exitDate == null) return null;
    final now = DateTime.now();
    if (now.isBefore(exitDate!)) return null;
    return (now.year - exitDate!.year) * 12 + (now.month - exitDate!.month);
  }

  /// True during the ~18-24 months after retirement collectors watch for a
  /// secondary-market price bump, as retail supply dries up and demand from
  /// people who missed the set climbs.
  bool get inRetirementWindow {
    final m = monthsSinceRetirement;
    return m != null && m >= 18 && m <= 24;
  }

  // ── Serialisation ─────────────────────────────────────────────────────────

  factory LegoSet.fromJson(Map<String, dynamic> j) {
    List<PricePoint> ph(dynamic raw) {
      if (raw == null) return const [];
      return (raw as List).map((e) => PricePoint.fromJson(e as Map<String, dynamic>)).toList();
    }

    return LegoSet(
      id:                   j['id']      as String? ?? j['num'] as String? ?? '',
      num:                  j['num']     as String? ?? '',
      name:                 j['name']    as String? ?? '',
      pieces:               j['pieces']  as int?,
      year:                 j['year']    as int?,
      imageUrl:             j['img']     as String?,
      theme:                j['theme']   as String?,
      subtheme:             j['subtheme']as String?,
      retired:              j['retired'] as bool? ?? false,
      verified:             j['verified'] as bool? ?? true,
      exitDate:             j['exitDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(j['exitDate'] as int)
          : null,
      status:               j['status']  as String? ?? 'sealed',
      qty:                  j['qty']     as int? ?? 1,
      openExtras:           j['extras'] != null
          ? OpenExtras.fromJson(j['extras'] as Map<String, dynamic>)
          : const OpenExtras(),
      retail:               (j['retail'] as dynamic?)?.toDouble(),
      paid:                 (j['paid']   as dynamic?)?.toDouble(),
      purchaseSource:       PurchaseSource.fromKey(j['source'] as String?),
      insiderPointsOverride:(j['insiderPts'] as dynamic?)?.toDouble(),
      ebaySealed:           (j['ebS']    as dynamic?)?.toDouble(),
      ebayOpen:             (j['ebO']    as dynamic?)?.toDouble(),
      ebayFetchedAt:        j['ebAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(j['ebAt'] as int)
          : null,
      phSealed:             ph(j['phS']),
      phOpen:               ph(j['phO']),
      sealedZeroResults:    j['ebSZero'] as bool? ?? false,
      openZeroResults:      j['ebOZero'] as bool? ?? false,
      notes:                j['notes']   as String? ?? '',
      addedAt:              j['added'] != null
          ? DateTime.fromMillisecondsSinceEpoch(j['added'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id':         id,
    'num':        num,
    'name':       name,
    'pieces':     pieces,
    'year':       year,
    'img':        imageUrl,
    'theme':      theme,
    'subtheme':   subtheme,
    'retired':    retired,
    'verified':   verified,
    'exitDate':   exitDate?.millisecondsSinceEpoch,
    'status':     status,
    'qty':        qty,
    'extras':     openExtras.toJson(),
    'retail':     retail,
    'paid':       paid,
    'source':     purchaseSource.key,
    'insiderPts': insiderPointsOverride,
    'ebS':        ebaySealed,
    'ebO':        ebayOpen,
    'ebAt':       ebayFetchedAt?.millisecondsSinceEpoch,
    'phS':        phSealed.map((p) => p.toJson()).toList(),
    'phO':        phOpen.map((p) => p.toJson()).toList(),
    'ebSZero':    sealedZeroResults,
    'ebOZero':    openZeroResults,
    'notes':      notes,
    'added':      addedAt.millisecondsSinceEpoch,
  };

  LegoSet copyWith({
    String?         name,
    int?            pieces,
    int?            year,
    String?         imageUrl,
    String?         theme,
    String?         subtheme,
    bool?           retired,
    bool?           verified,
    DateTime?       exitDate,
    String?         status,
    int?            qty,
    OpenExtras?     openExtras,
    double?         retail,
    double?         paid,
    PurchaseSource? purchaseSource,
    double?         insiderPointsOverride,
    double?         ebaySealed,
    double?         ebayOpen,
    DateTime?       ebayFetchedAt,
    List<PricePoint>? phSealed,
    List<PricePoint>? phOpen,
    bool?           sealedZeroResults,
    bool?           openZeroResults,
    String?         notes,
  }) => LegoSet(
    id:                   id,
    num:                  num,
    name:                 name              ?? this.name,
    pieces:               pieces            ?? this.pieces,
    year:                 year              ?? this.year,
    imageUrl:             imageUrl          ?? this.imageUrl,
    theme:                theme             ?? this.theme,
    subtheme:             subtheme          ?? this.subtheme,
    retired:              retired           ?? this.retired,
    verified:             verified          ?? this.verified,
    exitDate:             exitDate          ?? this.exitDate,
    status:               status            ?? this.status,
    qty:                  qty               ?? this.qty,
    openExtras:           openExtras        ?? this.openExtras,
    retail:               retail            ?? this.retail,
    paid:                 paid              ?? this.paid,
    purchaseSource:       purchaseSource    ?? this.purchaseSource,
    insiderPointsOverride:insiderPointsOverride ?? this.insiderPointsOverride,
    ebaySealed:           ebaySealed        ?? this.ebaySealed,
    ebayOpen:             ebayOpen          ?? this.ebayOpen,
    ebayFetchedAt:        ebayFetchedAt     ?? this.ebayFetchedAt,
    phSealed:             phSealed          ?? this.phSealed,
    phOpen:               phOpen            ?? this.phOpen,
    sealedZeroResults:    sealedZeroResults ?? this.sealedZeroResults,
    openZeroResults:      openZeroResults   ?? this.openZeroResults,
    notes:                notes             ?? this.notes,
    addedAt:              addedAt,
  );
}
