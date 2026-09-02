// lib/services/feature_flag_service.dart
//
// Remote feature gating. Fetches /features from the Worker once at app
// launch and caches the result for the session. Fails safe — if the fetch
// fails for any reason (offline, Worker down, timeout), every gated feature
// defaults to OFF rather than accidentally unlocking something.
//
// To enable a feature for real users: go to Cloudflare dashboard → Worker →
// Settings → Variables, set FEATURE_COMMUNITY_FEED or FEATURE_SCANNER to
// "true", save. No app update or redeploy needed — takes effect the next
// time a user opens the app.
//
// communityBanner works the same way but isn't a bool -- it's free text
// (e.g. a moderation notice or temporary warning) read from a
// COMMUNITY_BANNER env var on the Worker. Empty/unset means "don't show
// anything," so clearing the banner is just blanking that var, same
// dashboard, no code change either direction.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FeatureFlagService extends ChangeNotifier {
  FeatureFlagService._();
  static final instance = FeatureFlagService._();

  static const String _baseUrl =
      'https://brikstax-worker.paul-olsen1684.workers.dev';

  bool   _communityFeedEnabled = false;
  bool   _scannerEnabled       = false;
  bool   _pushNotificationsEnabled = false;
  bool   _minifigValuesEnabled = false;
  String? _communityBanner;
  bool   _loaded               = false;

  bool    get communityFeedEnabled => _communityFeedEnabled;
  bool    get scannerEnabled       => _scannerEnabled;
  /// Gates PushService's silent auto-activation for real (non-dev) users --
  /// see that file's doc comment. DevMode users bypass this flag entirely.
  bool    get pushNotificationsEnabled => _pushNotificationsEnabled;
  /// Gates only MinifigService's BrickEconomy "Check current value" button --
  /// catalog browsing (Rebrickable) works regardless. Off by default until
  /// BRICKECONOMY_KEY is provisioned on the Worker and this flag is flipped
  /// on, same zero-app-update mechanism as the other flags here.
  bool    get minifigValuesEnabled => _minifigValuesEnabled;
  /// Free-text notice for the Community feed, or null when there isn't one.
  /// Already trimmed; an empty/whitespace-only value from the Worker is
  /// treated the same as unset so a stray space in the dashboard field
  /// can't make an invisible banner container show up.
  String? get communityBanner      => _communityBanner;
  bool    get loaded               => _loaded;

  /// Call once at app startup, before runApp(). Safe to call multiple times —
  /// only the first successful fetch matters for the session.
  Future<void> init() async {
    try {
      final uri = Uri.parse('$_baseUrl/features');
      final res = await http.get(uri).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _communityFeedEnabled = data['community_feed'] == true;
        _scannerEnabled       = data['scanner'] == true;
        _pushNotificationsEnabled = data['push_notifications'] == true;
        _minifigValuesEnabled = data['minifig_values'] == true;
        final banner = (data['community_banner'] as String?)?.trim();
        _communityBanner = (banner != null && banner.isNotEmpty) ? banner : null;
      }
      // Any non-200 falls through with both flags staying false (fail-safe).
    } catch (_) {
      // Network error, timeout, malformed response — stay gated. This is
      // intentional: a flaky connection at launch should never accidentally
      // unlock a feature that isn't ready for real users yet.
    }

    _loaded = true;
    notifyListeners();
  }
}
