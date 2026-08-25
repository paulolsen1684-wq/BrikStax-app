// lib/services/whats_new_service.dart
//
// Reusable "What's New" quest system -- server-driven, not a Dart list.
// All entries for the currently-running app version are fetched once at
// launch from brikstax-worker's GET /whats-new?version=X, matching
// FeatureFlagService's own init()-time fetch/fail-safe shape exactly (see
// that file's doc comment). Publishing/editing a quest is a POST to that
// same endpoint -- tools/quest_builder.html (offline) and the live
// cloudflare-site/quest-admin.html are the authoring UIs for it, no app
// rebuild or store submission needed either way.
//
// Fails safe like every other remote-driven thing in this app: offline,
// timeout, a non-200, or malformed JSON all just leave the entry list
// empty (no quest shown) rather than falling back to stale or partial
// content.
//
// Multiple entries per version, each with its own stable [id], each shown
// once -- NOT one entry per version. Changed 2026-08-23: the original
// design used [version] itself as the unique key, meaning at most one
// announcement could ever exist per release and "seen" was tracked per
// version. Real feedback: there's no good reason a release can't have
// several distinct announcements, each shown on its own the first time a
// device sees it. Every piece of per-quest state (seen, task progress,
// bonus claimed) is now keyed by the quest's own [id], not the app
// version -- the version is just which quests get fetched at all.
//
// Shape: a checklist of small, real actions -- entry.tasks is a plain
// list, any number, nothing here assumes a fixed count -- each paying a
// little Briks the instant it's completed, plus one cosmetic bonus once
// every task is done. main.dart's launch check shows the oldest not-yet-
// seen entry's intro popup, one per launch (not all of them stacked at
// once) -- further unseen entries show on later launches. A quest still
// in progress after its intro's been seen is surfaced by
// widgets/whats_new_banner.dart instead of re-showing a blocking popup
// every launch.
//
// IMPORTANT for a NEW kind of task: a task's [id] (set by whoever authors
// the quest) is just a label for persistence/display -- actually
// detecting when one is done still needs one real completeTask(id) call
// wired into whatever screen/action that task describes. Same shape as
// AchievementService's condition switch or HiddenThemeService's tier
// checks -- server-driven content controls wording/reward amounts/how
// many tasks, not which real actions the app knows how to detect. A task
// whose id has no matching completeTask() call anywhere just never
// completes, same as a stale hook pointing at a task id that no longer
// exists (both are harmless no-ops, not errors).
//
// A plain ChangeNotifier singleton, initialized in main.dart's startup
// sequence alongside the other avatar-module singletons -- matches
// AchievementService/LootService's own shape so widgets/whats_new_banner.dart
// can listen the same way dashboard.dart's _AvatarSection already listens
// to AchievementService.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modules/avatar/services/achievement_service.dart';
import '../modules/avatar/services/loot_service.dart';

class WhatsNewTask {
  final String id;
  final String label;
  final int briksReward;
  const WhatsNewTask({required this.id, required this.label, this.briksReward = 5});

  factory WhatsNewTask.fromJson(Map<String, dynamic> j) => WhatsNewTask(
    id: j['id'] as String,
    label: j['label'] as String,
    briksReward: (j['briksReward'] as num?)?.toInt() ?? 5,
  );
}

class WhatsNewEntry {
  final String id; // stable, unique per announcement -- the real persistence key
  final String version; // which app version this was published for
  final String questTitle;
  final List<WhatsNewTask> tasks;
  // A cosmetic id from either catalog (background_cosmetics.dart or
  // pixel_cosmetics.dart), granted via LootService's dupe-safe
  // unlockOrDupePayout the moment every task above is complete.
  final String rewardCosmeticId;
  const WhatsNewEntry({
    required this.id,
    required this.version,
    required this.questTitle,
    required this.tasks,
    required this.rewardCosmeticId,
  });

  factory WhatsNewEntry.fromJson(Map<String, dynamic> j) => WhatsNewEntry(
    id: j['id'] as String,
    version: j['version'] as String,
    questTitle: j['questTitle'] as String,
    tasks: (j['tasks'] as List)
        .map((t) => WhatsNewTask.fromJson(t as Map<String, dynamic>))
        .toList(),
    rewardCosmeticId: j['rewardCosmeticId'] as String,
  );
}

/// What actually happened from a completeTask() call -- lets the caller
/// decide what (if anything) to show without duplicating the "already
/// done" / "quest just finished" logic at every call site.
class WhatsNewTaskResult {
  final int taskBriks;
  final bool questCompleted;
  final String? bonusCosmeticId;
  final bool bonusWasDupe;
  final int bonusBriks;
  const WhatsNewTaskResult({
    this.taskBriks = 0,
    this.questCompleted = false,
    this.bonusCosmeticId,
    this.bonusWasDupe = false,
    this.bonusBriks = 0,
  });
  static const none = WhatsNewTaskResult();
  bool get didAnything => taskBriks > 0;
}

class WhatsNewService extends ChangeNotifier {
  WhatsNewService._();
  static final instance = WhatsNewService._();

  static const String _baseUrl =
      'https://brikstax-worker.paul-olsen1684.workers.dev';

  static const _introSeenKey    = 'whats_new_intro_seen';    // entry ids
  static const _doneTasksKey    = 'whats_new_done_tasks';    // "entryId:taskId"
  static const _bonusClaimedKey = 'whats_new_bonus_claimed'; // entry ids

  String _version = '';
  List<WhatsNewEntry> _entries = [];
  Set<String> _introSeen = {};
  Set<String> _doneTasks = {};
  Set<String> _bonusClaimed = {};

  /// Call once at app startup, before runApp(). Fetches every quest
  /// published for the currently-running version from the Worker -- fails
  /// safe (leaves the entry list empty, same as "no quests for this
  /// version") on any network error, non-200, or malformed response,
  /// exactly like FeatureFlagService.init() does for its own flags.
  Future<void> init() async {
    _version = (await PackageInfo.fromPlatform()).version;

    try {
      final uri = Uri.parse('$_baseUrl/whats-new?version=$_version');
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = data['entries'] as List?;
        if (list != null) {
          _entries = list
              .map((e) => WhatsNewEntry.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {
      // Offline, timeout, malformed response -- stay empty. A flaky launch
      // should just show no quest, never a half-loaded or stale one.
    }

    final prefs = await SharedPreferences.getInstance();
    _introSeen    = (prefs.getStringList(_introSeenKey) ?? const []).toSet();
    _doneTasks    = (prefs.getStringList(_doneTasksKey) ?? const []).toSet();
    _bonusClaimed = (prefs.getStringList(_bonusClaimedKey) ?? const []).toSet();
  }

  /// Every quest fetched for the current version that hasn't been fully
  /// completed yet (bonus not yet claimed) -- oldest first, same order the
  /// Worker returns them in.
  List<WhatsNewEntry> get inProgressEntries =>
      _entries.where((e) => !_bonusClaimed.contains(e.id)).toList();

  /// The single quest widgets/whats_new_banner.dart shows/links to -- the
  /// oldest one still in progress, or null if everything fetched has
  /// already been completed (or nothing was fetched at all).
  WhatsNewEntry? get activeEntry {
    final list = inProgressEntries;
    return list.isEmpty ? null : list.first;
  }

  /// The oldest fetched entry whose intro popup this device hasn't shown
  /// yet -- main.dart's launch check shows this one, once. A device seeing
  /// multiple never-shown entries gets them one per launch, not all
  /// stacked in the same session.
  WhatsNewEntry? get nextUnseenEntry {
    for (final e in _entries) {
      if (!_introSeen.contains(e.id)) return e;
    }
    return null;
  }

  Future<void> markIntroSeen(String entryId) async {
    if (!_introSeen.add(entryId)) return; // already recorded
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_introSeenKey, _introSeen.toList());
  }

  /// Task ids already completed for [entryId] -- the raw set stores every
  /// quest's ids together ("entryId:taskId") so separate quests' progress
  /// never collides.
  Set<String> doneTaskIds(String entryId) => _doneTasks
      .where((k) => k.startsWith('$entryId:'))
      .map((k) => k.substring(entryId.length + 1))
      .toSet();

  /// Marks [taskId] complete on whichever in-progress entry actually
  /// defines it (searched oldest-first) if it isn't already done, pays
  /// that task's Briks, and -- if this was the last remaining task on that
  /// entry -- grants its bonus cosmetic too. Safe to call repeatedly: a
  /// task or bonus already recorded is never paid out twice, and it's a
  /// no-op entirely if no in-progress entry defines a task with this id
  /// (e.g. a hook left behind from a quest that's no longer published, or
  /// already fully claimed).
  Future<WhatsNewTaskResult> completeTask(String taskId) async {
    WhatsNewEntry? entry;
    WhatsNewTask? task;
    for (final e in inProgressEntries) {
      for (final t in e.tasks) {
        if (t.id == taskId) { entry = e; task = t; break; }
      }
      if (task != null) break;
    }
    if (entry == null || task == null) return WhatsNewTaskResult.none;

    final doneKey = '${entry.id}:$taskId';
    if (_doneTasks.contains(doneKey)) return WhatsNewTaskResult.none;

    _doneTasks.add(doneKey);
    await _persist(_doneTasksKey, _doneTasks);
    await LootService.instance.addBriks(task.briksReward);

    final done = doneTaskIds(entry.id);
    final allDone = entry.tasks.every((t) => done.contains(t.id));
    if (!allDone) {
      notifyListeners();
      return WhatsNewTaskResult(taskBriks: task.briksReward);
    }

    // Every task on this entry done -- grant its bonus cosmetic (or pay
    // Briks if it's somehow already owned), same dupe-safe path every
    // other reward grant in this app uses.
    final svc   = AchievementService.instance;
    final state = svc.state;
    final wasDupe = state.unlockedIds.contains(entry.rewardCosmeticId);
    final newUnlocked = Set<String>.from(state.unlockedIds);
    final dupePayout = LootService.instance
        .unlockOrDupePayout(entry.rewardCosmeticId, newUnlocked);
    if (!wasDupe) {
      await svc.updateState(state.copyWith(unlockedIds: newUnlocked));
    } else if (dupePayout > 0) {
      await LootService.instance.addBriks(dupePayout);
    }
    _bonusClaimed.add(entry.id);
    await _persist(_bonusClaimedKey, _bonusClaimed);
    notifyListeners();

    return WhatsNewTaskResult(
      taskBriks: task.briksReward,
      questCompleted: true,
      bonusCosmeticId: entry.rewardCosmeticId,
      bonusWasDupe: wasDupe,
      bonusBriks: wasDupe ? dupePayout : 0,
    );
  }

  Future<void> _persist(String key, Set<String> values) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, values.toList());
  }
}
