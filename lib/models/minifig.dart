// lib/models/minifig.dart
// A LEGO minifig the user owns or wants, mirroring WishlistItem/LegoSet's
// shape (plain immutable class, compact JSON keys, copyWith). Identity
// fields (figNum/name/imageUrl/numParts) come from Rebrickable's free
// minifig catalog; valueUsd/valueFetchedAt come from BrickEconomy via the
// Worker's scarce, D1-cached /brickeconomy/value endpoint -- see
// MinifigService.refreshValue and api.dart's fetchMinifigValue for why that
// half is never auto-fetched.
import '../services/constants.dart';

class Minifig {
  final String id;                // local identity, defaults to figNum
  final String figNum;             // Rebrickable fig_num, e.g. "fig-000001"
                                    // (NOT BrickLink's "sw0001"-style scheme)
  final String name;
  final String? imageUrl;
  final int? numParts;

  // Collection state
  final String status;            // 'owned' | 'wanted'
  final int qty;
  final String condition;         // 'mint' | 'good' | 'incomplete' -- loose
                                   // figs, not sealed/open like LegoSet
  final List<String> fromSetNums; // sets it's known to come from
                                   // (Rebrickable-sourced, informational only)

  // BrickEconomy value cache -- mirrors LegoSet's ebaySealed/ebayFetchedAt
  // shape, one condition only (no sealed/open split -- a loose minifig has
  // no equivalent distinction).
  final double? valueUsd;
  final DateTime? valueFetchedAt;
  final bool valueZeroResult;     // fetched, BrickEconomy had no value for it

  final String notes;
  final DateTime addedAt;

  const Minifig({
    required this.id,
    required this.figNum,
    this.name = '',
    this.imageUrl,
    this.numParts,
    this.status = 'owned',
    this.qty = 1,
    this.condition = 'mint',
    this.fromSetNums = const [],
    this.valueUsd,
    this.valueFetchedAt,
    this.valueZeroResult = false,
    this.notes = '',
    required this.addedAt,
  });

  // ── Computed ──────────────────────────────────────────────────────────────

  bool get hasValue => valueUsd != null;

  /// A staleness *indicator* only -- never drives an auto-refresh, unlike
  /// LegoSet.ebayIsStale. See K.minifigValueStaleAfterDays's own comment.
  bool get valueIsStale =>
      valueFetchedAt == null ||
      DateTime.now().difference(valueFetchedAt!).inDays >=
          K.minifigValueStaleAfterDays;

  // ── Serialization (JSON, like LegoSet/WishlistItem) ────────────────────────

  factory Minifig.fromJson(Map<String, dynamic> j) => Minifig(
    id:              j['id']   as String? ?? j['fig'] as String? ?? '',
    figNum:          j['fig']  as String? ?? '',
    name:            j['name'] as String? ?? '',
    imageUrl:        j['img']  as String?,
    numParts:        j['parts'] as int?,
    status:          j['status'] as String? ?? 'owned',
    qty:             j['qty']  as int? ?? 1,
    condition:       j['cond'] as String? ?? 'mint',
    fromSetNums:     (j['sets'] as List?)?.cast<String>() ?? const [],
    valueUsd:        (j['val'] as dynamic)?.toDouble(),
    valueFetchedAt:  j['valAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(j['valAt'] as int)
        : null,
    valueZeroResult: j['valZero'] as bool? ?? false,
    notes:           j['notes'] as String? ?? '',
    addedAt:         j['added'] != null
        ? DateTime.fromMillisecondsSinceEpoch(j['added'] as int)
        : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id':      id,
    'fig':     figNum,
    'name':    name,
    'img':     imageUrl,
    'parts':   numParts,
    'status':  status,
    'qty':     qty,
    'cond':    condition,
    'sets':    fromSetNums,
    'val':     valueUsd,
    'valAt':   valueFetchedAt?.millisecondsSinceEpoch,
    'valZero': valueZeroResult,
    'notes':   notes,
    'added':   addedAt.millisecondsSinceEpoch,
  };

  Minifig copyWith({
    String? name,
    String? imageUrl,
    int? numParts,
    String? status,
    int? qty,
    String? condition,
    List<String>? fromSetNums,
    double? valueUsd,
    DateTime? valueFetchedAt,
    bool? valueZeroResult,
    String? notes,
  }) => Minifig(
    id:              id,
    figNum:          figNum,
    name:            name            ?? this.name,
    imageUrl:        imageUrl        ?? this.imageUrl,
    numParts:        numParts        ?? this.numParts,
    status:          status          ?? this.status,
    qty:             qty             ?? this.qty,
    condition:       condition       ?? this.condition,
    fromSetNums:     fromSetNums     ?? this.fromSetNums,
    valueUsd:        valueUsd        ?? this.valueUsd,
    valueFetchedAt:  valueFetchedAt  ?? this.valueFetchedAt,
    valueZeroResult: valueZeroResult ?? this.valueZeroResult,
    notes:           notes           ?? this.notes,
    addedAt:         addedAt,
  );
}
