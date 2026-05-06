import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_enums.dart';
import '../models/article_model.dart';
import '../models/user_model.dart';
import '../auth/auth_service.dart';
import '../controller/article_controller.dart';
import 'writer_view.dart';

class DraftPage extends StatefulWidget {
  const DraftPage({super.key});

  @override
  State<DraftPage> createState() => _DraftPageState();
}

class _DraftPageState extends State<DraftPage> {
  static const Color _bgColor     = Color(0xFF1A1A1A);
  static const Color _orangeColor = Color(0xFFFF6D00);
  static const Color _redColor    = Color(0xFFE53935);
  static const Color _greenColor  = Color(0xFF43A047);
  static const Color _dividerColor = Color(0xFF333333);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthService _authService = AuthService();
  late final ArticleController _articleController;

  @override
  void initState() {
    super.initState();
    _articleController = ArticleController(authService: _authService);
  }

  // Ambil semua artikel milik user yang sedang login, diurutkan terbaru
  List<ArticleModel> _getMyArticles() {
    final currentUserId = _authService.getCurrentUserId();
    if (currentUserId == null) return [];
    final box = Hive.box<ArticleModel>('article_box');
    return box.values
        .where((a) => a.authorId == currentUserId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Ambil nama penulis dari user_box berdasarkan authorId
  String _getAuthorName(String authorId) {
    final box = Hive.box<UserModel>('user_box');
    return box.get(authorId)?.name ?? 'Penulis';
  }

  // Format DateTime ke format Indonesia
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
      key: _scaffoldKey,
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _orangeColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: _buildLogo(),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[700],
              child: const Icon(Icons.person, color: Colors.white70, size: 20),
            ),
          ),
        ],
      ),
      // ValueListenableBuilder: otomatis rebuild saat Hive box berubah
      body: ValueListenableBuilder(
        valueListenable: Hive.box<ArticleModel>('article_box').listenable(),
        builder: (context, Box<ArticleModel> box, _) {
          final articles = _getMyArticles();
          if (articles.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, color: Colors.white24, size: 56),
                  SizedBox(height: 12),
                  Text('Belum ada artikel',
                      style: TextStyle(color: Colors.white38, fontSize: 15)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: articles.length,
            itemBuilder: (ctx, i) => _buildDraftCard(ctx, articles[i]),
          );
        },
      ),
    );
  }

  Widget _buildLogo() {
    return RichText(
      text: const TextSpan(
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        children: [
          TextSpan(text: 'V', style: TextStyle(color: Color(0xFFFF6D00))),
          TextSpan(text: 'o', style: TextStyle(color: Colors.white)),
          TextSpan(text: 'P', style: TextStyle(color: Color(0xFFFF6D00))),
        ],
      ),
    );
  }

  Widget _buildDraftCard(BuildContext context, ArticleModel article) {
    final authorName = _getAuthorName(article.authorId);
    final dateStr = _formatDate(article.createdAt);

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A), width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author + tanggal
            Row(
              children: [
                const CircleAvatar(
                  radius: 12,
                  backgroundColor: Color(0xFF444444),
                  child: Icon(Icons.person, color: Colors.white60, size: 14),
                ),
                const SizedBox(width: 8),
                Text(authorName,
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(width: 8),
                Text(dateStr,
                    style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),

            // Judul
            Text(
              article.title,
              style: const TextStyle(
                  color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Lihat gambar (placeholder, gambar belum diimplementasi di writer)
            Center(
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.keyboard_arrow_down,
                    color: Colors.white54, size: 18),
                label: const Text('Lihat Gambar',
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
              ),
            ),

            // Tampilan berbeda berdasarkan status artikel
            if (article.status == ArticleStatus.rejected) ...[
              if (article.rejectionNote != null &&
                  article.rejectionNote!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _bgColor,
                    border: Border.all(color: _dividerColor),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Komentar:',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text(article.rejectionNote!,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _actionBtn(
                    icon: Icons.edit,
                    label: 'Edit',
                    color: Colors.white,
                    bgColor: const Color(0xFF333333),
                    onTap: () {
                      // Navigasi ke WriterPage untuk edit ulang
                      Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const WriterPage()));
                    },
                  ),
                  const SizedBox(width: 8),
                  _actionBtn(
                    icon: Icons.delete,
                    label: 'Drop',
                    color: _redColor,
                    bgColor: const Color(0xFF333333),
                    onTap: () {
                      _articleController.deleteArticle(article.articleId);
                    },
                  ),
                  const Spacer(),
                  _statusChip(
                    icon: Icons.close,
                    label: 'Ditolak',
                    color: _redColor,
                  ),
                ],
              ),

            ] else if (article.status == ArticleStatus.published) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF333333),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_upward,
                            color: Color(0xFFFF6D00), size: 16),
                        SizedBox(width: 6),
                        Text('0',
                            style: TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _statusChip(
                    icon: Icons.check,
                    label: 'Terpublikasi',
                    color: _greenColor,
                  ),
                ],
              ),

            ] else if (article.status == ArticleStatus.archived) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _statusChip(
                    icon: Icons.delete,
                    label: 'Dihapus',
                    color: _redColor,
                  ),
                ],
              ),

            ] else if (article.status == ArticleStatus.pending) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _statusChip(
                    icon: Icons.hourglass_empty,
                    label: 'Menunggu Review',
                    color: Colors.orange,
                  ),
                ],
              ),

            ] else if (article.status == ArticleStatus.draft) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  _actionBtn(
                    icon: Icons.edit,
                    label: 'Edit',
                    color: Colors.white,
                    bgColor: const Color(0xFF333333),
                    onTap: () {
                      Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const WriterPage()));
                    },
                  ),
                  const SizedBox(width: 8),
                  _actionBtn(
                    icon: Icons.delete,
                    label: 'Hapus',
                    color: _redColor,
                    bgColor: const Color(0xFF333333),
                    onTap: () {
                      _articleController.deleteArticle(article.articleId);
                    },
                  ),
                  const Spacer(),
                  _statusChip(
                    icon: Icons.edit_note,
                    label: 'Draft',
                    color: Colors.white54,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: color, fontSize: 13)),
            ],
          ),
        ),
      );

  Widget _statusChip({
    required IconData icon,
    required String label,
    required Color color,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 13)),
          ],
        ),
      );
}