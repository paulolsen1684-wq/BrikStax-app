// lib/providers/collection.dart
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/lego_set.dart';
import '../modules/avatar/services/achievement_service.dart';
import '../modules/avatar/services/loot_service.dart';
import '../services/api.dart';
import '../services/storage.dart';
import '../modules/avatar/services/dev_mode.dart';
import '../modules/avatar/services/secret_item_service.dart';
import '../services/widget_service.dart';
import '../services/verified.dart';

enum RefreshState { idle, running, done }

class CollectionProvider extends ChangeNotifier {
  final _storage = Storage.instance;
  final _api     = Api.instance;
  final _uuid    = const Uuid();

  // ── State ──────────────────────────────────────────────────────────────────
  List<LegoSet> _sets       = [];
  bool          _loading    = true;
  String?       _error;
  int           _quotaLeft  = 3;
  RefreshState  _ebayState  = RefreshState.idle;
  String        _ebayStatus = '';

  List<LegoSet>  get sets       => _sets;
  bool           get loading    => _loading;
  String?        get error      => _error;
  int            get quotaLeft  => _quotaLeft;
  RefreshState   get ebayState  => _ebayState;
  String         get ebayStatus => _ebayStatus;

  // ── Aggregates ─────────────────────────────────────────────────────────────
  int    get count          => _sets.length;
  int    get sealedCount    => _sets.where((s) => s.status == 'sealed').length;
  int    get legoStoreCount => _sets.where((s) => s.purchaseSource.earnsInsiderPoints).length;
  double get totalPaid      => _sets.fold(0, (a, s) => a + (s.paid ?? 0));
  double get totalEffective => _sets.fold(0, (a, s) => a + (s.effectivePaid ?? s.paid ?? 0));
  double get totalRetail    => _sets.fold(0, (a, s) => a + (s.retail ?? 0));
  double get totalMarket    => _sets.fold(0, (a, s) => a + (s.ebayAvg ?? 0));
  double get totalInsider   => _sets.fold(0, (a, s) => a + (s.insiderPoints ?? 0));
  double? get portfolioRoi {
    if (totalEffective == 0 || totalMarket == 0) return null;
    return (totalMarket - totalEffective) / totalEffective * 100;
  }
  List<LegoSet> get topGainers {
    final priced = _sets.where((s) => s.roi != null).toList();
    priced.sort((a, b) => (b.roi!).compareTo(a.roi!));
    return priced.take(5).toList();
  }
  /// Sets currently in their ~18-24 month post-retirement price-climb
  /// window, soonest-to-age-out-of-the-window first.
  List<LegoSet> get inRetirementWindow {
    final sets = _sets.where((s) => s.inRetirementWindow).toList();
    sets.sort((a, b) => (b.monthsSinceRetirement!).compareTo(a.monthsSinceRetirement!));
    return sets;
  }
  Map<String, int> get byTheme {
    final map = <String, int>{};
    for (final s in _sets) {
      final t = s.theme?.split(' > ').first ?? 'Unknown';
      map[t] = (map[t] ?? 0) + 1;
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(entries);
  }

  void _syncWidget() {
    WidgetService.instance.updateWidget(
      setCount: count,
      portfolioValue: totalMarket,
    );
  }

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> init() async {
    _loading = true;
    notifyListeners();
    try {
      _sets      = await _storage.loadAll();
      _quotaLeft = await _storage.quotaRemaining();
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────
  Future<LegoSet> addSet({
    required String  num,
    String           name            = '',
    String           status          = 'sealed',
    int              qty             = 1,
    double?          retail,
    double?          paid,
    String           notes           = '',
    int?             pieces,
    int?             year,
    String?          imageUrl,
    String?          theme,
    String?          subtheme,
    bool             retired         = false,
    DateTime?        exitDate,
    OpenExtras       openExtras      = const OpenExtras(),
    PurchaseSource   purchaseSource  = PurchaseSource.other,
    double?          insiderPointsOverride,
    // Null (the default) defers to manualEntryDefaultVerified -- true while
    // kScannerLive is false (every entry trusted), false once it's on
    // (manual entries need a human to vouch for them). Pass true explicitly
    // for a set that actually came off a real barcode scan (see
    // scanner.dart's AddSetScreen(fromScan: true) hop) so it's verified
    // regardless of how manual entries are being treated.
    bool?            verified,
    }) async {
      if (await DevMode.instance.handleMagicId(num)) {
        return LegoSet(id: 'devmode', num: num, name: 'dev', addedAt: DateTime.now());
      }
      final secretName = await SecretItemService.instance.handleCode(num);
      if (secretName != null) {
        // id: 'secret' is a marker add_set.dart checks for to show a
        // confirmation toast -- same early-return-before-touching-the-
        // collection pattern as the DevMode branch above.
        return LegoSet(id: 'secret', num: num, name: secretName, addedAt: DateTime.now());
      }
      final set = LegoSet(      id:                   _uuid.v4(),
      num:                  num.replaceAll(RegExp(r'-\d+$'), ''),
      name:                 name,
      status:               status,
      qty:                  qty,
      retail:               retail,
      paid:                 paid,
      notes:                notes,
      pieces:               pieces,
      year:                 year,
      imageUrl:             imageUrl,
      theme:                theme,
      subtheme:             subtheme,
      retired:              retired,
      exitDate:             exitDate,
      openExtras:           openExtras,
      purchaseSource:       purchaseSource,
      insiderPointsOverride:insiderPointsOverride,
      verified:             verified ?? manualEntryDefaultVerified,
      addedAt:              DateTime.now(),
    );
    _sets.insert(0, set);
    await _storage.save(set);
    notifyListeners();
    _syncWidget();
    AchievementService.instance.check(this);
    LootService.instance.checkBundles(this);
    return set;
  }

  Future<void> update(LegoSet updated) async {
    final i = _sets.indexWhere((s) => s.id == updated.id);
    if (i < 0) return;
    _sets[i] = updated;
    await _storage.save(updated);
    notifyListeners();
    _syncWidget();
  }

  Future<void> remove(String id) async {
    _sets.removeWhere((s) => s.id == id);
    await _storage.delete(id);
    notifyListeners();
    _syncWidget();
  }

  // ── Rebrickable lookup ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> lookupSet(String num) =>
      _api.fetchSet(num);

  // ── Fill missing images ────────────────────────────────────────────────────
  Future<int> fillImages({void Function(int done, int total)? onProgress}) async {
    final missing = _sets.where((s) => s.imageUrl == null).toList();
    int ok = 0;
    for (int i = 0; i < missing.length; i++) {
      onProgress?.call(i, missing.length);
      final d = await _api.fetchSet(missing[i].num);
      if (d != null) {
        final idx = _sets.indexWhere((s) => s.id == missing[i].id);
        if (idx >= 0) {
          _sets[idx] = _sets[idx].copyWith(
            imageUrl: d['set_img_url'] as String?,
            pieces:   _sets[idx].pieces ?? d['num_parts'] as int?,
            year:     _sets[idx].year   ?? d['year'] as int?,
            theme:    _sets[idx].theme  ?? d['theme_name'] as String?,
          );
          await _storage.save(_sets[idx]);
          ok++;
        }
      }
      if (i < missing.length - 1) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
    onProgress?.call(missing.length, missing.length);
    notifyListeners();
    return ok;
  }

  // ── Fill missing retail (and retirement date, same BrickSet call) ─────────
  Future<int> fillRetail({void Function(int done, int total)? onProgress}) async {
    final missing = _sets
        .where((s) => s.retail == null || (s.retired && s.exitDate == null))
        .toList();
    int ok = 0;
    for (int i = 0; i < missing.length; i++) {
      onProgress?.call(i, missing.length);
      final details = await _api.fetchSetDetails(missing[i].num);
      if (details != null && (details.retail != null || details.exitDate != null)) {
        final idx = _sets.indexWhere((s) => s.id == missing[i].id);
        if (idx >= 0) {
          _sets[idx] = _sets[idx].copyWith(
            retail: details.retail,
            exitDate: details.exitDate,
          );
          await _storage.save(_sets[idx]);
          ok++;
        }
      }
      if (i < missing.length - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    onProgress?.call(missing.length, missing.length);
    notifyListeners();
    return ok;
  }

  // ── eBay refresh ───────────────────────────────────────────────────────────
  Future<void> refreshEbay({
    bool forceAll = false,
    void Function(String error)? onError,
  }) async {
    if (_quotaLeft <= 0) {
      onError?.call('Weekly eBay quota reached. Resets in 7 days.');
      return;
    }
    _ebayState  = RefreshState.running;
    _ebayStatus = '';
    notifyListeners();

    // Only fetch stale sets unless forced
    final targets = forceAll
        ? _sets
        : _sets.where((s) => s.ebayIsStale).toList();

    // Bypass the Worker's shared D1 cache only for dev-mode "Force refresh
    // all" -- see Api.fetchEbay's doc comment. A regular user's "Force
    // refresh all" still only ignores *local* staleness, exactly as
    // before; it doesn't start spending extra RapidAPI calls that used to
    // be free cache hits.
    final forceLive = forceAll && DevMode.instance.isOn;

    int ok = 0, fail403 = 0;

    for (int i = 0; i < targets.length; i++) {
      final s = targets[i];
      _ebayStatus = '${s.name.isEmpty ? s.num : s.name} (${i+1}/${targets.length})';
      notifyListeners();

      Map<String, dynamic>? sealedData;
      Map<String, dynamic>? openData;

      try {
        sealedData = await _api.fetchEbay(s.num, s.name, sealed: true, force: forceLive);
        // If data came from cache, no need for delay before open fetch
        final fromCache = sealedData?['source'] == 'cache';
        if (!fromCache) await Future.delayed(const Duration(milliseconds: 1200));
      } on ApiException catch (e) {
        if (e.code == 'not_subscribed') { fail403++; }
      }

      if (fail403 >= 2) {
        onError?.call(
          'eBay API: Not subscribed.\n\n'
          'Go to your Cloudflare Worker → Settings → Variables\n'
          'and confirm EBAY_KEY is set correctly.',
        );
        break;
      }

      try {
        openData = await _api.fetchEbay(s.num, s.name, sealed: false, force: forceLive);
      } on ApiException catch (_) {}

      if (sealedData != null || openData != null) {
        final now = DateTime.now();
        final idx = _sets.indexWhere((x) => x.id == s.id);
        if (idx < 0) continue;

        final newPhS = sealedData != null
            ? [
                ..._sets[idx].phSealed,
                PricePoint(
                  date:   now,
                  avg:    sealedData['avg'],
                  median: sealedData['median'],
                  min:    sealedData['min'],
                  max:    sealedData['max'],
                  count:  sealedData['count'] ?? 0,
                ),
              ]
            : _sets[idx].phSealed;

        final newPhO = openData != null
            ? [
                ..._sets[idx].phOpen,
                PricePoint(
                  date:   now,
                  avg:    openData['avg'],
                  median: openData['median'],
                  min:    openData['min'],
                  max:    openData['max'],
                  count:  openData['count'] ?? 0,
                ),
              ]
            : _sets[idx].phOpen;

        // Distinguish "checked, found a real price" from "checked, found
        // nothing" from "never checked" — see LegoSet.sealedZeroResults /
        // openZeroResults. A successful fetch with a real avg always clears
        // the zero-results flag; a successful fetch with count==0 sets it.
        final sealedFoundNow = sealedData != null && sealedData['avg'] != null;
        final openFoundNow   = openData   != null && openData['avg']   != null;

        _sets[idx] = _sets[idx].copyWith(
          ebaySealed:    sealedData?['avg'] ?? _sets[idx].ebaySealed,
          ebayOpen:      openData?['avg']   ?? _sets[idx].ebayOpen,
          ebayFetchedAt: now,
          phSealed: newPhS.length > 52 ? newPhS.sublist(newPhS.length - 52) : newPhS,
          phOpen:   newPhO.length > 52 ? newPhO.sublist(newPhO.length - 52) : newPhO,
          sealedZeroResults: sealedFoundNow
              ? false
              : (sealedData != null && (sealedData['count'] ?? 0) == 0)
                  ? true
                  : _sets[idx].sealedZeroResults,
          openZeroResults: openFoundNow
              ? false
              : (openData != null && (openData['count'] ?? 0) == 0)
                  ? true
                  : _sets[idx].openZeroResults,
        );
        await _storage.save(_sets[idx]);
        ok++;
      }

      if (i < targets.length - 1) {
        await Future.delayed(const Duration(milliseconds: 2000));
      }
    }

    if (ok > 0) {
      await _storage.recordQuotaCall();
      _quotaLeft = await _storage.quotaRemaining();
    }

    _ebayState  = RefreshState.done;
    _ebayStatus = ok > 0 ? 'Updated $ok set${ok != 1 ? "s" : ""}' : 'Nothing to update';
    notifyListeners();

    await Future.delayed(const Duration(seconds: 3));
    _ebayState = RefreshState.idle;
    notifyListeners();
    _syncWidget();
  }

  // ── Import from Rebrickable ────────────────────────────────────────────────
  Future<int> importFromRebrickable(String token) async {
    final items = await _api.fetchUserCollection(token);
    int imported = 0;
    for (final item in items) {
      final num = (item['set_num'] as String? ?? '')
          .replaceAll(RegExp(r'-\d+$'), '');
      if (num.isEmpty) continue;
      if (_sets.any((s) => s.num == num)) continue;
      final set = LegoSet(
        id:       _uuid.v4(),
        num:      num,
        name:     item['name'] as String? ?? '',
        pieces:   item['num_parts'] as int?,
        year:     item['year'] as int?,
        imageUrl: item['set_img_url'] as String?,
        qty:      item['_qty'] as int? ?? 1,
        addedAt:  DateTime.now(),
      );
      _sets.insert(0, set);
      await _storage.save(set);
      imported++;
    }
    notifyListeners();
    _syncWidget();
    return imported;
  }

  // ── Import / export JSON ───────────────────────────────────────────────────
  Future<int> importJson(List<dynamic> data) async {
    int imported = 0;
    for (final item in data) {
      try {
        final s = LegoSet.fromJson(item as Map<String, dynamic>);
        final idx = _sets.indexWhere((x) => x.num == s.num);
        if (idx >= 0) {
          _sets[idx] = s;
        } else {
          _sets.insert(0, s);
        }
        await _storage.save(s);
        imported++;
      } catch (_) {}
    }
    notifyListeners();
    _syncWidget();
    return imported;
  }

  List<Map<String, dynamic>> exportJson() =>
      _sets.map((s) => s.toJson()).toList();
}
