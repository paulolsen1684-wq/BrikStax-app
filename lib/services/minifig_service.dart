// lib/services/minifig_service.dart
// Manages the user's minifig collection: persistence (sqflite, own DB file --
// see _open) and value checks against the Worker's BrickEconomy-backed
// endpoint. WishlistService-shaped, not CollectionProvider-shaped: this is
// an additive, opt-in, secondary collection (like the wishlist), not the
// primary always-present Sets inventory Storage/CollectionProvider own.
//
// No item-count cap (unlike WishlistService.freeTierCap) -- owning many
// minifigs costs the app nothing (Rebrickable catalog lookups are free,
// embedded-key). Only the VALUE fetch is scarce, and that's throttled
// server-side (see cloudflare-worker/worker.js's handleMinifigValue), not
// via a client-side item-count cap.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/minifig.dart';
import 'api.dart';

class MinifigService extends ChangeNotifier {
  MinifigService._();
  static final MinifigService instance = MinifigService._();

  Database? _db;
  final List<Minifig> _items = [];

  List<Minifig> get items => List.unmodifiable(_items);
  int get count => _items.length;

  // ── Storage ────────────────────────────────────────────────────────────────

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'brikstax_minifigs.db');
    return openDatabase(path, version: 1, onCreate: (db, _) async {
      await db.execute('''
        CREATE TABLE minifigs (
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
      final rows = await db.query('minifigs', orderBy: 'added DESC');
      _items.clear();
      for (final r in rows) {
        try {
          _items.add(Minifig.fromJson(
              jsonDecode(r['data'] as String) as Map<String, dynamic>));
        } catch (_) {}
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persist(Minifig item) async {
    try {
      final db = await _database;
      await db.insert('minifigs', {
        'id': item.id,
        'data': jsonEncode(item.toJson()),
        'added': item.addedAt.millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {}
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────

  Future<void> add(Minifig item) async {
    if (_items.any((m) => m.figNum == item.figNum)) return; // already there
    _items.insert(0, item);
    await _persist(item);
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _items.removeWhere((m) => m.id == id);
    try {
      final db = await _database;
      await db.delete('minifigs', where: 'id = ?', whereArgs: [id]);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> update(Minifig item) async {
    final i = _items.indexWhere((m) => m.id == item.id);
    if (i < 0) return;
    _items[i] = item;
    await _persist(item);
    notifyListeners();
  }

  bool contains(String figNum) => _items.any((m) => m.figNum == figNum);

  // ── Value check ──────────────────────────────────────────────────────────

  /// Explicit-action-only value fetch -- see the file header and api.dart's
  /// fetchMinifigValue doc comment for why this must never be called from
  /// init(), a loop, or any kind of "refresh all." Callers should check
  /// FeatureFlagService.instance.minifigValuesEnabled before ever showing a
  /// button that reaches this. Any ApiException (rate_limited, network_error,
  /// etc.) propagates to the caller to surface -- this method does not
  /// swallow it, unlike most of this file's storage helpers.
  Future<void> refreshValue(Minifig item) async {
    final d = await Api.instance.fetchMinifigValue(item.figNum);
    if (d == null) return;
    final updated = item.copyWith(
      valueUsd: (d['value_usd'] as num?)?.toDouble(),
      valueFetchedAt: DateTime.now(),
      valueZeroResult: d['zero_result'] == true,
    );
    await update(updated);
  }
}
