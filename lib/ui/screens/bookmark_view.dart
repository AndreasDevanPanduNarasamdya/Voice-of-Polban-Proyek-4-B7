import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../storage/cached_post.dart';
import '../../storage/cached_user.dart';
import '../../storage/local_bookmark.dart';
import '../../processing/feed_controller.dart';
import '../../processing/auth_controller.dart';
import '../../processing/sync_worker.dart';
import 'post_view.dart';

class BookmarkPage extends StatefulWidget {
  const BookmarkPage({super.key});

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage> {
  final FeedController _controller = FeedController();
  final AuthController _authController = AuthController();
  final SyncWorker _syncWorker = SyncWorker();

  @override
  void initState() {
    super.initState();
    _controller.syncBookmarks();
  }

  Widget _buildAvatar(String avatarUrl, double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[700],
      backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
      child: avatarUrl.isEmpty
          ? Icon(Icons.person, color: Colors.white70, size: radius)
          : null,
    );
  }

  String _getAuthorName(String authorId) {
    final user = Hive.box<CachedUser>('cached_user_box').get(authorId);
    return user?.name ?? "Penulis Tidak Diketahui";
  }

  String _getAuthorAvatar(String authorId) {
    final user = Hive.box<CachedUser>('cached_user_box').get(authorId);
    return user?.avatarUrl ?? '';
  }

  int _readUpvoteCount(Map<String, dynamic> parsed) {
    final raw = parsed['upvote_count'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw) ?? 0;
    return 0;
  }

  bool _readBoolFlag(Map<String, dynamic> parsed, String key) {
    final raw = parsed[key];
    if (raw is bool) return raw;
    if (raw is String) return raw.toLowerCase() == 'true';
    return false;
  }

  Future<void> _handleVote({
    required String postId,
    required bool isUpvoteTarget,
  }) async {
    try {
      await _controller.castVote(
        postId: postId,
        isUpvoteTarget: isUpvoteTarget,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFF8C00)),
        title: const Text(
          'Tersimpan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _buildAvatar(
              _authController.currentUser?.avatarUrl ?? '',
              16,
            ),
          ),
        ],
      ),
      // Listen to both bookmark box AND cached post box so UI updates reactively
      body: ValueListenableBuilder<Box<LocalBookmark>>(
        valueListenable: Hive.box<LocalBookmark>(
          'local_bookmark_box',
        ).listenable(),
        builder: (context, bookmarkBox, _) {
          final posts = _controller.getOfflineBookmarks();

          if (posts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, color: Colors.white24, size: 56),
                  SizedBox(height: 12),
                  Text(
                    'Belum ada artikel tersimpan',
                    style: TextStyle(color: Colors.white38, fontSize: 15),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFFFF8C00),
            onRefresh: () async {
              await _controller.syncBookmarks();
              setState(() {});
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: posts.length,
              itemBuilder: (context, index) =>
                  _buildArticleCard(context, posts[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, CachedPost post) {
    final parsed = jsonDecode(post.cachedData) as Map<String, dynamic>;
    final title = parsed['title'] ?? '';
    final authorId = parsed['author_id']?.toString() ?? '';
    final dateString = DateFormat('EEEE, dd MMMM yyyy').format(post.cachedAt);
    final imageUrls = parsed['imageUrls'] as List<dynamic>? ?? [];
    final authorName = _getAuthorName(authorId);
    final authorAvatar = _getAuthorAvatar(authorId);

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ArticlePage(articleId: post.postId),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        color: const Color(0xFF121212),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  _buildAvatar(authorAvatar, 12),
                  const SizedBox(width: 8),
                  Text(
                    authorName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateString,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (imageUrls.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15.0),
                constraints: const BoxConstraints(maxHeight: 500),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                clipBehavior: Clip.hardEdge,
                child: Image.network(
                  imageUrls.first.toString(),
                  fit: BoxFit.fitWidth,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey,
                      size: 50,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [_buildInteractionPillGroup(post.postId)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionPillGroup(String postId) {
    return ValueListenableBuilder<Box<CachedPost>>(
      valueListenable: Hive.box<CachedPost>(
        'cached_post_box',
      ).listenable(keys: [postId]),
      builder: (context, postBox, _) {
        final livePost = postBox.get(postId);
        final parsed = livePost == null
            ? <String, dynamic>{}
            : Map<String, dynamic>.from(jsonDecode(livePost.cachedData) as Map);

        final upvoteCount = _readUpvoteCount(parsed);
        final isUpvotedByMe = _readBoolFlag(parsed, 'is_upvoted_by_me');
        final isDownvotedByMe = _readBoolFlag(parsed, 'is_downvoted_by_me');
        final userId = _authController.currentUser?.userId;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onPressed: () =>
                    _handleVote(postId: postId, isUpvoteTarget: true),
                icon: Icon(
                  isUpvotedByMe ? Icons.arrow_circle_up : Icons.arrow_upward,
                  color: isUpvotedByMe ? const Color(0xFFFF8C00) : Colors.grey,
                  size: 18,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$upvoteCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onPressed: () =>
                    _handleVote(postId: postId, isUpvoteTarget: false),
                icon: Icon(
                  isDownvotedByMe
                      ? Icons.arrow_circle_down
                      : Icons.arrow_downward,
                  color: isDownvotedByMe
                      ? const Color(0xFF2E5BFF)
                      : Colors.grey,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<Box<LocalBookmark>>(
                valueListenable: Hive.box<LocalBookmark>(
                  'local_bookmark_box',
                ).listenable(),
                builder: (context, bookmarkBox, _) {
                  final isBookmarked =
                      userId != null &&
                      bookmarkBox.values.any(
                        (b) => b.userId == userId && b.postId == postId,
                      );
                  return IconButton(
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _controller.toggleBookmark(postId),
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked
                          ? const Color(0xFFFF8C00)
                          : Colors.grey,
                      size: 16,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
