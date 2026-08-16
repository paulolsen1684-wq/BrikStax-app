// lib/services/local_notification_service.dart
//
// On-device scheduled notifications -- separate from push_service.dart's
// Firebase Cloud Messaging stack. FCM is for the server reaching a device
// it can't otherwise wake up (broadcasts, future targeted sends); this is
// for reminding a user about THEIR OWN local state, which the server has
// no visibility into at all (collection contents, Daily Five completion --
// all local SQLite, never synced). Scheduling/canceling happens entirely
// on-device, no network round-trip, no server involvement.
//
// First user: the Daily Five reminder (syncDailyFiveReminder). Designed to
// be reused for future "remind me about my own stuff" notifications (price
// alerts, retirement warnings) the same way -- see the class doc below.
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../modules/avatar/services/daily_five_service.dart';

class LocalNotificationService extends ChangeNotifier {
  LocalNotificationService._();
  static final instance = LocalNotificationService._();

  static const String _kOptedInKey = 'daily_reminder_opted_in';
  // Today's show/hide + exact-minute roll, persisted so repeated sync
  // calls throughout the day (app launch, every markDone, the daily claim)
  // reuse the SAME decision instead of re-rolling each time -- otherwise
  // the reminder could jitter to a new random minute, or flip between
  // showing/not-showing, on every single sync call.
  static const String _kRollDayKey = 'daily_reminder_roll_day';
  static const String _kRollShowKey = 'daily_reminder_roll_show';
  static const String _kRollMinuteKey = 'daily_reminder_roll_minute';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _optedIn = false;
  bool get optedIn => _optedIn;

  // Fixed notification id -- there's only ever one Daily Five reminder
  // pending at a time, so re-scheduling under the same id naturally
  // replaces whatever was there rather than stacking duplicates.
  static const int _dailyFiveReminderId = 1001;
  // Per user request: don't fire every single day it's needed (that reads
  // as naggy), and don't fire at the same predictable minute every time
  // either -- 60% of incomplete days get a reminder, landing anywhere in a
  // 4pm-8pm window, both re-rolled fresh once per day.
  static const double _showProbability = 0.6;
  static const int _windowStartHour = 16; // 4pm
  static const int _windowEndHour   = 20; // 8pm

  static String _dayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, "0")}-${n.day.toString().padLeft(2, "0")}';
  }

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Falls back to whatever the timezone package defaults to (UTC) if
      // the device's IANA name can't be resolved -- reminders still fire,
      // just not guaranteed to land at the intended local hour. Better
      // than failing to schedule anything at all.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    // requestAlertPermission/etc. true here means iOS prompts for
    // notification permission during initialize() itself -- the standard
    // iOS pattern, no separate platform-specific call needed the way
    // Android requires below.
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit));
    _initialized = true;
  }

  /// Android 13+ requires this explicit runtime request (unlike iOS, which
  /// prompts during initialize() above) -- call from wherever the app
  /// already has a natural "turn on reminders" moment (e.g. alongside the
  /// FCM opt-in in Settings), not blindly at startup.
  Future<bool> requestPermission() async {
    if (!_initialized) await init();
    final androidGranted = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    final iosGranted = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return androidGranted ?? iosGranted ?? true;
  }

  /// Call once at startup (after DailyFiveService.init()) to restore a
  /// previous opt-in choice without re-prompting for permission.
  Future<void> restoreOptedIn() async {
    final prefs = await SharedPreferences.getInstance();
    _optedIn = prefs.getBool(_kOptedInKey) ?? false;
    if (_optedIn) await syncDailyFiveReminder();
    notifyListeners();
  }

  /// Flips the Settings toggle. Turning on requests the OS permission (a
  /// no-op prompt on iOS since that already happened during init(); a real
  /// prompt on Android 13+) and immediately syncs; turning off cancels
  /// whatever's pending and clears the opt-in.
  Future<void> setOptedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await requestPermission();
      _optedIn = true;
      await syncDailyFiveReminder();
    } else {
      _optedIn = false;
      if (_initialized) await _plugin.cancel(_dailyFiveReminderId);
    }
    await prefs.setBool(_kOptedInKey, _optedIn);
    notifyListeners();
  }

  /// Checks DailyFiveService's actual completion state right now and
  /// schedules or cancels today's reminder to match. No-ops entirely if
  /// the user hasn't opted in. Idempotent otherwise -- safe to call
  /// repeatedly (app launch, after markDone, after the daily claim); each
  /// call just replaces whatever was previously scheduled under the same
  /// fixed id.
  Future<void> syncDailyFiveReminder() async {
    if (!_optedIn) return;
    if (!_initialized) await init();
    final daily5 = DailyFiveService.instance;
    await daily5.ensureToday();

    if (daily5.allComplete) {
      await _plugin.cancel(_dailyFiveReminderId);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final todayKey = _dayKey();
    bool willShow;
    int minuteOfDay; // minutes since midnight, within the 4pm-8pm window

    if (prefs.getString(_kRollDayKey) == todayKey) {
      // Already rolled today -- reuse it.
      willShow = prefs.getBool(_kRollShowKey) ?? false;
      minuteOfDay = prefs.getInt(_kRollMinuteKey) ?? (_windowStartHour * 60);
    } else {
      // First sync of a new day -- roll fresh and persist it so every
      // later sync call today sees the same result.
      final rand = Random();
      willShow = rand.nextDouble() < _showProbability;
      minuteOfDay = _windowStartHour * 60 +
          rand.nextInt((_windowEndHour - _windowStartHour) * 60);
      await prefs.setString(_kRollDayKey, todayKey);
      await prefs.setBool(_kRollShowKey, willShow);
      await prefs.setInt(_kRollMinuteKey, minuteOfDay);
    }

    if (!willShow) {
      // Today rolled "skip" -- no reminder, and correspondingly no +10
      // follow-through bonus either (see markReminderNeeded below): that
      // bonus is specifically for finishing after an actual prompt, so a
      // day that never prompts shouldn't grant it.
      await _plugin.cancel(_dailyFiveReminderId);
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    final today = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, minuteOfDay ~/ 60, minuteOfDay % 60);
    if (today.isBefore(now)) {
      // Already past today's rolled time -- don't fire one for a time
      // that's already gone. Tomorrow's app-open re-syncs fresh via
      // ensureToday()'s own day-rollover, no need to pre-schedule ahead.
      // Deliberately checked BEFORE markReminderNeeded() below: this path
      // means no notification will ever actually show today, so the +10
      // follow-through bonus must not become claimable either -- it used
      // to be marked needed unconditionally first, so a late app-open
      // after the rolled window had already passed could grant the bonus
      // for a nudge the user never actually saw.
      await _plugin.cancel(_dailyFiveReminderId);
      return;
    }

    // Records that a nudge was genuinely needed AND will actually show
    // today -- DailyFiveService.claimBonus() reads this to decide whether
    // finishing later earns the +10 Brik follow-through bonus on top of
    // the normal reward.
    await daily5.markReminderNeeded();

    final remaining = 5 - daily5.completedCount;
    await _plugin.zonedSchedule(
      _dailyFiveReminderId,
      'Finish today\'s Daily Five, get extra Bricks 🧱',
      '$remaining task${remaining == 1 ? '' : 's'} left today -- finish them all for '
          '+10 bonus Bricks on top of your usual reward.',
      today,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_five',
          'Daily Five reminder',
          channelDescription: 'Reminds you if today\'s Daily Five tasks aren\'t done yet.',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      // Required by this package version -- absoluteTime means `today`
      // (already a concrete TZDateTime, not a time-of-day to reinterpret
      // relative to "now") is used exactly as given.
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
