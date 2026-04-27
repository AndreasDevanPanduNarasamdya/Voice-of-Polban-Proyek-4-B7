import 'package:flutter/material.dart';
import 'package:voice_of_polban/view/home_view.dart';

class ArticlePage extends StatefulWidget {
  final ArticleModel? article;
  const ArticlePage({super.key, this.article});

  @override
  State<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends State<ArticlePage> {
  static const Color _bgColor = Color(0xFF1A1A2E);
  static const Color _cardColor = Color(0xFF16213E);
  static const Color _accentColor = Color(0xFF0F3460);
  static const Color _highlightColor = Color(0xFFE94560);

  final TextEditingController _commentController = TextEditingController();
  final List<Map<String, String>> _comments = [];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _comments.add({'name': 'Kamu', 'text': text, 'time': 'Baru saja'});
    });
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(color: _highlightColor, shape: BoxShape.circle),
              child: const Icon(Icons.campaign, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
            const Text('Voice of Polban',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.account_circle, color: Colors.white, size: 28),
          ),
        ],
      ),
      body: article == null
          ? const Center(
              child: Text('Artikel tidak ditemukan', style: TextStyle(color: Colors.white54)))
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                // Gambar artikel
                article.imageUrl != null
                    ? Image.network(
                        article.imageUrl!,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imgPlaceholder(),
                      )
                    : _imgPlaceholder(),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge kategori
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _highlightColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _highlightColor.withOpacity(0.4)),
                        ),
                        child: Text(article.category,
                            style: const TextStyle(
                                color: _highlightColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 12),

                      // Judul
                      Text(article.title,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),

                      // Deskripsi
                      Text(article.description,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic)),
                      const SizedBox(height: 12),

                      // Penulis & tanggal
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 16,
                            backgroundColor: _accentColor,
                            child: Icon(Icons.person, color: Colors.white70, size: 18),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(article.author,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                              Text(article.date,
                                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
                            ],
                          ),
                          const Spacer(),
                          _iconBtn(Icons.bookmark_border, () {}),
                          _iconBtn(Icons.share_outlined, () {}),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 16),

                      // Isi artikel
                      Text(article.content,
                          style: const TextStyle(
                              color: Colors.white12, fontSize: 14, height: 1.7)),

                      const SizedBox(height: 32),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 16),

                      // ---- KOLOM KOMENTAR ----
                      const Text('Komentar',
                          style: TextStyle(
                              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),

                      // Form komentar
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Tulis komentar...',
                                hintStyle: const TextStyle(color: Colors.white38),
                                filled: true,
                                fillColor: _cardColor,
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: _accentColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: _accentColor.withOpacity(0.6)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: _highlightColor),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _submitComment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _highlightColor,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            child: const Icon(Icons.send, color: Colors.white, size: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Daftar komentar
                      _comments.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Text('Belum ada komentar',
                                    style: TextStyle(color: Colors.white38, fontSize: 13)),
                              ),
                            )
                          : Column(
                              children: _comments
                                  .map((c) => _buildCommentTile(c))
                                  .toList(),
                            ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _imgPlaceholder() => Container(
        height: 220,
        width: double.infinity,
        color: _accentColor,
        child: const Center(
          child: Icon(Icons.image_outlined, color: Colors.white24, size: 56),
        ),
      );

  Widget _iconBtn(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Icon(icon, color: Colors.white54, size: 20),
        ),
      );

  Widget _buildCommentTile(Map<String, String> comment) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _accentColor.withOpacity(0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: _accentColor,
              child: Icon(Icons.person, color: Colors.white70, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(comment['name'] ?? '',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                      const Spacer(),
                      Text(comment['time'] ?? '',
                          style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(comment['text'] ?? '',
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      );
}