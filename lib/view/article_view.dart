import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/cached_post.dart';
import '../models/cached_user.dart';
import '../models/local_bookmark.dart';
import '../auth/auth_controller.dart';
import '../controller/post_controller.dart';

class ArticlePage extends StatefulWidget {
  final String articleId;
  const ArticlePage({super.key, required this.articleId});

  @override
  State<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends State<ArticlePage> {
  CachedPost? _post;
  final AuthController _authController = AuthController();
  final PostController _postController = PostController();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  double _galleryHeight = 250;

  @override
  void dispose() {
    _pageController.dispose();
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

            // Image gallery — natural ratio + dot indicators
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

            // Interaction Bar
            Padding(
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
                        Icon(
                          Icons.arrow_upward,
                          color: Color(0xFFFF8C00),
                          size: 16,
                        ),
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
                        Icon(
                          Icons.arrow_downward,
                          color: Color(0xFF000080),
                          size: 16,
                        ),
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
                                      bookmark.postId == widget.articleId,
                                );

                            return IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _postController.toggleBookmark(
                                widget.articleId,
                              ),
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
            ),
            const Divider(color: Color(0xFF333333)),

            // Comment Input
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    _buildAvatar(myAvatarUrl, 12),
                    const SizedBox(width: 12),
                    const Text(
                      "Tulis Komentar",
                      style: TextStyle(
                        color: Color(0xFFFF8C00),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            _buildDummyComment("Richard Joe", "🔥🔥🔥"),
            _buildDummyComment("Christie Lee", "🔥🔥🔥"),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDummyComment(String name, String comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dummy commenters keep placeholder since we don't have their data
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.grey[700],
            child: const Icon(Icons.person, color: Colors.white70, size: 14),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "31 Agustus 2025",
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                comment,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
