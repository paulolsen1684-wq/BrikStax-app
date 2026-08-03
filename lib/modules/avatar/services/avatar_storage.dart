// lib/modules/avatar/services/avatar_storage.dart
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/avatar_state.dart';
import '../data/pixel_cosmetics.dart';

class AvatarStorage {
  AvatarStorage._();
  static final instance = AvatarStorage._();

  Database? _db;

  Future<Database> get _database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'brikstax_avatar.db');
    return openDatabase(path, version: 1, onCreate: (db, _) async {
      await db.execute('''
        CREATE TABLE avatar_state (
          id      INTEGER PRIMARY KEY DEFAULT 1,
          data    TEXT NOT NULL
        )
      ''');
    });
  }

  Future<AvatarState> load() async {
    try {
      final db  = await _database.timeout(const Duration(seconds: 3));
      final rows = await db.query('avatar_state', where: 'id = 1').timeout(const Duration(seconds: 3));
      if (rows.isEmpty) return AvatarState.defaults;
      final data = jsonDecode(rows.first['data'] as String);
      return _sanitize(AvatarState.fromJson(data as Map<String, dynamic>));
    } catch (_) {
      return AvatarState.defaults;
    }
  }

  // Guards against a save pointing at an id the current catalog doesn't
  // know about -- either the pre-cutover sprite catalog (retired) or a
  // pixel item that's since been removed -- which would otherwise render
  // as a blank layer. head/torso/legs force back to the default id (these
  // must never render blank); hat/item drop to unequipped instead, since
  // an empty hat or item slot is a valid, normal look.
  AvatarState _sanitize(AvatarState state) {
    final defaults = AvatarState.defaults;
    final unlocked = Set<String>.from(state.unlockedIds);

    String? fix(String? id, String defaultId) {
      if (id != null && pixelCosmeticsById.containsKey(id)) return id;
      unlocked.add(defaultId);
      return defaultId;
    }

    final headId  = fix(state.headId, defaults.headId!);
    final torsoId = fix(state.torsoId, defaults.torsoId!);
    final legsId  = fix(state.legsId, defaults.legsId!);
    final hatId  = (state.hatId  != null && pixelCosmeticsById.containsKey(state.hatId))  ? state.hatId  : null;
    final itemId = (state.itemId != null && pixelCosmeticsById.containsKey(state.itemId)) ? state.itemId : null;

    return state.copyWith(
      headId: headId,
      torsoId: torsoId,
      legsId: legsId,
      hatId: hatId,
      clearHat: hatId == null,
      itemId: itemId,
      clearItem: itemId == null,
      unlockedIds: unlocked,
    );
  }

  Future<void> save(AvatarState state) async {
    try {
      final db = await _database;
      await db.insert(
        'avatar_state',
        {'id': 1, 'data': jsonEncode(state.toJson())},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }
}
