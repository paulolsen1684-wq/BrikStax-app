// lib/modules/community/models/community_post.dart
class CommunityPost {
  final int      id;
  final String   userId;
  final String   imageUrl;
  final String?  caption;
  final String?  setNum;
  final int      submittedAt;

  const CommunityPost({
    required this.id,
    required this.userId,
    required this.imageUrl,
    this.caption,
    this.setNum,
    required this.submittedAt,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) => CommunityPost(
    id:          json['id'] as int,
    userId:      json['userId'] as String,
    imageUrl:    json['imageUrl'] as String,
    caption:     json['caption'] as String?,
    setNum:      json['setNum'] as String?,
    submittedAt: json['submittedAt'] as int,
  );

  DateTime get submittedAtDate =>
      DateTime.fromMillisecondsSinceEpoch(submittedAt);

  String get timeAgo {
    final diff = DateTime.now().difference(submittedAtDate);
    if (diff.inMinutes < 1)   return 'just now';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)    return '${diff.inHours}h ago';
    if (diff.inDays < 7)      return '${diff.inDays}d ago';
    return '${submittedAtDate.month}/${submittedAtDate.day}/${submittedAtDate.year}';
  }
}
