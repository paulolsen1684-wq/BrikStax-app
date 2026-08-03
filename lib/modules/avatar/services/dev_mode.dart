// lib/modules/avatar/services/dev_mode.dart
// Hidden developer toggle. Adding a set with the magic number flips dev mode:
//   ON  → unlocks every cosmetic, every theme, and the barcode scanner
//   OFF → wipes back to defaults
// The magic set is never persisted to the collection (handled in addSet).
//
// SHIP-SAFE: '041793' is not a valid real LEGO set number, so it won't collide
// with anything testers enter, and it ships harmlessly in release — just a
// string compare. Persists via sqflite (no extra package needed).
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../data/sprite_cosmetics.dart' as sprite;
import '../data/pixel_cosmetics.dart';
import '../models/avatar_state.dart';
import 'achievement_service.dart';

class DevMode {
  DevMode._();
  static final instance = DevMode._();

  static const String magicId = '041793';

  Database? _db;
  bool _on = false;
  bool get isOn => _on;

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'brikstax_devmode.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE devmode (
            id INTEGER PRIMARY KEY DEFAULT 1,
            on_flag INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<Database> get _database async {
    _db ??= await _open();
    return _db!;
  }

  Future<void> init() async {
    try {
      final db   = await _database;
      final rows = await db.query('devmode', where: 'id = 1');
      if (rows.isNotEmpty) {
        _on = (rows.first['on_flag'] as int) == 1;
      }
    } catch (_) {
      _on = false;
    }
  }

  Future<void> _save() async {
    try {
      final db = await _database;
      await db.insert('devmode', {'id': 1, 'on_flag': _on ? 1 : 0},
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {}
  }

  String _norm(String s) {
    final t = s.trim();
    final stripped = t.replaceFirst(RegExp(r'^0+'), '');
    return stripped.isEmpty ? '0' : stripped;
  }

  bool _isMagic(String setNum) => _norm(setNum) == _norm(magicId);

  Future<bool> handleMagicId(String setNum) async {
    if (!_isMagic(setNum)) return false;
    await toggle();
    return true;
  }

  /// Flip dev mode. ON unlocks every cosmetic in the catalog; OFF resets
  /// to defaults.
  Future<void> toggle() async {
    _on = !_on;
    await _save();
    final svc = AchievementService.instance;
    if (_on) {
      // Every pixel item is already unlocked by default (only 20 exist,
      // see AvatarState.defaults), so the only thing this actually adds
      // right now is the full background catalog -- still unions both
      // rather than assuming that, so it stays correct once pixel items
      // stop being unlocked-by-default and once more get added.
      final allIds = sprite.allSpriteCosmetics.map((c) => c.id).toSet()
        ..addAll(allPixelCosmetics.map((c) => c.id));
      await svc.updateState(svc.state.copyWith(unlockedIds: allIds));
    } else {
      // AvatarState.defaults.unlockedIds is the source of truth for
      // starter ids.
      await svc.updateState(
          svc.state.copyWith(unlockedIds: AvatarState.defaults.unlockedIds));
    }
  }

  String get statusMessage => _on
      ? '🔓 Dev mode ON — cosmetics, themes & scanner unlocked'
      : '🔒 Dev mode OFF — reset to defaults';
}
