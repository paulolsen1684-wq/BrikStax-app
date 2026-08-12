// lib/models/checker_part.dart
//
// Response shape for the Worker's GET /parts?set=<num> endpoint (see
// cloudflare-worker/worker.js's handleParts) -- the same endpoint
// cloudflare-site/checker.html has always used. `id` is "{partNum}__{colorId}",
// a stable per-part-per-color key already used as the merge key on the
// server side; PartCheckService persists progress against this same id.
//
// NOTE: `qty` is the set's raw per-part quantity as Rebrickable reports it,
// which already includes spares baked in (handleParts sums every row for a
// part_num+color_id pair regardless of is_spare) -- same behavior the
// website version has always had. Unlike handlePartsMerge (parts-merge
// endpoint), this doesn't separate out a spareQty, so "Need 3" can include
// 1 spare LEGO already boxed extra. Known parity gap with the merger, not
// fixed here -- would need a handleParts change (and a matching website
// update) to address for both surfaces at once.
// Top-level, not a class member -- a `num`-typed field on CheckerSetInfo
// below shadows the core `num` type within that class's own body, so any
// `as num` cast has to happen out here instead.
int? _asInt(dynamic v) => v == null ? null : (v as num).toInt();

class CheckerSetInfo {
  final String num;
  final String name;
  final int? year;
  final int? numParts;
  final String? imgUrl;

  const CheckerSetInfo({
    required this.num,
    required this.name,
    this.year,
    this.numParts,
    this.imgUrl,
  });

  factory CheckerSetInfo.fromJson(Map<String, dynamic> j) => CheckerSetInfo(
        num: j['num'] as String? ?? '',
        name: j['name'] as String? ?? '',
        year: _asInt(j['year']),
        numParts: _asInt(j['numParts']),
        imgUrl: j['imgUrl'] as String?,
      );
}

class CheckerPart {
  final String id; // "{partNum}__{colorId}"
  final String partNum;
  final String name;
  final String color;
  final String? colorHex;
  final int qty; // needed (spares included, see note above)
  final String? imgUrl;

  const CheckerPart({
    required this.id,
    required this.partNum,
    required this.name,
    required this.color,
    this.colorHex,
    required this.qty,
    this.imgUrl,
  });

  factory CheckerPart.fromJson(Map<String, dynamic> j) => CheckerPart(
        id: j['id'] as String? ?? '',
        partNum: j['partNum'] as String? ?? '',
        name: j['name'] as String? ?? '',
        color: j['color'] as String? ?? '',
        colorHex: j['colorHex'] as String?,
        qty: (j['qty'] as num?)?.toInt() ?? 0,
        imgUrl: j['imgUrl'] as String?,
      );
}

enum CheckerPartStatus { complete, partial, missing }

CheckerPartStatus checkerPartStatus(int have, int need) {
  if (have >= need) return CheckerPartStatus.complete;
  if (have > 0) return CheckerPartStatus.partial;
  return CheckerPartStatus.missing;
}
