// lib/services/api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lego_set.dart';
import 'constants.dart';
import 'storage.dart';

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

  /// Route a URL through the Cloudflare Worker proxy
  Uri _proxy(String targetUrl) => Uri.parse(
      '${K.workerUrl}?url=${Uri.encodeComponent(targetUrl)}');

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
      final name = await _resolveTheme(themeId);
      if (name != null) d['theme_name'] = name;
    }
    return d;
  }

  /// Resolve theme_id → full name (e.g. 246 → "Star Wars > UCS")
  Future<String?> _resolveTheme(int themeId) async {
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
      final parentName = await _resolveTheme(parentId);
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
      final p    = (us as Map?)?['retailPrice'] ?? (us as Map?)?['RetailPrice'];
      if (p != null) retail = (p as dynamic).toDouble();

      DateTime? exitDate;
      final exitRaw = set0['exitDate'] as String?;
      if (exitRaw != null) exitDate = DateTime.tryParse(exitRaw);

      if (retail == null && exitDate == null) return null;
      return (retail: retail, exitDate: exitDate);
    } catch (_) {
      return null;
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
