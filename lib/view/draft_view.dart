import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_enums.dart';
import '../models/cached_post.dart';
import '../models/cached_user.dart';
import '../models/local_draft.dart';
import '../auth/auth_controller.dart';
import '../controller/post_controller.dart';
import 'writer_view.dart';
import 'dart:convert';

class DraftPage extends StatefulWidget {
  const DraftPage({super.key});

  @override
  State<DraftPage> createState() => _DraftPageState();
}

class _DraftPageState extends State<DraftPage> {
  static const Color _bgColor     = Color(0xFF1A1A1A);
  static const Color _orangeColor = Color(0xFFFF6D00);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthController _AuthController = AuthController();
  late final PostController _articleController;

  @override
  void initState() {
    super.initState();
    _articleController = PostController();
  }

  List<LocalDraft> _getMyArticles() {
    // Use the actual property: currentUser?.userId
    final currentUserId = _AuthController.currentUser?.userId; 
    if (currentUserId == null) return [];

    // Use the actual box name defined in PostController: 'cached_post_box'
    final box = Hive.box<LocalDraft>('local_draft_box'); 
    
    return box.values
            .where((a) => a.userId == currentUserId)
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)); // Use updatedAt
  }

  String _getAuthorName(String authorId) {
    final box = Hive.box<CachedUser>('cached_user_box'); // Box is 'cached_user_box'
    return box.get(authorId)?.name ?? 'Penulis';
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
      key: _scaffoldKey,
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _orangeColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            children: [
              TextSpan(text: 'V', style: TextStyle(color: Color(0xFFFF6D00))),
              TextSpan(text: 'o', style: TextStyle(color: Colors.white)),
              TextSpan(text: 'P', style: TextStyle(color: Color(0xFFFF6D00))),
            ],
          ),
        ),
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
      body: ValueListenableBuilder(
        valueListenable: Hive.box<LocalDraft>('local_draft_box').listenable(),
        builder: (context, Box<LocalDraft> box, _) {
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
            padding: const EdgeInsets.only(top: 4, bottom: 24),
            itemCount: articles.length,
            itemBuilder: (ctx, i) {
              final draft = articles[i]; // 1. Use a semicolon here
              
              return _DraftCard(         // 2. You MUST return the widget
                article: draft,// Missing 'final'
              authorName: _getAuthorName(draft.userId), // Floating parameter, no widget!
              dateStr: _formatDate(draft.updatedAt),    // Used semicolons instead of commas
              controller: _articleController,
              );                         // 4. Semicolon to end the return statement
            },
          );
        },
      ),
    );
  }
}

// ── Card sebagai StatefulWidget agar tiap card punya state expand sendiri ──
class _DraftCard extends StatefulWidget {
  final LocalDraft article;
  final String authorName;
  final String dateStr;
  final PostController controller;

  const _DraftCard({
    required this.article,
    required this.authorName,
    required this.dateStr,
    required this.controller,
  });

  @override
  State<_DraftCard> createState() => _DraftCardState();
}

class _DraftCardState extends State<_DraftCard> {
  bool _expanded = false;

  static const Color _bgColor      = Color(0xFF1A1A1A);
  static const Color _redColor     = Color(0xFFE53935);
  static const Color _greenColor   = Color(0xFF43A047);
  static const Color _orangeColor  = Color(0xFFFF6D00);
  static const Color _dividerColor = Color(0xFF333333);

  @override
  Widget build(BuildContext context) {
    final article = widget.article;

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Author + tanggal ──
          Row(
            children: [
              const CircleAvatar(
                radius: 12,
                backgroundColor: Color(0xFF444444),
                child: Icon(Icons.person, color: Colors.white60, size: 14),
              ),
              const SizedBox(width: 8),
              Text(widget.authorName,
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(width: 8),
              Text(widget.dateStr,
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),

          // ── Judul ──
          Text(
            article.title,
            style: const TextStyle(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // ── Tombol "Lihat Gambar" / collapse ──
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.white54,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  _expanded ? 'Sembunyikan' : 'Lihat Gambar',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),

          // ── Konten artikel (expandable) ──
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Container(
              margin: const EdgeInsets.only(top: 10),
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF252525),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _dividerColor),
              ),
              child: Text(
                article.content,
                style: const TextStyle(
                    color: Colors.white12, fontSize: 14, height: 1.6),
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),

          // ── Komentar penolakan (hanya jika rejected) ──
          if (article.status == PostStatus.rejected &&
              article.rejectionNote != null &&
              article.rejectionNote!.isNotEmpty) ...[
            const SizedBox(height: 10),
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
                      style:
                          const TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // ── Tombol aksi berdasarkan status ──
          _buildStatusRow(article),
        ],
      ),
    );
  }

  Widget _buildStatusRow(LocalDraft article) {
    switch (article.status) {
      // Ditolak: Edit + Drop (kiri), chip Ditolak (kanan)
      case PostStatus.rejected:
        return Row(
          children: [
            _actionBtn(
              icon: Icons.edit,
              label: 'Edit',
              color: Colors.white,
              bgColor: const Color(0xFF333333),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => WriterPage(draftId: article.localId))),
            ),
            const SizedBox(width: 8),
            _actionBtn(
              icon: Icons.delete,
              label: 'Drop',
              color: _redColor,
              bgColor: const Color(0xFF333333),
              onTap: () => widget.controller.deleteArticle(article.postId),
            ),
            const Spacer(),
            _statusChip(
                icon: Icons.close, label: 'Ditolak', color: _redColor,
                filled: true),
          ],
        );

      // Terpublikasi: upvote count (kiri), chip hijau (kanan)
      case PostStatus.published:
        return Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.arrow_upward, color: _orangeColor, size: 16),
                  SizedBox(width: 6),
                  Text('300',
                      style:
                          TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
            ),
            const Spacer(),
            _statusChip(
                icon: Icons.check,
                label: 'Terpublikasi',
                color: _greenColor,
                filled: true),
          ],
        );

      // Dihapus/Archived: chip merah (kanan saja)
      case PostStatus.archived:
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _statusChip(
                icon: Icons.delete, label: 'Dihapus', color: _redColor,
                filled: true),
          ],
        );

      // Menunggu review: chip orange (kanan saja)
      case PostStatus.pending:
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _statusChip(
                icon: Icons.hourglass_empty,
                label: 'Menunggu Review',
                color: Colors.orange,
                filled: false),
          ],
        );

      // Draft: Edit + Hapus (kiri), chip abu (kanan)
      case PostStatus.draft:
      default:
        return Row(
          children: [
            _actionBtn(
              icon: Icons.edit,
              label: 'Edit',
              color: Colors.white,
              bgColor: const Color(0xFF333333),
              onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => WriterPage(draftId: article.localId))),
            ),
            const SizedBox(width: 8),
            _actionBtn(
              icon: Icons.delete,
              label: 'Hapus',
              color: _redColor,
              bgColor: const Color(0xFF333333),
              onTap: () => widget.controller.deleteArticle(article.localId),
            ),
            const Spacer(),
            _statusChip(
                icon: Icons.edit_note,
                label: 'Draft',
                color: Colors.white54,
                filled: false),
          ],
        );
    }
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
    required bool filled,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? color.withOpacity(0.15) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}