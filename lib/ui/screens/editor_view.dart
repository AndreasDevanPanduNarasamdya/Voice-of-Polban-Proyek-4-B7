import 'dart:io'; // Tambahkan import ini untuk membaca file gambar lokal
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:voice_of_polban/processing/auth_controller.dart';
import 'package:voice_of_polban/storage/cached_post.dart';
import 'package:voice_of_polban/storage/cached_user.dart';
import 'package:voice_of_polban/ui/screens/post_view.dart';
import '../../config/app_enums.dart';
import '../../processing/studio_controller.dart';
import '../../api/studio_repository.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final AuthController _authController = AuthController();
  late final StudioController _controller;
  final StudioRepository _repository = StudioRepository();

  @override
  void initState() {
    super.initState();
    _controller = StudioController();
    _repository.fetchPendingPosts();
  }

  Future<void> _refreshEditor() async {
    await _repository.fetchPendingPosts();
  }

  // Helper to resolve Foreign Key (authorId) to Real Name
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
      backgroundColor: const Color(0xFFFF6D00),
      backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
      child: avatarUrl.isEmpty
          ? Icon(Icons.person, color: Colors.white70, size: radius)
          : null,
    );
  }

  // The Review Dialog to enforce your Anti-Mass-Approval rule
  void _showReviewDialog(
    BuildContext context,
    CachedPost post,
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
                  onPressed: () async {
                    bool success = false;

                    try {
                      if (isApprove) {
                        success = await _controller.approvePost(
                          post.postId,
                          note: noteController.text,
                        );
                      } else {
                        success = await _controller.rejectPost(
                          post.postId,
                          note: noteController.text,
                        );
                      }

                      if (!success) {
                        setState(() {
                          errorMessage =
                              "Gagal memproses perubahan status artikel.";
                        });
                      } else {
                        if (context.mounted) {
                          Navigator.pop(context);
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
                      }
                    } catch (e) {
                      setState(() {
                        errorMessage = "Terjadi kesalahan: $e";
                      });
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
  void _dropPost(CachedPost post) {
    final TextEditingController noteController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            "Drop Artikel",
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Masukkan catatan mengapa artikel di-drop:",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Tulis catatan drop...",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF121212),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Hive.box<CachedPost>('cached_post_box').delete(post.postId);

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Artikel di-drop (dihapus)."),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: const Text("Drop", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
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
              TextSpan(
                text: 'V',
                style: TextStyle(color: Color(0xFFFF6D00)),
              ),
              TextSpan(
                text: 'O',
                style: TextStyle(color: Colors.white),
              ),
              TextSpan(
                text: 'P',
                style: TextStyle(color: Color(0xFFFF6D00)),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: _buildAvatar(
              _authController.currentUser?.avatarUrl ?? '',
              18,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFFFF8C00),
        backgroundColor: const Color(0xFF1E1E1E),
        onRefresh: _refreshEditor,
        child: ValueListenableBuilder<Box<CachedPost>>(
          valueListenable: Hive.box<CachedPost>('cached_post_box').listenable(),
          builder: (context, box, _) {
            final pendingPosts = box.values.where((p) {
              final data = jsonDecode(p.cachedData);
              return data['status'] == PostStatus.pending.name;
            }).toList()..sort((a, b) => b.cachedAt.compareTo(a.cachedAt));

            if (pendingPosts.isEmpty) {
              return ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(), // Forces pull-to-refresh
                children: const [
                  SizedBox(height: 200),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          color: Colors.white24,
                          size: 56,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Tidak ada artikel yang perlu direview.',
                          style: TextStyle(color: Colors.white38, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: pendingPosts.length,
              itemBuilder: (context, index) =>
                  _buildEditorCard(context, pendingPosts[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEditorCard(BuildContext context, CachedPost post) {
    // 1. Decode JSON
    final data = jsonDecode(post.cachedData);

    // 2. Extract author_id, title, and image
    final authorId = data['author_id']?.toString() ?? '';
    final title = data['title']?.toString() ?? 'Tanpa Judul';
    final imageUrls = data['imageUrls'] as List<dynamic>? ?? [];

    // 3. Setup others
    final authorName = _getAuthorName(authorId);
    final authorAvatar = _getAuthorAvatar(authorId);
    final dateStr = _formatDate(post.cachedAt);

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
              _buildAvatar(authorAvatar, 16),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Penulis',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  Text(
                    authorName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                dateStr,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Judul artikel
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // ── Preview Gambar / Konten (Ganti Kotak Abu-abu Di Sini) ──
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ArticlePage(articleId: post.postId),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrls.isNotEmpty
                  ? (() {
                      final imgPath = imageUrls.first.toString();
                      final isNetwork = imgPath.startsWith('http');

                      return isNetwork
                          ? Image.network(
                              imgPath,
                              width: double.infinity,
                              height: 160,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const _ImagePlaceholder(),
                            )
                          : Image.file(
                              File(imgPath),
                              width: double.infinity,
                              height: 160,
                              fit: BoxFit.cover,
                            );
                    })()
                  : const _ImagePlaceholder(),
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
                onTap: () => _showReviewDialog(context, post, true),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.close,
                color: Colors.red,
                label: 'Tolak',
                onTap: () => _showReviewDialog(context, post, false),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.delete_outline,
                color: Colors.red,
                label: 'Drop',
                onTap: () => _dropPost(post),
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
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget Placeholder jika gambar tidak ada atau gagal diload
class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Icon(Icons.image_outlined, color: Colors.white24, size: 40),
      ),
    );
  }
}
