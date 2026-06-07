import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../storage/cached_post.dart';
import '../../storage/cached_user.dart';
import '../../storage/local_bookmark.dart';
import '../../storage/comment_model.dart';
import '../../processing/auth_controller.dart';
import '../../processing/feed_controller.dart';
import '../../processing/sync_worker.dart';
import '../../api/feed_repository.dart';

class ArticlePage extends StatefulWidget {
  final String articleId;
  const ArticlePage({super.key, required this.articleId});

  @override
  State<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends State<ArticlePage> {
  CachedPost? _post;
  final AuthController _authController = AuthController();
  final FeedController _feedController = FeedController();
  final FeedRepository _feedRepository = FeedRepository();
  final SyncWorker _syncWorker = SyncWorker();
  final PageController _pageController = PageController();

  // Controller dan State untuk fitur komentar
  final TextEditingController _commentController = TextEditingController();
  List<CommentModel> _comments = [];
  bool _isLoadingComments = true;
  bool _isSubmittingComment = false;

  int _currentPage = 0;
  double _galleryHeight = 250;

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

  Future<void> _handleVote({required bool isUpvoteTarget}) async {
    try {
      await _feedController.castVote(
        postId: widget.articleId,
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

  // Fungsi untuk mengambil komentar dari Supabase
  Future<void> _loadComments() async {
    if (!mounted) return;
    setState(() => _isLoadingComments = true);

    try {
      final comments = await _feedRepository.fetchComments(widget.articleId);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingComments = false);
      debugPrint("Gagal memuat komentar: $e");
    }
  }

  // Fungsi untuk mengirim komentar baru
  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmittingComment = true);
    try {
      await _feedRepository.addComment(postId: widget.articleId, content: text);

      _commentController.clear();
      FocusScope.of(context).unfocus(); // Menutup keyboard

      // Muat ulang komentar untuk menampilkan komentar yang baru dikirim
      await _loadComments();
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isSubmittingComment = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _preloadImageHeights(List<String> urls, double maxWidth) {
    for (final url in urls) {
      final image = NetworkImage(url);
      final stream = image.resolve(const ImageConfiguration());
      stream.addListener(
        ImageStreamListener((info, _) {
          final imgH = info.image.height.toDouble();
          final imgW = info.image.width.toDouble();
          if (imgW == 0) return;
          final ratio = imgH / imgW;
          final displayH = maxWidth * ratio;
          if (displayH > _galleryHeight && mounted) {
            setState(() => _galleryHeight = displayH);
          }
        }),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadComments(); // Panggil fetch comments saat halaman dimuat
    _syncWorker.syncLiveVoteCount(widget.articleId);
    _post = Hive.box<CachedPost>('cached_post_box').get(widget.articleId);
    if (_post != null) {
      final parsed = jsonDecode(_post!.cachedData) as Map<String, dynamic>;
      final urls = (parsed['imageUrls'] as List? ?? [])
          .map((e) => e.toString())
          .toList();
      if (urls.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final width = MediaQuery.of(context).size.width;
          _preloadImageHeights(urls, width);
        });
      }
    }
  }

  String _getAuthorName(String authorId) {
    final user = Hive.box<CachedUser>('cached_user_box').get(authorId);
    return user?.name ?? "Penulis Tidak Diketahui";
  }

  String _getAuthorAvatar(String authorId) {
    final user = Hive.box<CachedUser>('cached_user_box').get(authorId);
    return user?.avatarUrl ?? '';
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

  @override
  Widget build(BuildContext context) {
    final myAvatarUrl = _authController.currentUser?.avatarUrl ?? '';

    if (_post == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: const Color(0xFF121212),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFFF8C00)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text(
            "Artikel tidak ditemukan.",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final p = _post!;
    final parsed = jsonDecode(p.cachedData) as Map<String, dynamic>;
    final title = parsed['title'] ?? '';
    final content = parsed['content'] ?? '';
    final authorId = parsed['author_id']?.toString() ?? '';
    final dateString = DateFormat('EEEE, dd MMMM yyyy').format(p.cachedAt);
    final authorName = _getAuthorName(authorId);
    final authorAvatar = _getAuthorAvatar(authorId);
    final hashtags =
        (parsed['hashtags'] as List<dynamic>?)?.cast<String>() ?? [];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFFF8C00)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _buildAvatar(myAvatarUrl, 16),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Author Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _buildAvatar(authorAvatar, 16),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        dateString,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Image gallery
            if (parsed['imageUrls'] != null &&
                (parsed['imageUrls'] as List).isNotEmpty)
              Builder(
                builder: (context) {
                  final urls = (parsed['imageUrls'] as List)
                      .map((e) => e.toString())
                      .toList();
                  return Column(
                    children: [
                      SizedBox(
                        height: _galleryHeight,
                        width: double.infinity,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: urls.length,
                          onPageChanged: (i) =>
                              setState(() => _currentPage = i),
                          itemBuilder: (context, index) {
                            return Image.network(
                              urls[index],
                              width: double.infinity,
                              fit: BoxFit.fitWidth,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.red,
                                      size: 50,
                                    ),
                                  ),
                            );
                          },
                        ),
                      ),
                      if (urls.length > 1) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(urls.length, (i) {
                            final active = i == _currentPage;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: active ? 16 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: active
                                    ? const Color(0xFFFF6D00)
                                    : Colors.white24,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  );
                },
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),

            // Hashtags (Hanya tampil jika ada hashtag)
            if (hashtags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Wrap(
                  spacing: 8.0, // Jarak horizontal antar hashtag
                  runSpacing:
                      4.0, // Jarak vertikal jika hashtag turun ke baris baru
                  children: hashtags
                      .map(
                        (tag) => Text(
                          '#$tag',
                          style: const TextStyle(
                            color: Color(
                              0xFFFF8C00,
                            ), // Menggunakan warna oranye tema VOP
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),

            const SizedBox(height: 8), // Sedikit jarak sebelum tombol like
            // Interaction Bar
            ValueListenableBuilder<Box<CachedPost>>(
              valueListenable: Hive.box<CachedPost>(
                'cached_post_box',
              ).listenable(keys: [widget.articleId]),
              builder: (context, postBox, _) {
                final livePost = postBox.get(widget.articleId) ?? _post;
                final liveParsed = livePost == null
                    ? <String, dynamic>{}
                    : Map<String, dynamic>.from(
                        jsonDecode(livePost.cachedData) as Map,
                      );

                final upvoteCount = _readUpvoteCount(liveParsed);
                final isUpvotedByMe = _readBoolFlag(
                  liveParsed,
                  'is_upvoted_by_me',
                );
                final isDownvotedByMe = _readBoolFlag(
                  liveParsed,
                  'is_downvoted_by_me',
                );

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
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
                                  _handleVote(isUpvoteTarget: true),
                              icon: Icon(
                                isUpvotedByMe
                                    ? Icons.arrow_circle_up
                                    : Icons.arrow_upward,
                                color: isUpvotedByMe
                                    ? const Color(0xFFFF8C00)
                                    : Colors.grey,
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
                                  _handleVote(isUpvoteTarget: false),
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
                            const SizedBox(width: 12),
                            ValueListenableBuilder<Box<LocalBookmark>>(
                              valueListenable: Hive.box<LocalBookmark>(
                                'local_bookmark_box',
                              ).listenable(),
                              builder: (context, bookmarkBox, _) {
                                final userId =
                                    _authController.currentUser?.userId;
                                final isBookmarked =
                                    userId != null &&
                                    bookmarkBox.values.any(
                                      (bookmark) =>
                                          bookmark.userId == userId &&
                                          bookmark.postId == widget.articleId,
                                    );

                                return IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _feedController
                                      .toggleBookmark(widget.articleId),
                                  icon: Icon(
                                    isBookmarked
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
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
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(color: Color(0xFF333333)),

            // Comment Input Section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  _buildAvatar(myAvatarUrl, 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Tulis Komentar...',
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF1E1E1E),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submitComment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isSubmittingComment
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFFF8C00),
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Color(0xFFFF8C00),
                          ),
                          onPressed: _submitComment,
                        ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Dynamic Comments List
            _isLoadingComments
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF8C00),
                      ),
                    ),
                  )
                : _comments.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "Belum ada komentar. Jadilah yang pertama!",
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(), // Agar scroll mengikuti SingleChildScrollView
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      return _buildCommentItem(_comments[index]);
                    },
                  ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Widget dinamis untuk setiap item komentar
  Widget _buildCommentItem(CommentModel comment) {
    // Format tanggal
    final wibTime = comment.createdAt.toUtc().add(const Duration(hours: 7));
    final formattedDate = DateFormat('dd MMM yyyy').format(wibTime);
    final displayName = comment.authorName.isNotEmpty
        ? comment.authorName
        : "User";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.grey[700],
            child: const Icon(Icons.person, color: Colors.white70, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formattedDate,
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
