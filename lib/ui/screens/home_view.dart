import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart'; // Used for formatting real dates
import '../../storage/cached_post.dart';
import '../../storage/cached_user.dart';
import '../../storage/local_bookmark.dart';
import '../../config/app_enums.dart';
import '../../processing/feed_controller.dart';
import '../../processing/sync_worker.dart';
import '../../processing/auth_controller.dart';
import 'package:voice_of_polban/ui/widgets/sidebar.dart';
import 'post_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthController _authController = AuthController();
  final FeedController _controller = FeedController();
  final SyncWorker _syncWorker = SyncWorker();
  final TextEditingController _searchController = TextEditingController();
  late Future<List<CachedPost>> _onlineFeed;

  void _onSearchChanged(String value) {
    setState(() {
      _controller.updateSearchQuery(value);
    });
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
    if (raw is String) {
      return raw.toLowerCase() == 'true';
    }
    return false;
  }

  // int _readUpvoteCount(Map<String, dynamic> parsed) {
  //   final raw = parsed['upvote_count'];
  //   if (raw is int) return raw;
  //   if (raw is num) return raw.toInt();
  //   if (raw is String) return int.tryParse(raw) ?? 0;
  //   return 0;
  // }

  // bool _readBoolFlag(Map<String, dynamic> parsed, String key) {
  //   final raw = parsed[key];
  //   if (raw is bool) return raw;
  //   if (raw is String) {
  //     return raw.toLowerCase() == 'true';
  //   }
  //   return false;
  // }

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
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void initState() {
    super.initState();
    _syncWorker.processSyncQueue();

    // 🚨 FIX: Load the feed, and the millisecond it finishes,
    // tell the worker to quietly fetch the live votes for every post in the background.
    _onlineFeed = _controller.fetchFeed().then((posts) {
      for (var post in posts) {
        _syncWorker.syncLiveVoteCount(post.postId);
      }
      return posts;
    });
  }

  Future<void> _refreshFeed() async {
    setState(() {
      // 🚨 FIX: Do the exact same background sync when the user pulls to refresh.
      _onlineFeed = _controller.fetchFeed().then((posts) {
        for (var post in posts) {
          _syncWorker.syncLiveVoteCount(post.postId);
        }
        return posts;
      });
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
            title: Image.asset('assets/Logo_VOP.png', height: 32),
            centerTitle: true,
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
          body: Column(
            children: [
              Container(
                color: const Color(0xFF1A1A1A),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF121212),
                          borderRadius: BorderRadius.circular(22.0),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() {
                            _controller.updateSearchQuery(value);
                          }),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Cari Postingan',
                            hintStyle: TextStyle(
                              color: Colors.white38,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.white38,
                              size: 20,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(22.0),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<SortMode>(
                          value: _controller
                              .sortMode, // Make sure you added sortMode to your Controller
                          dropdownColor: const Color(0xFF1E1E1E),
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Color(0xFFFF8C00),
                          ),
                          onChanged: (SortMode? mode) {
                            if (mode != null) {
                              setState(() => _controller.updateSortMode(mode));
                            }
                          },
                          items: const [
                            DropdownMenuItem(
                              value: SortMode.terbaru,
                              child: Text(
                                "Terbaru",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            DropdownMenuItem(
                              value: SortMode.terlama,
                              child: Text(
                                "Terlama",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            DropdownMenuItem(
                              value: SortMode.populer,
                              child: Text(
                                "Populer",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<CachedPost>>(
                  future: _onlineFeed,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFF8C00),
                        ),
                      );
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return const Center(
                        child: Text(
                          'Gagal memuat feed.',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    final allPosts = snapshot.data!; // safe now
                    _controller.updateFeed(allPosts);
                    final posts = _controller.getFilteredFeed();

                    if (posts.isEmpty) {
                      return const Center(
                        child: Text(
                          "Tidak ada hasil.",
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _refreshFeed,
                      child: ListView.builder(
                        itemCount: posts.length,
                        itemBuilder: (context, index) =>
                            _buildArticleCard(context, posts[index]),
                      ),
                    );
                  },
                ),
              ),
            ],
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
                  _buildReactiveCommentPill(post.postId),
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

  Widget _buildReactiveCommentPill(String postId) {
    return ValueListenableBuilder<Box<CachedPost>>(
      valueListenable: Hive.box<CachedPost>(
        'cached_post_box',
      ).listenable(keys: [postId]),
      builder: (context, postBox, _) {
        final livePost = postBox.get(postId);
        final parsed = livePost == null
            ? <String, dynamic>{}
            : Map<String, dynamic>.from(jsonDecode(livePost.cachedData) as Map);

        final raw = parsed['comment_count'];
        int commentCount = 0;
        if (raw is int) commentCount = raw;
        else if (raw is num) commentCount = raw.toInt();
        else if (raw is String) commentCount = int.tryParse(raw) ?? 0;

        return _buildInteractionPill(Icons.chat_bubble_outline, commentCount.toString());
      },
    );
  }

  Widget _buildInteractionPillGroup(String postId) {
    return ValueListenableBuilder<Box<CachedPost>>(
      // Menambahkan filter `keys` agar widget hanya rebuild jika postId yang sesuai berubah
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
                  final userId = _authController.currentUser?.userId;
                  final isBookmarked =
                      userId != null &&
                      bookmarkBox.values.any(
                        (bookmark) =>
                            bookmark.userId == userId &&
                            bookmark.postId == postId,
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
