// lib/modules/community/services/community_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/community_post.dart';
import '../../avatar/services/dev_mode.dart';

class CommunityService extends ChangeNotifier {
  CommunityService._();
  static final instance = CommunityService._();

  static const String _baseUrl =
      'https://brikstax-worker.paul-olsen1684.workers.dev';

  static const String _kLastSubmitKey = 'community_last_submit_at';
  static const Duration submitCooldown = Duration(hours: 6);

  List<CommunityPost> _feed   = [];
  bool                 _loading = false;
  String?              _error;

  List<CommunityPost> get feed    => _feed;
  bool                 get loading => _loading;
  String?              get error   => _error;

  /// Fetch the public feed — approved posts only. [userId] is optional but
  /// should always be passed by real call sites (DeviceIdentity.instance.id)
  /// so each post comes back knowing whether THIS device already liked it —
  /// omitting it just means every post renders with an outline (unliked)
  /// heart regardless of actual state.
  Future<void> fetchFeed({int limit = 20, String? userId}) async {
    _loading = true;
    _error   = null;
    notifyListeners();

    try {
      final uri = Uri.parse('$_baseUrl/community/feed?limit=$limit'
          '${userId != null ? '&user_id=${Uri.encodeComponent(userId)}' : ''}');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        throw Exception('Feed error ${res.statusCode}');
      }
      final data  = jsonDecode(res.body) as Map<String, dynamic>;
      final posts = (data['posts'] as List<dynamic>? ?? [])
          .map((p) => CommunityPost.fromJson(p as Map<String, dynamic>))
          .toList();
      _feed = posts;
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  /// Toggle a like on [postId] for [userId]. Updates the matching post in
  /// [_feed] in place (optimistic-ish -- waits for the real response rather
  /// than guessing the new count, but doesn't require a full fetchFeed()
  /// round-trip to reflect the change). Silently no-ops on failure, same
  /// "never let a background network hiccup surface as an error state"
  /// philosophy as the rest of this service.
  Future<void> toggleLike(int postId, String userId) async {
    try {
      final uri = Uri.parse('$_baseUrl/community/like');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'post_id': postId, 'user_id': userId}),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final liked = data['liked'] as bool? ?? false;
      final count = data['likeCount'] as int? ?? 0;

      final idx = _feed.indexWhere((p) => p.id == postId);
      if (idx >= 0) {
        _feed[idx] = _feed[idx].copyWithLike(liked: liked, likeCount: count);
        notifyListeners();
      }
    } catch (_) {
      // Network hiccup — the heart just doesn't update this time; the next
      // fetchFeed() will resync to the real server state either way.
    }
  }

  /// Pulls any Brik rewards accrued from likes on this user's own posts
  /// since the last claim and returns how many were earned (0 if none).
  /// Callers are responsible for actually crediting the local Briks wallet
  /// (LootService.instance.addBriks) -- this service only talks to the
  /// Worker, it doesn't know about LootService, same layering as everywhere
  /// else Briks get granted from outside the avatar module.
  Future<int> claimRewards(String userId) async {
    try {
      final uri = Uri.parse('$_baseUrl/community/claim-rewards');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return 0;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['briksEarned'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<Duration> cooldownRemaining() async {
    if (DevMode.instance.isOn) return Duration.zero;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastMs = prefs.getInt(_kLastSubmitKey);
      if (lastMs == null) return Duration.zero;

      final last    = DateTime.fromMillisecondsSinceEpoch(lastMs);
      final elapsed = DateTime.now().difference(last);
      final remaining = submitCooldown - elapsed;
      return remaining.isNegative ? Duration.zero : remaining;
    } catch (_) {
      return Duration.zero;
    }
  }

  Future<void> _recordSubmitTime() async {
    if (DevMode.instance.isOn) return; // don't burn the cooldown in dev mode
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastSubmitKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Guesses the image MIME type from the file extension. http's
  /// MultipartFile.fromPath does NOT set this automatically — without it,
  /// the Worker sees no content-type and rejects the upload as "not an image".
  MediaType _mimeTypeFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png'))  return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    if (lower.endsWith('.heic')) return MediaType('image', 'heic');
    if (lower.endsWith('.heif')) return MediaType('image', 'heif');
    // Default to jpeg — covers .jpg/.jpeg and is a safe fallback for
    // anything image_picker hands back without a recognized extension.
    return MediaType('image', 'jpeg');
  }

  /// Submit a photo for review. Returns a [SubmitResult] describing the
  /// outcome — success, rate-limited (with remaining time), or a plain error.
  Future<SubmitResult> submitPost({
    required String userId,
    required File   image,
    String? caption,
    String? setNum,
  }) async {
    final remaining = await cooldownRemaining();
    if (remaining > Duration.zero) {
      return SubmitResult.rateLimited(remaining);
    }

    try {
      final uri = Uri.parse('$_baseUrl/community/submit');
      final request = http.MultipartRequest('POST', uri)
        ..fields['user_id'] = userId
        ..files.add(await http.MultipartFile.fromPath(
          'image',
          image.path,
          contentType: _mimeTypeFor(image.path),
        ));

      if (caption != null && caption.trim().isNotEmpty) {
        request.fields['caption'] = caption.trim();
      }
      if (setNum != null && setNum.trim().isNotEmpty) {
        request.fields['set_num'] = setNum.trim();
      }
      if (DevMode.instance.isOn) {
        request.fields['dev_mode'] = '1';
      }

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode == 429) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final retryAfterSec = data['retry_after_seconds'] as int? ?? 0;
        return SubmitResult.rateLimited(Duration(seconds: retryAfterSec));
      }

      if (res.statusCode != 200) {
        throw Exception('Submit failed: ${res.statusCode} ${res.body}');
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      await _recordSubmitTime();
      return SubmitResult.success(data['id'] as int);

    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return SubmitResult.failure(e.toString());
    }
  }
}

class SubmitResult {
  final bool     ok;
  final bool     rateLimited;
  final int?     postId;
  final Duration? cooldownRemaining;
  final String?  errorMessage;

  const SubmitResult._({
    required this.ok,
    required this.rateLimited,
    this.postId,
    this.cooldownRemaining,
    this.errorMessage,
  });

  factory SubmitResult.success(int id) =>
      SubmitResult._(ok: true, rateLimited: false, postId: id);

  factory SubmitResult.rateLimited(Duration remaining) => SubmitResult._(
      ok: false, rateLimited: true, cooldownRemaining: remaining);

  factory SubmitResult.failure(String message) => SubmitResult._(
      ok: false, rateLimited: false, errorMessage: message);
}