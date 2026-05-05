import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../controller/post_controller.dart';
import '../models/cached_post.dart';
import '../models/cached_user.dart';
import 'article_view.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final PostController _controller = PostController();
  late Future<List<CachedPost>> _pendingPostsFuture;

  @override
  void initState() {
    super.initState();
    _pendingPostsFuture = _controller.fetchPendingPosts();
  }

  String _getAuthorName(String authorId) {
    final user = Hive.box<CachedUser>('cached_user_box').get(authorId);
    return user?.name ?? 'Penulis Tidak Diketahui';
  }

  Map<String, dynamic> _parsePostData(CachedPost post) {
    final decoded = jsonDecode(post.cachedData);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{};
  }

  Future<void> _refresh() async {
    setState(() {
      _pendingPostsFuture = _controller.fetchPendingPosts();
    });
  }

  Future<void> _approvePost(CachedPost post) async {
    final ok = await _controller.approvePost(post.postId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Artikel dipublikasikan.' : 'Gagal mempublikasikan artikel.',
        ),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
    if (ok) {
      await _refresh();
    }
  }

  Future<void> _rejectPost(CachedPost post) async {
    final ok = await _controller.rejectPost(post.postId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Artikel ditolak.' : 'Gagal menolak artikel.'),
        backgroundColor: ok ? Colors.orange : Colors.red,
      ),
    );
    if (ok) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFFF8C00)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'VOP',
          style: TextStyle(
            color: Color(0xFF000080),
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
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
      body: FutureBuilder<List<CachedPost>>(
        future: _pendingPostsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF8C00)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Gagal memuat antrian review: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final posts = snapshot.data ?? <CachedPost>[];
          if (posts.isEmpty) {
            return const Center(
              child: Text(
                'Tidak ada artikel yang perlu direview.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFFFF8C00),
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return _buildEditorCard(context, posts[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditorCard(BuildContext context, CachedPost post) {
    final data = _parsePostData(post);
    final title = data['title']?.toString() ?? 'Tanpa Judul';
    final content = data['content']?.toString() ?? '';
    final authorId = data['author_id']?.toString() ?? '';
    final status = data['status']?.toString() ?? 'pending';
    final createdAt = DateFormat('dd MMMM yyyy').format(post.cachedAt);
    final authorName = _getAuthorName(authorId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 14,
                backgroundImage: NetworkImage(
                  'https://i.pravatar.cc/100?img=11',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '$createdAt • ${status.toUpperCase()}',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArticlePage(articleId: post.postId),
                ),
              );
            },
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Tap untuk membaca artikel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionButton(
                icon: Icons.check,
                color: Colors.green,
                label: 'Publikasi',
                onTap: () => _approvePost(post),
              ),
              const SizedBox(width: 10),
              _buildActionButton(
                icon: Icons.close,
                color: Colors.red,
                label: 'Tolak',
                onTap: () => _rejectPost(post),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
