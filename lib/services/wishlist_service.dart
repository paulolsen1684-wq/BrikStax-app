// lib/services/wishlist_service.dart
// Manages the wishlist: persistence (sqflite), the free-tier cap, price checks
// against the Worker's eBay endpoint, and alert detection. Notifications are
// handled separately (see notification_service.dart) so this works without that
// dependency — it computes which items have alerts; the UI/notifier consumes them.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import '../models/wishlist_item.dart';
import '../models/lego_set.dart' show PricePoint;

class WishlistService extends ChangeNotifier {
  WishlistService._();
  static final WishlistService instance = WishlistService._();

  // Free tier allows this many; Pro = unlimited. Tune as needed.
  static const int freeTierCap = 5;

  // Worker eBay endpoint (same base used elsewhere).
  static const String _ebayBase =
      'https://brikstax-worker.paul-olsen1684.workers.dev/ebay';

  // A drop of this fraction since last check counts as a "price drop" alert.
  static const double dropThreshold = 0.10; // 10%

  Database? _db;
  final List<WishlistItem> _items = [];
  bool _isPro = false; // wire to your entitlement check when Pro launches

  List<WishlistItem> get items => List.unmodifiable(_items);
  bool get isPro => _isPro;
  int  get count => _items.length;
  bool get atCap => !_isPro && _items.length >= freeTierCap;
  int  get remainingFreeSlots =>
      _isPro ? 9999 : (freeTierCap - _items.length).clamp(0, freeTierCap);

  void setProStatus(bool pro) { _isPro = pro; notifyListeners(); }

  // ── Storage ────────────────────────────────────────────────────────────────

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'brikstax_wishlist.db');
    return openDatabase(path, version: 1, onCreate: (db, _) async {
      await db.execute('''
        CREATE TABLE wishlist (
          id   TEXT PRIMARY KEY,
          data TEXT NOT NULL,
          added INTEGER NOT NULL
        )
      ''');
    });
  }

  Future<Database> get _database async {
    _db ??= await _open();
    return _db!;
  }

  Future<void> init() async {
    try {
      final db = await _database;
      final rows = await db.query('wishlist', orderBy: 'added DESC');
      _items.clear();
      for (final r in rows) {
        try {
          _items.add(WishlistItem.fromJson(
              jsonDecode(r['data'] as String) as Map<String, dynamic>));
        } catch (_) {}
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persist(WishlistItem item) async {
    try {
      final db = await _database;
      await db.insert('wishlist', {
        'id': item.id,
        'data': jsonEncode(item.toJson()),
        'added': item.addedAt.millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {}
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────

  /// Returns false if blocked by the free-tier cap.
  Future<bool> add(WishlistItem item) async {
    if (atCap) return false;
    if (_items.any((w) => w.num == item.num)) return true; // already there
    _items.insert(0, item);
    await _persist(item);
    notifyListeners();
    return true;
  }

  Future<void> remove(String id) async {
    _items.removeWhere((w) => w.id == id);
    try {
      final db = await _database;
      await db.delete('wishlist', where: 'id = ?', whereArgs: [id]);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> update(WishlistItem item) async {
    final i = _items.indexWhere((w) => w.id == item.id);
    if (i < 0) return;
    _items[i] = item;
    await _persist(item);
    notifyListeners();
  }

  bool contains(String num) => _items.any((w) => w.num == num);

  // ── Price checking ─────────────────────────────────────────────────────────

  /// Fetch the latest market price for one item from the Worker (sealed).
  /// Updates currentPrice, lastChecked, and appends a price-history point.
  /// Returns the alert kind triggered, if any.
  Future<WishlistAlert?> checkPrice(WishlistItem item) async {
    double? price;
    try {
      final res = await http.get(
        Uri.parse('$_ebayBase?num=${Uri.encodeComponent(item.num)}&condition=sealed'),
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        price = (data['avg'] as dynamic)?.toDouble();
      }
    } catch (_) {}

    if (price == null) return null;

    final prev = item.currentPrice;
    final history = List<PricePoint>.from(item.priceHistory)
      ..add(PricePoint(date: DateTime.now(), avg: price));

    final updated = item.copyWith(
      currentPrice: price,
      lastChecked: DateTime.now(),
      priceHistory: history,
    );
    await update(updated);

    // Determine alert
    if (updated.notifyOnTarget && updated.atOrBelowTarget) {
      return WishlistAlert(updated, WishlistAlertKind.target);
    }
    if (updated.notifyOnDrop && prev != null && prev > 0) {
      final dropFrac = (prev - price) / prev;
      if (dropFrac >= dropThreshold) {
        return WishlistAlert(updated, WishlistAlertKind.drop);
      }
    }
    return null;
  }

  /// Check every item (Pro auto-check, or manual "refresh all"). Returns alerts.
  Future<List<WishlistAlert>> checkAll() async {
    final alerts = <WishlistAlert>[];
    for (final item in List<WishlistItem>.from(_items)) {
      final a = await checkPrice(item);
      if (a != null) alerts.add(a);
    }
    return alerts;
  }

  /// Items currently at/below target (for the dashboard "near target" hook).
  List<WishlistItem> get atTarget =>
      _items.where((w) => w.atOrBelowTarget).toList();

  /// Items within a few dollars / close to target (for "almost" prompts).
  List<WishlistItem> nearTarget({double withinPct = 0.10}) {
    return _items.where((w) {
      if (w.atOrBelowTarget) return true;
      final p = w.progressToTarget;
      return p != null && p >= (1 - withinPct);
    }).toList();
  }
}

enum WishlistAlertKind { target, drop }

class WishlistAlert {
  final WishlistItem item;
  final WishlistAlertKind kind;
  const WishlistAlert(this.item, this.kind);

  String get message => switch (kind) {
    WishlistAlertKind.target =>
      '🎯 ${item.name.isNotEmpty ? item.name : item.num} hit your target price!',
    WishlistAlertKind.drop =>
      '📉 ${item.name.isNotEmpty ? item.name : item.num} just dropped in price!',
  };
}
