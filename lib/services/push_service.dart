// lib/services/push_service.dart
//
// Real push notifications (Firebase Cloud Messaging) -- deliberately NOT
// initialized from main.dart's startup sequence, unlike every other
// singleton there. Every entry point into this service (the raw dev test
// screen AND the opt-in toggle below) is only ever reachable from a
// DevMode.instance.isOn-gated widget (push_test_screen.dart,
// settings.dart's _NotificationsOptIn) -- a real (non-dev) beta user's app
// never touches Firebase code, never requests the notification permission,
// and can't be affected if something here is misconfigured. Android only
// for now -- no iOS Firebase app/APNs key exist yet, see
// google-services.json (Android-only client) and
// project_future_push_notifications.md.
//
// "all_users" is the broadcast topic for sending to everyone at once
// (FCM handles the fan-out server-side -- no need to loop the push_tokens
// table for this). push_tokens itself stays for TARGETED sends later (e.g.
// "your wishlist item hit target price," which is inherently per-user, not
// a topic). Actually sending to either isn't implemented yet -- this only
// gets a device INTO a state where Firebase Console's own "Send test
// message" tool (Cloud Messaging -> a specific token, or the Topics tab for
// "all_users") can push to it with zero server-side code. The Worker-side
// send endpoint (using a Firebase service account key, not yet provided) is
// a follow-up once this client side is confirmed working end-to-end.
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PushService extends ChangeNotifier {
  PushService._();
  static final instance = PushService._();

  static const String _baseUrl =
      'https://brikstax-worker.paul-olsen1684.workers.dev';
  static const String topicAllUsers = 'all_users';
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

  // ── Broadcast opt-in (Settings toggle, dev-gated) ──────────────────────
  // Persisted locally so the toggle reflects reality across app restarts
  // without re-prompting for permission every launch. Deliberately doesn't
  // check DevMode itself -- every caller (settings.dart's
  // _NotificationsOptIn widget) already only exists inside a
  // DevMode.instance.isOn-gated part of the tree, so gating here too would
  // just be redundant, not an extra safety net.

  /// Call when the (dev-gated) toggle first renders, before the user has
  /// necessarily touched it -- restores a previous opt-in silently (no
  /// permission re-prompt, since Android/iOS both remember a prior grant)
  /// so re-opening Settings doesn't look like it forgot the choice.
  Future<void> restoreIfOptedIn(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    _optedIn = prefs.getBool(_kOptedInKey) ?? false;
    notifyListeners();
    if (!_optedIn) return;

    final gotToken = await _requestPermissionAndGetToken();
    if (!gotToken) {
      // Permission was revoked in OS settings since the last time this was
      // on -- reflect that honestly rather than claiming to still be opted
      // in with nothing actually working underneath.
      _optedIn = false;
      await prefs.setBool(_kOptedInKey, false);
      notifyListeners();
      return;
    }
    await FirebaseMessaging.instance.subscribeToTopic(topicAllUsers);
    await registerToken(userId);
    notifyListeners();
  }

  /// Flips the toggle. Turning on: requests permission, subscribes to the
  /// broadcast topic, registers the token. Turning off: unsubscribes (best
  /// effort -- OS-level permission itself can't be revoked programmatically
  /// by the app, only the topic subscription and our own "opted in" record
  /// can be undone). Persists either way so it survives a restart.
  Future<void> setOptedIn(bool value, {required String userId}) async {
    final prefs = await SharedPreferences.getInstance();

    if (value) {
      final gotToken = await _requestPermissionAndGetToken();
      if (!gotToken) {
        // Permission denied or Firebase failed to init -- don't claim
        // opted-in when nothing underneath actually succeeded.
        _optedIn = false;
        await prefs.setBool(_kOptedInKey, false);
        notifyListeners();
        return;
      }
      await FirebaseMessaging.instance.subscribeToTopic(topicAllUsers);
      await registerToken(userId);
      _optedIn = true;
    } else {
      if (_firebaseReady) {
        try {
          await FirebaseMessaging.instance.unsubscribeFromTopic(topicAllUsers);
        } catch (_) {
          // Best effort -- not being able to unsubscribe shouldn't block
          // turning the toggle off locally.
        }
      }
      _optedIn = false;
    }

    await prefs.setBool(_kOptedInKey, _optedIn);
    notifyListeners();
  }
}
