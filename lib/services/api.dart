// lib/services/api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';
import 'storage.dart';
import '../models/brickset_extras.dart';
import '../models/checker_part.dart';
import '../models/merge_part.dart';

class Api {
  Api._();
  static final Api instance = Api._();

  final _client = http.Client();

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> _get(Uri uri,
      {Map<String, String>? headers}) async {
    try {
      final r = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return null;
      return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── Rebrickable ────────────────────────────────────────────────────────────

  /// Look up a set by EAN/UPC barcode via BrickSet directly
  Future<Map<String, dynamic>?> fetchSetByBarcode(String barcode) async {
    // Try BrickSet EAN lookup via Worker proxy
    final params = jsonEncode({'EAN': barcode, 'pageSize': 1});
    final bsUrl  = 'https://brickset.com/api/v3.asmx/getSets'
        '?apiKey=${Uri.encodeComponent(K.bsKey)}'
        '&userHash='
        '&params=${Uri.encodeComponent(params)}';

    String? setNum = await _brickSetEanLookup(bsUrl);

    // If not found, try with leading zero stripped (UPC vs EAN)
    if (setNum == null && barcode.length == 12) {
      final ean13 = '0$barcode';
      final bsUrl2 = 'https://brickset.com/api/v3.asmx/getSets'
          '?apiKey=${Uri.encodeComponent(K.bsKey)}'
          '&userHash='
          '&params=${Uri.encodeComponent(jsonEncode({'EAN': ean13, 'pageSize': 1}))}';
      setNum = await _brickSetEanLookup(bsUrl2);
    }

    if (setNum == null) return null;

    // Got the set number — fetch full details from Rebrickable
    return await fetchSet(setNum);
  }

  Future<String?> _brickSetEanLookup(String bsUrl) async {
    try {
      final r = await _client
          .get(Uri.parse(bsUrl))
          .timeout(const Duration(seconds: 14));
      if (r.statusCode != 200) return null;
      final body = r.body;
      final ji   = body.indexOf('{');
      if (ji < 0) return null;
      final d    = jsonDecode(body.substring(ji)) as Map<String, dynamic>;
      if (d['status'] != 'success') return null;
      final sets = d['sets'] as List?;
      if (sets == null || sets.isEmpty) return null;
      final s = sets[0] as Map<String, dynamic>;
      final num = (s['number'] as String? ?? '')
          .replaceAll(RegExp(r'-\d+$'), '');
      return num.isNotEmpty ? num : null;
    } catch (_) {
      return null;
    }
  }

  /// Full set details including image, pieces, year, theme_id
  Future<Map<String, dynamic>?> fetchSet(String num) async {
    final sn = num.contains('-') ? num : '$num-1';
    final d = await _get(
      Uri.parse('https://rebrickable.com/api/v3/lego/sets/$sn/'),
      headers: {'Authorization': 'key ${K.rbKey}'},
    );
    if (d == null) return null;

    // Resolve theme name
    final themeId = d['theme_id'] as int?;
    if (themeId != null) {
      final name = await resolveTheme(themeId);
      if (name != null) d['theme_name'] = name;
    }
    return d;
  }

  /// Full piece checklist for a set (images, needed qty per part+color) --
  /// the same Worker endpoint cloudflare-site/checker.html has always used
  /// (GET /parts?set=, see handleParts in cloudflare-worker/worker.js), now
  /// also the backend for the native Parts Checker screen. Returns null on
  /// any failure (bad set number, network error) -- callers show a generic
  /// "couldn't load" message, matching fetchSet's own null-on-failure style.
  Future<({CheckerSetInfo set, List<CheckerPart> parts})?> fetchPartsChecklist(
      String num) async {
    final d = await _get(Uri.parse(
        '${K.workerUrl}parts?set=${Uri.encodeComponent(num)}'));
    if (d == null) return null;
    final s = d['set'] as Map<String, dynamic>?;
    final p = d['parts'] as List<dynamic>?;
    if (s == null || p == null) return null;
    return (
      set: CheckerSetInfo.fromJson(s),
      parts: p
          .map((e) => CheckerPart.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Merges up to 20 official LEGO sets' piece lists into one combined list
  /// via the Worker's POST /parts-merge (see handlePartsMerge in
  /// cloudflare-worker/worker.js / PARTS_MERGE_WORKER.js) -- same endpoint
  /// cloudflare-site/parts-merger.html uses, MOC upload not supported here
  /// (see merge_part.dart's file doc comment for why). Unlike _get's blanket
  /// null-on-failure, a failed merge can still carry real per-set reasons
  /// (e.g. one typo'd set number among five valid ones) worth showing the
  /// user, so failures come back as a `MergeResult` with `error` set, not
  /// null -- callers should check `.success` rather than null-check this.
  Future<MergeResult> mergeParts(List<String> setNums) async {
    try {
      final r = await _client
          .post(
            Uri.parse('${K.workerUrl}parts-merge'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'ids': setNums}),
          )
          .timeout(const Duration(seconds: 40));
      final data = jsonDecode(r.body) as Map<String, dynamic>?;
      if (data == null) {
        return MergeResult.failure('Server error (${r.statusCode})');
      }
      final warnings = (data['warnings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [];
      if (data['success'] != true) {
        return MergeResult.failure(
          warnings.isNotEmpty
              ? warnings.join(' ')
              : (data['error'] as String? ?? 'Server error (${r.statusCode})'),
          warnings: warnings,
        );
      }
      final parts = parseMergeCsv(data['csv'] as String? ?? '');
      return MergeResult.success(
        parts: parts,
        setCount: data['setCount'] as int? ?? 0,
        warnings: warnings,
      );
    } catch (_) {
      return MergeResult.failure(
          'Network error -- check your connection and try again.');
    }
  }

  /// Resolve theme_id → full name (e.g. 246 → "Star Wars > UCS"). Public
  /// (not just fetchSet's own internal helper) so importFromRebrickable can
  /// resolve theme_id -> name for bulk-imported sets too -- see
  /// CollectionProvider.importFromRebrickable's own comment for why that
  /// matters.
  Future<String?> resolveTheme(int themeId) async {
    // Check DB cache first
    final cached = await Storage.instance.getCachedTheme(themeId);
    if (cached != null) return cached;

    // Fetch from Rebrickable
    final d = await _get(
      Uri.parse('https://rebrickable.com/api/v3/lego/themes/$themeId/'),
      headers: {'Authorization': 'key ${K.rbKey}'},
    );
    if (d == null) return null;

    String name = d['name'] as String? ?? '';
    final parentId = d['parent_id'] as int?;

    // Recurse to get parent (e.g. "Star Wars" for subtheme "UCS")
    if (parentId != null && parentId != themeId) {
      final parentName = await resolveTheme(parentId);
      if (parentName != null && parentName != name) {
        name = '$parentName > $name';
      }
    }

    if (name.isNotEmpty) {
      await Storage.instance.cacheTheme(themeId, name);
    }
    return name.isNotEmpty ? name : null;
  }

  /// Paginated user collection import
  Future<List<Map<String, dynamic>>> fetchUserCollection(String token) async {
    final results = <Map<String, dynamic>>[];
    int page = 1;
    while (true) {
      final d = await _get(
        Uri.parse(
          'https://rebrickable.com/api/v3/users/$token/sets/'
          '?page=$page&page_size=100',
        ),
        headers: {'Authorization': 'key ${K.rbKey}'},
      );
      if (d == null) break;
      final items = d['results'] as List? ?? [];
      for (final item in items) {
        final setData = (item['set'] ?? item) as Map<String, dynamic>;
        setData['_qty'] = item['quantity'] ?? 1;
        results.add(setData);
      }
      if (d['next'] == null) break;
      page++;
    }
    return results;
  }

  // ── BrickSet retail (direct call — no proxy needed) ───────────────────────

  Future<double?> fetchRetail(String num) async {
    final details = await fetchSetDetails(num);
    return details?.retail;
  }

  /// Retail price + retirement date in one BrickSet call. exitDate comes
  /// straight from BrickSet's own `exitDate` field -- verified against
  /// several known-retired sets to confirm it's a real past date once a set
  /// has actually retired (often just Dec 31 of the retirement year, not a
  /// precise day, but that's plenty precise for month-level tracking).
  Future<({double? retail, DateTime? exitDate})?> fetchSetDetails(String num) async {
    final clean  = num.replaceAll(RegExp(r'-\d+$'), '');
    final params = jsonEncode({'setNumber': '$clean-1', 'pageSize': 1});
    final url    = Uri.parse(
      'https://brickset.com/api/v3.asmx/getSets'
      '?apiKey=${Uri.encodeComponent(K.bsKey)}'
      '&userHash='
      '&params=${Uri.encodeComponent(params)}',
    );

    try {
      final r = await _client
          .get(url)
          .timeout(const Duration(seconds: 14));
      if (r.statusCode != 200) return null;
      final body = r.body;
      final ji   = body.indexOf('{');
      if (ji < 0) return null;
      final d    = jsonDecode(body.substring(ji)) as Map<String, dynamic>;
      if (d['status'] != 'success') return null;
      final sets = d['sets'] as List?;
      if (sets == null || sets.isEmpty) return null;
      final set0 = sets[0] as Map;

      double? retail;
      final lego = set0['LEGOCom'] as Map?;
      final us   = lego?['US'] ?? lego?['us'];
      final p    = (us as Map?)?['retailPrice'] ?? us?['RetailPrice'];
      if (p != null) retail = p.toDouble();

      DateTime? exitDate;
      final exitRaw = set0['exitDate'] as String?;
      if (exitRaw != null) exitDate = DateTime.tryParse(exitRaw);

      if (retail == null && exitDate == null) return null;
      return (retail: retail, exitDate: exitDate);
    } catch (_) {
      return null;
    }
  }

  /// Instructions links, star rating, and extra gallery images -- Set
  /// Detail only, kept separate from fetchSetDetails (used more broadly,
  /// e.g. Set Lookup) since nothing else needs any of this. One getSets
  /// call to get setID/rating/counts, then up to two more calls
  /// (getInstructions2, getAdditionalImages) run in parallel, skipped
  /// entirely when their respective count is 0. Per BrickSet's own API
  /// docs ("Note that only calls to the getSets method count against key
  /// usage"), the follow-up calls don't cost anything against the daily
  /// key limit.
  Future<BrickSetExtras?> fetchSetExtras(String setNum) async {
    final clean   = setNum.replaceAll(RegExp(r'-\d+$'), '');
    final variant = '$clean-1';
    final params  = jsonEncode({'setNumber': variant, 'pageSize': 1});
    final url = Uri.parse(
      'https://brickset.com/api/v3.asmx/getSets'
      '?apiKey=${Uri.encodeComponent(K.bsKey)}'
      '&userHash='
      '&params=${Uri.encodeComponent(params)}',
    );

    Map<String, dynamic> set0;
    try {
      final r = await _client.get(url).timeout(const Duration(seconds: 14));
      if (r.statusCode != 200) return null;
      final body = r.body;
      final ji   = body.indexOf('{');
      if (ji < 0) return null;
      final d = jsonDecode(body.substring(ji)) as Map<String, dynamic>;
      if (d['status'] != 'success') return null;
      final sets = d['sets'] as List?;
      if (sets == null || sets.isEmpty) return null;
      set0 = (sets[0] as Map).cast<String, dynamic>();
    } catch (_) {
      return null;
    }

    final setId               = set0['setID'];
    final rating              = (set0['rating'] as num?)?.toDouble();
    final ratingCount         = (set0['ratingCount'] as num?)?.toInt() ?? 0;
    final reviewCount         = (set0['reviewCount'] as num?)?.toInt() ?? 0;
    final bricksetUrl         = set0['bricksetURL'] as String?;
    final instructionsCount   = (set0['instructionsCount'] as num?)?.toInt() ?? 0;
    final additionalImgCount  = (set0['additionalImageCount'] as num?)?.toInt() ?? 0;

    List<BrickSetInstruction> instructions = const [];
    List<String> images = const [];
    final futures = <Future>[];

    if (instructionsCount > 0) {
      futures.add(
        _fetchInstructions(variant).then((v) => instructions = v),
      );
    }
    if (additionalImgCount > 0 && setId != null) {
      futures.add(
        _fetchAdditionalImages(setId).then((v) => images = v),
      );
    }
    if (futures.isNotEmpty) await Future.wait(futures);

    return BrickSetExtras(
      rating: (rating != null && rating > 0 && ratingCount > 0) ? rating : null,
      ratingCount: ratingCount,
      reviewCount: reviewCount,
      bricksetUrl: bricksetUrl,
      instructions: instructions,
      additionalImages: images,
    );
  }

  Future<List<BrickSetInstruction>> _fetchInstructions(String setNumber) async {
    final url = Uri.parse(
      'https://brickset.com/api/v3.asmx/getInstructions2'
      '?apiKey=${Uri.encodeComponent(K.bsKey)}'
      '&setNumber=${Uri.encodeComponent(setNumber)}',
    );
    try {
      final r = await _client.get(url).timeout(const Duration(seconds: 14));
      if (r.statusCode != 200) return const [];
      final body = r.body;
      final ji   = body.indexOf('{');
      if (ji < 0) return const [];
      final d = jsonDecode(body.substring(ji)) as Map<String, dynamic>;
      if (d['status'] != 'success') return const [];
      final list = d['instructions'] as List? ?? const [];
      return list
          .map((e) {
            final m = e as Map;
            final u = (m['URL'] ?? m['url']) as String?;
            if (u == null || u.isEmpty) return null;
            return BrickSetInstruction(
              url: u,
              description: (m['description'] as String?) ?? '',
            );
          })
          .whereType<BrickSetInstruction>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<String>> _fetchAdditionalImages(dynamic setId) async {
    final url = Uri.parse(
      'https://brickset.com/api/v3.asmx/getAdditionalImages'
      '?apiKey=${Uri.encodeComponent(K.bsKey)}'
      '&setID=$setId',
    );
    try {
      final r = await _client.get(url).timeout(const Duration(seconds: 14));
      if (r.statusCode != 200) return const [];
      final body = r.body;
      final ji   = body.indexOf('{');
      if (ji < 0) return const [];
      final d = jsonDecode(body.substring(ji)) as Map<String, dynamic>;
      if (d['status'] != 'success') return const [];
      final list = d['additionalImages'] as List? ?? const [];
      return list
          .map((e) {
            final m = e as Map;
            return (m['imageURL'] ?? m['thumbnailURL']) as String?;
          })
          .whereType<String>()
          .where((u) => u.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  // ── eBay via Cloudflare Worker + D1 cache ─────────────────────────────────
  // The Worker holds the RapidAPI key server-side.
  // All users share one cached result per set/condition per 7 days.
  // Worker endpoint: POST /ebay  { num, condition, name? }
  // Response: { source, avg, median, min, max, count, fetched_at, age_hours }

  Future<Map<String, dynamic>?> fetchEbay(
    String num,
    String name, {
    required bool sealed,
    // Skips the Worker's shared 7-day D1 cache, guaranteeing a live
    // RapidAPI call (see handleEbay in cloudflare-worker/worker.js for why
    // this exists -- the cache silently ate almost every call otherwise,
    // even ones from the client's own "force" refresh). Not exposed on the
    // public refresh path -- see CollectionProvider.refreshEbay, which
    // only sets this true for dev-mode "Force refresh all" specifically,
    // to avoid a regular user's tap suddenly costing real RapidAPI calls
    // that used to be free cache hits shared across everyone.
    bool force = false,
  }) async {
    final condition = sealed ? 'sealed' : 'open';
    final endpoint  = Uri.parse('${K.workerUrl}ebay');

    try {
      final r = await _client.post(
        endpoint,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'num':       num,
          'condition': condition,
          'name':      name,
          if (force) 'force': true,
        }),
      ).timeout(const Duration(seconds: 20));

      // Worker forwards eBay error codes as-is
      if (r.statusCode == 403) throw ApiException('not_subscribed');
      if (r.statusCode == 429) throw ApiException('rate_limited');
      if (r.statusCode != 200) throw ApiException('http_${r.statusCode}');

      final d = jsonDecode(r.body) as Map<String, dynamic>;

      return {
        'avg':        (d['avg']    as dynamic?)?.toDouble(),
        'median':     (d['median'] as dynamic?)?.toDouble(),
        'min':        (d['min']    as dynamic?)?.toDouble(),
        'max':        (d['max']    as dynamic?)?.toDouble(),
        'count':      d['count']   as int? ?? 0,
        // Pass through cache metadata for debugging
        'source':     d['source']  as String? ?? 'live',
        'age_hours':  d['age_hours'] as int? ?? 0,
      };
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('network_error');
    }
  }

  // ── Check Worker cache without triggering a fetch ──────────────────────────
  // Useful for showing stale indicators in the UI without spending quota.
  Future<Map<String, dynamic>?> checkEbayCache(String num, String condition) async {
    try {
      final r = await _client.get(
        Uri.parse('${K.workerUrl}ebay?num=$num&condition=$condition'),
      ).timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) return null;
      return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

class ApiException implements Exception {
  final String code;
  const ApiException(this.code);
  @override String toString() => 'ApiException($code)';
}
