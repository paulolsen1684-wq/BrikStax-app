// lib/modules/avatar/services/daily_five_service.dart
// Tracks completion of the Daily 5 tasks. Resets at local midnight (keyed on
// yyyy-mm-dd). "Check-in" mirrors the loot daily claim; the rest are tracked
// here. Completing all five can grant a small bonus (a free roll).
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'loot_service.dart';
import '../../../services/local_notification_service.dart';

// Persisted "done" state is keyed by .name now (see _save/_decodeTask
// below), not position, so reordering or inserting values here is safe --
// it wasn't always: portfolio replaced the old polish task (trophy polish
// is no longer a feature) back when this was index-persisted, which is
// exactly the footgun the name-based format exists to remove. Renaming an
// *existing* value is still not quite free -- see _decodeTask.
enum DailyTask { checkin, portfolio, tip, trivia, spotlight }

class DailyFiveService {
  DailyFiveService._();
  static final instance = DailyFiveService._();

  Database? _db;
  String _today = '';
  final Set<DailyTask> _done = {};
  bool _bonusClaimed = false;
  // True once a reminder has actually been needed today (i.e.
  // LocalNotificationService found tasks incomplete at least once) --
  // finishing after this is true earns a +10 Brik top-up on the normal
  // bonus roll, see claimBonus(). Deliberately NOT set just because the
  // user opted into reminders; only real "you weren't done yet" moments
  // count, so it can't be gamed by toggling the setting on and off.
  bool _reminderNeeded = false;

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'brikstax_daily5.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE daily5 (
            id    INTEGER PRIMARY KEY DEFAULT 1,
            day   TEXT NOT NULL,
            done  TEXT NOT NULL,
            bonus INTEGER NOT NULL,
            reminder_needed INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              'ALTER TABLE daily5 ADD COLUMN reminder_needed INTEGER NOT NULL DEFAULT 0');
        }
      },
    );
  }

  Future<Database> get _database async {
    _db ??= await _open();
    return _db!;
  }

  static String _dayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, "0")}-${n.day.toString().padLeft(2, "0")}';
  }

  Future<void> init() async {
    _today = _dayKey();
    try {
      final db   = await _database;
      final rows = await db.query('daily5', where: 'id = 1');
      if (rows.isNotEmpty) {
        final storedDay = rows.first['day'] as String;
        if (storedDay == _today) {
          final list = jsonDecode(rows.first['done'] as String) as List;
          _done.addAll(list.map(_decodeTask).whereType<DailyTask>());
          _bonusClaimed = (rows.first['bonus'] as int) == 1;
          // Column didn't exist before schema v2 -- a row saved by an
          // older app version simply won't have it yet on the one day
          // this migration runs, defaulting to false (same as ALTER
          // TABLE's own DEFAULT 0 for existing rows).
          _reminderNeeded = (rows.first['reminder_needed'] as int? ?? 0) == 1;
        } else {
          // new day — reset
          await _resetForToday();
        }
      } else {
        await _resetForToday();
      }
    } catch (_) {}
  }

  Future<void> _resetForToday() async {
    _today = _dayKey();
    _done.clear();
    _bonusClaimed = false;
    _reminderNeeded = false;
    await _save();
  }

  Future<void> _save() async {
    try {
      final db = await _database;
      await db.insert('daily5', {
        'id': 1,
        'day': _today,
        'done': jsonEncode(_done.map((e) => e.name).toList()),
        'bonus': _bonusClaimed ? 1 : 0,
        'reminder_needed': _reminderNeeded ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {}
  }

  // Reads either the current name-keyed format ('portfolio') or, for a
  // same-day save written before this format changed, the old index-keyed
  // format (1) -- so an app update mid-day doesn't silently drop today's
  // already-checked-off tasks (the day-based reset in init() already
  // discards anything older than today, so this only ever needs to bridge
  // one transition day, never a real migration). _save always writes names
  // now. Unrecognized entries (a name from a since-removed task) decode to
  // null and are dropped rather than throwing.
  DailyTask? _decodeTask(dynamic e) {
    if (e is String) {
      try { return DailyTask.values.byName(e); } catch (_) { return null; }
    }
    if (e is int && e >= 0 && e < DailyTask.values.length) {
      return DailyTask.values[e];
    }
    return null;
  }

  /// Call before reading state to ensure a midnight rollover is applied.
  Future<void> ensureToday() async {
    if (_dayKey() != _today) await _resetForToday();
  }

  bool isDone(DailyTask t) {
    // Check-in mirrors the loot claim: it's "done" when today's brick is claimed.
    if (t == DailyTask.checkin) {
      return !LootService.instance.streak.canClaim;
    }
    return _done.contains(t);
  }

  Future<void> markDone(DailyTask t) async {
    if (t == DailyTask.checkin) return; // managed by loot claim
    await ensureToday();
    _done.add(t);
    await _save();
    // Re-checks completion and cancels today's reminder the moment the
    // last task is done, rather than leaving a stale "not done yet"
    // notification scheduled from earlier in the session. No-ops if the
    // user never opted into reminders.
    await LocalNotificationService.instance.syncDailyFiveReminder();
  }

  int get completedCount =>
      DailyTask.values.where(isDone).length;

  bool get allComplete => completedCount >= DailyTask.values.length;

  bool get bonusAvailable => allComplete && !_bonusClaimed;

  /// Called by LocalNotificationService.syncDailyFiveReminder(), but only
  /// on days its own 60%-of-incomplete-days roll actually decides to show
  /// a reminder -- records that a real prompt is happening today, so
  /// claimBonus() below knows to pay the extra follow-through bonus. Not
  /// called on days that roll "skip," so the bonus stays tied to an actual
  /// prompt rather than just "was incomplete at some point." Idempotent
  /// (only writes once per day) since sync can run many times (app
  /// launch, every markDone, the daily claim).
  Future<void> markReminderNeeded() async {
    await ensureToday();
    if (_reminderNeeded) return;
    _reminderNeeded = true;
    await _save();
  }

  /// Claim the all-five bonus — a free guaranteed-ish roll, plus a +10 Brik
  /// top-up if a reminder was actually needed today (see
  /// markReminderNeeded) -- finishing up after being nudged earns more
  /// than finishing without ever needing one. Returns the roll result or
  /// null if not available.
  Future<ClaimResult?> claimBonus() async {
    await ensureToday();
    if (!bonusAvailable) return null;
    _bonusClaimed = true;
    await _save();
    // A little reward: a free roll for showing up fully.
    final result = await LootService.instance.grantBonusRoll();
    if (result == null || !_reminderNeeded) return result;

    await LootService.instance.addBriks(10);
    return ClaimResult(
      roll: result.roll,
      briksEarned: result.briksEarned + 10,
      wasDupe: result.wasDupe,
    );
  }
}
