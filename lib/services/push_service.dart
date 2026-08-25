// lib/services/push_service.dart
//
// Real push notifications (Firebase Cloud Messaging) -- deliberately NOT
// initialized from main.dart's sequential startup, unlike every other
// singleton there, since maybeAutoActivate() below already short-circuits
// before touching Firebase for anyone not gated in.
//
// 2026-08-26: replaced the old Settings toggle (_NotificationsOptIn) with a
// silent, automatic activation path -- no in-app UI at all, matching how
// camera permission works elsewhere in this app (a single OS system
// prompt, triggered once, with no separate "enable camera" toggle
// anywhere). See maybeAutoActivate()'s own doc comment for the gating
// (DevMode OR FeatureFlagService's server-controlled `push_notifications`
// flag) and main.dart's _Shell for where it's actually called. The old raw
// dev test screen (push_test_screen.dart) is untouched -- still a manual,
// DevMode-only debugging tool exercising these same pieces individually,
// unrelated to the automatic path.
//
// Android only for now -- no iOS Firebase app/APNs key exist yet, see
// google-services.json (Android-only client) and
// project_future_push_notifications.md.
//
// "all_users" is the broadcast topic for sending to everyone at once (FCM
// handles the fan-out server-side -- no need to loop the push_tokens table
// for this). push_tokens itself is for TARGETED sends (e.g. "your wishlist
// item hit target price," inherently per-user, not a topic). Sending is
// real, not a stub -- brikstax-worker's POST /push/send (a real FCM HTTP
// v1 call, OAuth2 JWT-signed with a Firebase service account key) already
// ships this to lego-rewards-watcher in production; see that Worker's
// sendBrikStaxPush() and CLAUDE.md's Push notifications section.
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../modules/avatar/services/dev_mode.dart';
import 'feature_flag_service.dart';

class PushService extends ChangeNotifier {
  PushService._();
  static final instance = PushService._();

  static const String _baseUrl =
      'https://brikstax-worker.paul-olsen1684.workers.dev';
  static const String topicAllUsers = 'all_users';

  // Dev-only side channel, subscribed to only when DevMode.instance.isOn --
  // the same gate that currently protects this whole service from ever
  // running on a real user's device. Exists specifically because
  // lego-rewards-watcher (a separate personal Cloudflare Worker, outside
  // this repo, monitoring LEGO Insiders Rewards) piggybacks on this app's
  // push infra to alert its owner -- before this topic existed it sent to
  // topicAllUsers directly, which was harmless only because push itself
  // was dev-gated (the developer's device was the sole subscriber). The
  // moment push stops being dev-gated for real users, anyone who opts in
  // would start getting those personal LEGO alerts too. Fixed 2026-08-12:
  // lego-rewards-watcher now sends here instead -- see that Worker's own
  // sendBrikStaxPush(). If push ever needs a broadcast channel that
  // genuinely should reach only non-dev real users, that's a third topic,
  // not a repurposing of either of these two.
  static const String topicDevAlerts = 'dev_alerts';

  static const String _kOptedInKey  = 'push_opted_in';

  bool _firebaseReady = false;
  String? _token;
  AuthorizationStatus? _permissionStatus;
  String? _lastError;
  bool _optedIn = false;
  final List<String> _foregroundLog = [];

  bool    get firebaseReady    => _firebaseReady;
  String? get token             => _token;
  AuthorizationStatus? get permissionStatus => _permissionStatus;
  String? get lastError         => _lastError;
  bool    get optedIn           => _optedIn;
  List<String> get foregroundLog => List.unmodifiable(_foregroundLog);

  /// Call once, from the dev screen only. Safe to call multiple times --
  /// short-circuits if Firebase is already initialized.
  Future<void> ensureInitialized() async {
    if (_firebaseReady) return;
    try {
      await Firebase.initializeApp();
      _firebaseReady = true;
      _lastError = null;

      // Foreground messages don't show a system notification automatically
      // (that's standard FCM behavior on both platforms, not a bug) -- the
      // dev screen's log is what proves a push actually arrived while
      // testing with the app open. Background/terminated-app pushes DO show
      // natively with zero extra code, so this listener is a dev-testing
      // convenience, not something a real notification flow needs.
      FirebaseMessaging.onMessage.listen((msg) {
        _foregroundLog.insert(0,
            '${DateTime.now().toIso8601String()}  ${msg.notification?.title ?? '(no title)'}: ${msg.notification?.body ?? msg.data}');
        notifyListeners();
      });

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _token = newToken;
        notifyListeners();
      });
    } catch (e) {
      _lastError = e.toString();
    }
    notifyListeners();
  }

  Future<void> requestPermissionAndToken() async {
    await _requestPermissionAndGetToken();
    notifyListeners();
  }

  /// Shared by the raw dev test screen (requestPermissionAndToken above)
  /// and the opt-in toggle (setOptedIn below) -- both need the exact same
  /// permission-request + token-fetch sequence, just with different things
  /// happening around it (the toggle also subscribes to a topic and
  /// persists the opt-in choice; the raw test screen just wants to see
  /// the values). Returns true if a real, usable token was obtained.
  Future<bool> _requestPermissionAndGetToken() async {
    if (!_firebaseReady) await ensureInitialized();
    if (!_firebaseReady) return false;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      _permissionStatus = settings.authorizationStatus;
      _token = await FirebaseMessaging.instance.getToken();
      _lastError = null;
      return _token != null &&
          (_permissionStatus == AuthorizationStatus.authorized ||
           _permissionStatus == AuthorizationStatus.provisional);
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  /// Sends the current token to the Worker for storage (push_tokens table).
  /// Nothing sends TO it yet -- this just proves the registration round-trip
  /// works, ahead of the Worker-side send endpoint.
  Future<bool> registerToken(String userId) async {
    if (_token == null) return false;
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/push/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'token': _token,
          'platform': 'android',
        }),
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Silent automatic activation (no toggle, no UI at all) ──────────────
  static const String _kAutoAttemptedKey = 'push_auto_attempted_v1';

  /// The whole feature, end to end, with no in-app UI -- call once from
  /// main.dart's _Shell.initState() on every launch; safe to call
  /// unconditionally since the gate check below returns immediately for
  /// the vast majority of users (nothing here touches Firebase, prefs, or
  /// the network until DevMode or the server flag is actually on).
  ///
  /// First time ever gated in: fires the real OS permission prompt
  /// (_requestPermissionAndGetToken -> FirebaseMessaging.requestPermission)
  /// -- exactly one system dialog, same shape as this app's camera
  /// permission, no separate app-level "enable notifications" question
  /// anywhere. That attempt is recorded (_kAutoAttemptedKey) regardless of
  /// outcome, so a real denial is respected forever after -- same as
  /// camera, changing your mind means going to the OS's own app-permission
  /// settings, not an in-app toggle.
  ///
  /// Every later launch (already attempted once): re-syncs quietly instead
  /// -- reads the OS's already-decided permission via
  /// getNotificationSettings() (never shows UI) and, if still authorized,
  /// refreshes the token/topic/registration in case the token rotated.
  /// This is what keeps a genuinely opted-in device's registration current
  /// without ever re-prompting.
  Future<void> maybeAutoActivate(String userId) async {
    final gated = DevMode.instance.isOn ||
        FeatureFlagService.instance.pushNotificationsEnabled;
    if (!gated) return;

    final prefs = await SharedPreferences.getInstance();
    final alreadyAttempted = prefs.getBool(_kAutoAttemptedKey) ?? false;

    if (!alreadyAttempted) {
      final gotToken = await _requestPermissionAndGetToken();
      await prefs.setBool(_kAutoAttemptedKey, true);
      if (!gotToken) {
        _optedIn = false;
        await prefs.setBool(_kOptedInKey, false);
        notifyListeners();
        return;
      }
      await _subscribeAndRegister(userId);
      _optedIn = true;
      await prefs.setBool(_kOptedInKey, true);
      notifyListeners();
      return;
    }

    // Already asked in a previous launch -- never call requestPermission()
    // again, just check where things actually stand and keep it in sync.
    await ensureInitialized();
    if (!_firebaseReady) return;
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    _permissionStatus = settings.authorizationStatus;
    final stillAuthorized = _permissionStatus == AuthorizationStatus.authorized ||
        _permissionStatus == AuthorizationStatus.provisional;
    if (!stillAuthorized) {
      // Revoked in OS settings since the last launch -- reflect that
      // honestly rather than claiming to still be active.
      _optedIn = false;
      await prefs.setBool(_kOptedInKey, false);
      notifyListeners();
      return;
    }
    _token = await FirebaseMessaging.instance.getToken();
    if (_token == null) return;
    await _subscribeAndRegister(userId);
    _optedIn = true;
    await prefs.setBool(_kOptedInKey, true);
    notifyListeners();
  }

  Future<void> _subscribeAndRegister(String userId) async {
    await FirebaseMessaging.instance.subscribeToTopic(topicAllUsers);
    if (DevMode.instance.isOn) {
      await FirebaseMessaging.instance.subscribeToTopic(topicDevAlerts);
    }
    await registerToken(userId);
  }
}
