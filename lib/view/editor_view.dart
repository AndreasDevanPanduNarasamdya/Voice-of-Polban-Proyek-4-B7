import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:voice_of_polban/auth/auth_controller.dart';
import 'package:voice_of_polban/models/cached_post.dart';
import 'package:voice_of_polban/models/cached_user.dart';
import '../models/cached_post.dart';
import '../models/cached_user.dart';
import '../models/app_enums.dart';
import '../controller/Post_controller.dart';
import '../auth/auth_service.dart';
import 'Post_view.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final AuthController _AuthController =AuthController();
  late final PostController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PostController(AuthController: _AuthController);
  }

  // Helper to resolve Foreign Key (authorId) to Real Name
  String _getAuthorName(String authorId) {
    final user = Hive.box<CachedUser>('user_box').get(authorId);
    return user?.name ?? "Penulis Tidak Diketahui";
  }

  // The Review Dialog to enforce your Anti-Mass-Approval rule
  void _showReviewDialog(
    BuildContext context,
    CachedPost Post,
    bool isApprove,
  ) {
    final TextEditingController noteController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: Text(
                isApprove ? "Publikasi Artikel" : "Tolak Artikel",
                style: const TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Masukkan catatan untuk penulis:",
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Tulis catatan review...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF121212),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Batal",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isApprove ? Colors.green : Colors.red,
                  ),
                  onPressed: () {
                    // Call the controller method
                    final error = _controller.reviewPost(
                      PostId: Post.postId,
                      approved: isApprove,
                      note: noteController.text,
                    );

                    if (error != null) {
                      // Trigger red error text
                      setState(() {
                        errorMessage = error;
                      });
                    } else {
                      // If approved, automatically publish it to the feed
                      if (isApprove) {
                        _controller.publishPost(Post.PostId);
                      }
                      Navigator.pop(context); // Close dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isApprove
                                ? "Artikel Dipublikasikan!"
                                : "Artikel Ditolak",
                          ),
                          backgroundColor: isApprove
                              ? Colors.green
                              : Colors.red,
                        ),
                      );
                    }
                  },
                  child: Text(
                    isApprove ? "Publikasi" : "Tolak",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Handles the "Drop" (Delete) action
  void _dropPost(CachedPost Post) {
    Hive.box<CachedPost>('Post_box').delete(Post.PostId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Artikel di-drop (dihapus)."),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const days = ['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'];
    const months = [
      'Januari','Februari','Maret','April','Mei','Juni',
      'Juli','Agustus','September','Oktober','November','Desember'
    ];
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFFF8C00)),
          onPressed: () => Navigator.pop(context),
        ),
        title: RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            children: [
              TextSpan(text: 'V', style: TextStyle(color: Color(0xFFFF6D00))),
              TextSpan(text: 'O', style: TextStyle(color: Colors.white)),
              TextSpan(text: 'P', style: TextStyle(color: Color(0xFFFF6D00))),
            ],
          ),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFFF6D00),
              backgroundImage: NetworkImage('https://i.pravatar.cc/100'),
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder<Box<CachedPost>>(
        valueListenable: Hive.box<CachedPost>('Post_box').listenable(),
        builder: (context, box, _) {
          final pendingPosts = box.values
              .where((a) =>
                  a.status == PostStatus.draft ||
                  a.status == PostStatus.pending)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (pendingPosts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, color: Colors.white24, size: 56),
                  SizedBox(height: 12),
                  Text('Tidak ada artikel yang perlu direview.',
                      style: TextStyle(color: Colors.white38, fontSize: 15)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: pendingPosts.length,
            itemBuilder: (context, index) =>
                _buildEditorCard(context, pendingPosts[index]),
          );
        },
      ),
    );
  }

  Widget _buildEditorCard(BuildContext context, CachedPost Post) {
    final authorName = _getAuthorName(Post.authorId);
    final dateStr = _formatDate(Post.createdAt);

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author + role badge
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFFFF6D00),
                backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=11'),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Writter',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                  Text(authorName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ],
              ),
              const Spacer(),
              Text(dateStr,
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),

          const SizedBox(height: 10),

          // Judul artikel
          Text(
            Post.title,
            style: const TextStyle(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          // Preview konten — tap untuk baca
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => PostPage(PostId: Post.PostId)),
            ),
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('Tap untuk membaca artikel',
                    style: TextStyle(color: Colors.white38, fontSize: 13)),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Tombol aksi: Publikasi | Tolak | Drop
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionButton(
                icon: Icons.check,
                color: Colors.green,
                label: 'Publikasi',
                onTap: () => _showReviewDialog(context, Post, true),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.close,
                color: Colors.red,
                label: 'Tolak',
                onTap: () => _showReviewDialog(context, Post, false),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.delete_outline,
                color: Colors.red,
                label: 'Drop',
                onTap: () => _dropPost(Post),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}