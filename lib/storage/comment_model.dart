class CommentModel {
  const CommentModel({
    required this.commentId,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.authorName,
  });

  final String commentId;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String authorName;

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['created_at'];
    final usersData = json['users'];

    String authorName = '';
    if (usersData is Map<String, dynamic>) {
      authorName = usersData['name']?.toString() ?? '';
    } else if (usersData is List && usersData.isNotEmpty) {
      final firstUser = usersData.first;
      if (firstUser is Map<String, dynamic>) {
        authorName = firstUser['name']?.toString() ?? '';
      }
    }

    authorName = authorName.isNotEmpty
        ? authorName
        : json['authorName']?.toString() ??
              json['author_name']?.toString() ??
              '';

    return CommentModel(
      commentId: json['comment_id']?.toString() ?? '',
      postId: json['post_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: createdAtRaw is DateTime
          ? createdAtRaw
          : DateTime.tryParse(createdAtRaw?.toString() ?? '') ?? DateTime.now(),
      authorName: authorName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'comment_id': commentId,
      'post_id': postId,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'authorName': authorName,
    };
  }
}
