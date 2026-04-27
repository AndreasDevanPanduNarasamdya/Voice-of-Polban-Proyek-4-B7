import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/article_model.dart';
import '../models/user_model.dart';
import '../models/app_enums.dart';
import '../controller/article_controller.dart';
import '../auth/auth_service.dart';
import 'article_view.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final AuthService _authService = AuthService();
  late final ArticleController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ArticleController(authService: _authService);
  }

  // Helper to resolve Foreign Key (authorId) to Real Name
  String _getAuthorName(String authorId) {
    final user = Hive.box<UserModel>('user_box').get(authorId);
    return user?.name ?? "Penulis Tidak Diketahui";
  }

  // The Review Dialog to enforce your Anti-Mass-Approval rule
  void _showReviewDialog(
    BuildContext context,
    ArticleModel article,
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
                    final error = _controller.reviewArticle(
                      articleId: article.articleId,
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
                        _controller.publishArticle(article.articleId);
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
  void _dropArticle(ArticleModel article) {
    Hive.box<ArticleModel>('article_box').delete(article.articleId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Artikel di-drop (dihapus)."),
        backgroundColor: Colors.red,
      ),
    );
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
          "VOP",
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
      body: ValueListenableBuilder<Box<ArticleModel>>(
        valueListenable: Hive.box<ArticleModel>('article_box').listenable(),
        builder: (context, box, _) {
          // Fetch articles that are waiting for editor review (Drafts)
          final pendingArticles =
              box.values
                  .where(
                    (a) =>
                        a.status == ArticleStatus.draft ||
                        a.status == ArticleStatus.pending,
                  )
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (pendingArticles.isEmpty) {
            return const Center(
              child: Text(
                "Tidak ada artikel yang perlu direview.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: pendingArticles.length,
            itemBuilder: (context, index) {
              return _buildEditorCard(context, pendingArticles[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildEditorCard(BuildContext context, ArticleModel article) {
    final authorName = _getAuthorName(article.authorId);

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
          // 👤 Author
          Row(
            children: [
              const CircleAvatar(
                radius: 14,
                backgroundImage: NetworkImage(
                  'https://i.pravatar.cc/100?img=11',
                ),
              ),
              const SizedBox(width: 10),
              Text(
                authorName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 📝 Title
          Text(
            article.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // 🖼 Image / Content Preview
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ArticlePage(articleId: article.articleId),
                ),
              );
            },
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  "Tap untuk membaca artikel",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 🎯 Actions (clean pill style)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionButton(
                icon: Icons.check,
                color: Colors.green,
                label: "Publikasi",
                onTap: () => _showReviewDialog(context, article, true),
              ),
              const SizedBox(width: 10),
              _buildActionButton(
                icon: Icons.close,
                color: Colors.red,
                label: "Tolak",
                onTap: () => _showReviewDialog(context, article, false),
              ),
              const SizedBox(width: 10),
              _buildActionButton(
                icon: Icons.delete_outline,
                color: Colors.red.shade900,
                label: "Drop",
                onTap: () => _dropArticle(article),
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
