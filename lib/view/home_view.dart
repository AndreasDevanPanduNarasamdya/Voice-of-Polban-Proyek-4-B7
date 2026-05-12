import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart'; // Used for formatting real dates
import '../models/cached_post.dart';
import '../models/cached_user.dart';
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
  int _selectedIndex = 0;
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

  String _getAuthorName(String authorId) {
    final user = Hive.box<CachedUser>('cached_user_box').get(authorId);
    return user?.name ?? "Penulis Tidak Diketahui";
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
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/100'),
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
                return const Center(
                  child: Text(
                    "Belum ada artikel yang dipublikasikan.",
                    style: TextStyle(color: Colors.white),
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
              ));
            },
          ),

          bottomNavigationBar: Container(
            color: const Color(0xFF121212),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(Icons.emoji_events_outlined, "Akademik", 0),
                _buildNavItem(Icons.school_outlined, "Kampus", 1),
                _buildNavItem(Icons.calendar_today_outlined, "Acara", 2),
                _buildNavItem(Icons.people_outline, "Organisasi", 3),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? const Color(0xFFFF8C00) : Colors.grey;
    return InkWell(
      onTap: () {
        setState(() => _selectedIndex = index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, CachedPost post) {
    final parsed = jsonDecode(post.cachedData) as Map<String, dynamic>;
    final title = parsed['title'] ?? '';
    final authorId = parsed['author_id']?.toString() ?? '';
    final dateString = DateFormat('EEEE, dd MMMM yyyy').format(post.cachedAt);

    final authorName = _getAuthorName(authorId);

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
                  const CircleAvatar(
                    radius: 12,
                    backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/100?img=11',
                    ),
                  ),
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
            Container(
              height: 250,
              width: double.infinity,
              color: const Color(0xFF2A2A2A),
              child: const Center(
                child: Icon(Icons.image, color: Colors.grey, size: 50),
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
                  _buildInteractionPillGroup(),
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

  Widget _buildInteractionPillGroup() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: const [
          Icon(Icons.arrow_upward, color: Color(0xFFFF8C00), size: 16),
          SizedBox(width: 4),
          Text(
            "300",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 12),
          Icon(Icons.arrow_downward, color: Color(0xFF000080), size: 16),
          SizedBox(width: 4),
          Text(
            "300",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 12),
          Icon(Icons.bookmark_border, color: Colors.grey, size: 16),
        ],
      ),
    );
  }
}