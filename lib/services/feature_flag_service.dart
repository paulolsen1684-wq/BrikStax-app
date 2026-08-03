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
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FeatureFlagService extends ChangeNotifier {
  FeatureFlagService._();
  static final instance = FeatureFlagService._();

  static const String _baseUrl =
      'https://brikstax-worker.paul-olsen1684.workers.dev';

  bool _communityFeedEnabled = false;
  bool _scannerEnabled       = false;
  bool _loaded               = false;

  bool get communityFeedEnabled => _communityFeedEnabled;
  bool get scannerEnabled       => _scannerEnabled;
  bool get loaded               => _loaded;

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
