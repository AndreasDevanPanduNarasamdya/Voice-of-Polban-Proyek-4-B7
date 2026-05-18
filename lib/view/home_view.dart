import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart'; // Used for formatting real dates
import '../models/cached_post.dart';
import '../models/cached_user.dart';
import '../models/local_bookmark.dart';
import '../models/app_enums.dart';
import '../controller/post_controller.dart';
import '../auth/auth_controller.dart';
import 'package:voice_of_polban/view/sidebar.dart';
import 'article_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthController _authController = AuthController();
  final PostController _controller = PostController();
  late Future<List<CachedPost>> _onlineFeed;

  @override
  void initState() {
    super.initState();
    _onlineFeed = _controller.fetchFeed();
    _controller.processSyncQueue();
  }

  Future<void> _refreshFeed() async {
    setState(() {
      _onlineFeed = _controller.fetchFeed();
    });
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

  @override
  Widget build(BuildContext context) {
    // 1. REACTIVE SESSION: Listens to logins/logouts instantly
    return ValueListenableBuilder<Box>(
      valueListenable: Hive.box('session_box').listenable(),
      builder: (context, sessionBox, _) {
        final currentUserRole =
            _authController.currentUser?.role ?? UserRole.reader;

        return Scaffold(
          backgroundColor: Colors.black, // Dark Theme
          drawer: AppSidebar(currentUserRole: currentUserRole),
          appBar: AppBar(
            backgroundColor: const Color(0xFF121212),
            elevation: 0,
            iconTheme: const IconThemeData(color: Color(0xFFFF8C00)),
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

          // 2. REACTIVE FEED: Listens to new articles/publications instantly
          body: FutureBuilder<List<CachedPost>>(
            future: _onlineFeed,
            builder: (context, snapshot) {
              // Show a loading spinner while communicating with the database
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF8C00)),
                );
              }
              final posts = snapshot.data ?? [];

              if (posts.isEmpty) {
                return RefreshIndicator(
                  color: const Color(0xFFFF8C00),
                  backgroundColor: const Color(0xFF1E1E1E),
                  onRefresh: _refreshFeed, // Triggers network call
                  child: ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(), // Forces pull-to-refresh to activate
                    children: const [
                      SizedBox(height: 150),
                      Center(
                        child: Text(
                          "Belum ada artikel yang dipublikasikan.",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: const Color(0xFFFF8C00),
                backgroundColor: const Color(0xFF1E1E1E),
                onRefresh: _refreshFeed, // Triggers the network call again
                child: ListView.builder(
                  // physics is required to ensure pull-to-refresh works even if the list is short
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _buildArticleCard(context, post);
                  },
                ),
              );
            },
          ),

          // bottomNavigationBar: Container(
          //   color: const Color(0xFF121212),
          //   padding: const EdgeInsets.symmetric(vertical: 8),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //     children: [
          //       _buildNavItem(Icons.emoji_events_outlined, "Akademik", 0),
          //       _buildNavItem(Icons.school_outlined, "Kampus", 1),
          //       _buildNavItem(Icons.calendar_today_outlined, "Acara", 2),
          //       _buildNavItem(Icons.people_outline, "Organisasi", 3),
          //     ],
          //   ),
          // ),
        );
      },
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
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticlePage(articleId: post.postId),
          ),
        );
      },
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
                  errorBuilder: (context, error, stackTrace) => const Center(
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
                children: [
                  _buildInteractionPill(Icons.chat_bubble_outline, "30"),
                  const SizedBox(width: 12),
                  _buildInteractionPillGroup(post.postId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionPill(IconData icon, String count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 16),
          const SizedBox(width: 6),
          Text(
            count,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionPillGroup(String postId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.arrow_upward, color: Color(0xFFFF8C00), size: 16),
          const SizedBox(width: 4),
          Text(
            "300",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.arrow_downward, color: Color(0xFF000080), size: 16),
          const SizedBox(width: 4),
          Text(
            "300",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<Box<LocalBookmark>>(
            valueListenable: Hive.box<LocalBookmark>(
              'local_bookmark_box',
            ).listenable(),
            builder: (context, bookmarkBox, _) {
              final userId = _authController.currentUser?.userId;
              final isBookmarked =
                  userId != null &&
                  bookmarkBox.values.any(
                    (bookmark) =>
                        bookmark.userId == userId && bookmark.postId == postId,
                  );

              return IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onPressed: () => _controller.toggleBookmark(postId),
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked ? const Color(0xFFFF8C00) : Colors.grey,
                  size: 16,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
