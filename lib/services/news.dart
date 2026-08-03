// lib/services/news.dart — BrikStax news feed service
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';

class NewsItem {
  final int    id;
  final String title;
  final String? summary;
  final String? url;
  final String? imageUrl;
  final DateTime postedAt;
  final String source;

  const NewsItem({
    required this.id,
    required this.title,
    this.summary,
    this.url,
    this.imageUrl,
    required this.postedAt,
    this.source = 'discord',
  });

  factory NewsItem.fromJson(Map<String, dynamic> j) => NewsItem(
    id:       j['id'] as int,
    title:    j['title'] as String,
    summary:  j['summary'] as String?,
    url:      j['url'] as String?,
    imageUrl: j['image_url'] as String?,
    postedAt: DateTime.fromMillisecondsSinceEpoch(
        (j['posted_at'] as int?) ?? 0),
    source:   j['source'] as String? ?? 'discord',
  );

  String get timeAgo {
    final diff = DateTime.now().difference(postedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    if (diff.inDays    < 7)  return '${diff.inDays}d ago';
    return '${postedAt.month}/${postedAt.day}';
  }
}

class NewsService {
  NewsService._();
  static final instance = NewsService._();

  List<NewsItem> _items = [];
  DateTime?      _lastFetch;
  bool           _loading = false;

  List<NewsItem> get items => List.unmodifiable(_items);
  bool get loading => _loading;

  Future<List<NewsItem>> fetch({bool force = false}) async {
    // Cache for 15 minutes
    if (!force && _lastFetch != null &&
        DateTime.now().difference(_lastFetch!).inMinutes < 15) {
      return _items;
    }

    _loading = true;
    try {
      final r = await http.get(
        Uri.parse('${K.workerUrl}news?limit=20'),
      ).timeout(const Duration(seconds: 10));

      if (r.statusCode == 200) {
        final data  = jsonDecode(r.body) as Map<String, dynamic>;
        final items = (data['items'] as List? ?? [])
            .map((e) => NewsItem.fromJson(e as Map<String, dynamic>))
            .toList();
        _items     = items;
        _lastFetch = DateTime.now();
      }
    } catch (_) {}

    _loading = false;
    return _items;
  }
}
