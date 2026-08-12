// lib/services/part_check_service.dart
//
// Persists Parts Checker progress -- how many of each part+color you've
// pulled together for a set -- keyed by set number, surviving app restarts
// and letting you resume a check later instead of losing it when you leave
// the screen (the website version only ever had 3 localStorage save slots
// per browser; this has no slot limit and doesn't depend on staying on the
// same device/browser tab).
//
// Own tiny SQLite database rather than a new table on the shared
// services/storage.dart `sets` schema -- matches the precedent set by
// modules/avatar/services/daily_five_service.dart, which does the same for
// the same reason: this data has nothing to do with the owned-collection
// schema Storage otherwise centers on, so it shouldn't ride that class's
// version-bump migrations.
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class PartCheckService {
  PartCheckService._();
  static final PartCheckService instance = PartCheckService._();

  Database? _db;
  Future<Database> get _database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'brikstax_partcheck.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE part_check (
            set_num    TEXT NOT NULL,
            part_id    TEXT NOT NULL,
            have_qty   INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            PRIMARY KEY (set_num, part_id)
          )
        ''');
      },
    );
  }

  // Same normalization LegoSet.num uses everywhere else (strip a trailing
  // "-N" variant suffix) so progress keyed off a freeform-typed set number
  // still lines up with an owned set looked up by its stored `num`.
  String _norm(String setNum) => setNum.replaceAll(RegExp(r'-\d+$'), '');

  Future<Map<String, int>> load(String setNum) async {
    final db = await _database;
    final rows = await db.query('part_check',
        where: 'set_num = ?', whereArgs: [_norm(setNum)]);
    return {for (final r in rows) r['part_id'] as String: r['have_qty'] as int};
  }

  Future<DateTime?> lastUpdated(String setNum) async {
    final db = await _database;
    final rows = await db.rawQuery(
        'SELECT MAX(updated_at) as m FROM part_check WHERE set_num = ?',
        [_norm(setNum)]);
    final m = rows.first['m'] as int?;
    return m == null ? null : DateTime.fromMillisecondsSinceEpoch(m);
  }

  Future<void> setHave(String setNum, String partId, int qty) async {
    final db = await _database;
    await db.insert(
      'part_check',
      {
        'set_num': _norm(setNum),
        'part_id': partId,
        'have_qty': qty,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clear(String setNum) async {
    final db = await _database;
    await db.delete('part_check', where: 'set_num = ?', whereArgs: [_norm(setNum)]);
  }

  /// Every set number with at least one saved qty -- used by the dashboard
  /// entry point to know whether there's anything to resume, without
  /// loading every row for every set up front.
  Future<Set<String>> setsWithProgress() async {
    final db = await _database;
    final rows = await db.rawQuery('SELECT DISTINCT set_num FROM part_check');
    return rows.map((r) => r['set_num'] as String).toSet();
  }
}
