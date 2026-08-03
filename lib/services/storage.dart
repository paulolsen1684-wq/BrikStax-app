// lib/services/storage.dart
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/lego_set.dart';
import 'constants.dart';

class Storage {
  Storage._();
  static final Storage instance = Storage._();

  Database? _db;

  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), K.dbName);
    return openDatabase(
      path,
      version: 2,
      onCreate: _create,
      onUpgrade: _upgrade,
    );
  }

  Future<void> _create(Database db, int v) async {
    await db.execute('''
      CREATE TABLE sets (
        id         TEXT PRIMARY KEY,
        num        TEXT NOT NULL,
        name       TEXT,
        theme      TEXT,
        data       TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_sets_num ON sets(num)
    ''');
    await db.execute('''
      CREATE TABLE prefs (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE theme_cache (
        theme_id   INTEGER PRIMARY KEY,
        name       TEXT NOT NULL,
        cached_at  INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _upgrade(Database db, int oldV, int newV) async {
    if (oldV < 2) {
      await db.execute('CREATE TABLE IF NOT EXISTS theme_cache (theme_id INTEGER PRIMARY KEY, name TEXT NOT NULL, cached_at INTEGER NOT NULL)');
    }
  }

  // ── Sets ───────────────────────────────────────────────────────────────────

  Future<List<LegoSet>> loadAll() async {
    final d = await db;
    final rows = await d.query('sets', orderBy: 'updated_at DESC');
    return rows.map((r) => LegoSet.fromJson(
      jsonDecode(r['data'] as String) as Map<String, dynamic>,
    )).toList();
  }

  Future<void> save(LegoSet s) async {
    final d = await db;
    await d.insert('sets', {
      'id':         s.id,
      'num':        s.num,
      'name':       s.name,
      'theme':      s.theme,
      'data':       jsonEncode(s.toJson()),
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveAll(List<LegoSet> sets) async {
    final d = await db;
    final batch = d.batch();
    for (final s in sets) {
      batch.insert('sets', {
        'id':         s.id,
        'num':        s.num,
        'name':       s.name,
        'theme':      s.theme,
        'data':       jsonEncode(s.toJson()),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> delete(String id) async {
    final d = await db;
    await d.delete('sets', where: 'id = ?', whereArgs: [id]);
  }

  // ── Prefs ──────────────────────────────────────────────────────────────────

  Future<String?> getPref(String key) async {
    final d = await db;
    final rows = await d.query('prefs', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> setPref(String key, String value) async {
    final d = await db;
    await d.insert('prefs', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deletePref(String key) async {
    final d = await db;
    await d.delete('prefs', where: 'key = ?', whereArgs: [key]);
  }

  // ── Theme cache ────────────────────────────────────────────────────────────

  Future<String?> getCachedTheme(int themeId) async {
    final d = await db;
    final rows = await d.query('theme_cache',
        where: 'theme_id = ?', whereArgs: [themeId]);
    if (rows.isEmpty) return null;
    final cachedAt = rows.first['cached_at'] as int;
    final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
    if (age > K.rbThemeCacheTtlDays * 86400000) return null; // expired
    return rows.first['name'] as String?;
  }

  Future<void> cacheTheme(int themeId, String name) async {
    final d = await db;
    await d.insert('theme_cache', {
      'theme_id':  themeId,
      'name':      name,
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ── eBay quota ─────────────────────────────────────────────────────────────

  Future<List<int>> getQuotaCalls() async {
    final raw = await getPref(K.prefEbayQuota) ?? '[]';
    final List list = jsonDecode(raw) as List;
    final cutoff = DateTime.now()
        .subtract(const Duration(days: 7))
        .millisecondsSinceEpoch;
    return list
        .cast<int>()
        .where((t) => t > cutoff)
        .toList();
  }

  Future<void> recordQuotaCall() async {
    final calls = await getQuotaCalls();
    calls.add(DateTime.now().millisecondsSinceEpoch);
    await setPref(K.prefEbayQuota, jsonEncode(calls));
  }

  Future<int> quotaRemaining() async {
    // 3 refreshes per week is very conservative — adjust as needed
    const max = 3;
    final calls = await getQuotaCalls();
    return (max - calls.length).clamp(0, max);
  }
}
