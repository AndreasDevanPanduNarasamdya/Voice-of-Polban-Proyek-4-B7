import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../config/app_enums.dart';
import '../../storage/cached_user.dart';
import '../../storage/local_draft.dart';
import '../../processing/auth_controller.dart';
import '../../processing/studio_controller.dart';
import 'writer_view.dart';
import 'post_view.dart';

class DraftPage extends StatefulWidget {
  const DraftPage({super.key});

  @override
  State<DraftPage> createState() => _DraftPageState();
}

class _DraftPageState extends State<DraftPage> {
  static const Color _orangeColor = Color(0xFFFF6D00);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthController _authController = AuthController();
  final StudioController _studioController = StudioController();

  @override
  void initState() {
    super.initState();
    _syncDrafts();
  }

  Future<void> _syncDrafts() async {
    final userId = _authController.currentUser?.userId;
    if (userId != null) {
      await _studioController.syncMyArticles(userId);
    }
  }

  List<LocalDraft> _getMyArticles() {
    final currentUserId = _authController.currentUser?.userId;
    if (currentUserId == null) return [];

    final box = Hive.box<LocalDraft>('local_draft_box');

    return box.values.where((a) => a.userId == currentUserId).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  String _getAuthorName(String authorId) {
    final box = Hive.box<CachedUser>('cached_user_box');
    return box.get(authorId)?.name ?? 'Penulis';
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
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _orangeColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset('assets/Logo_VOP.png', height: 32),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Builder(
              builder: (context) {
                final avatarUrl = _authController.currentUser?.avatarUrl ?? '';
                return CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[700],
                  backgroundImage: avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl.isEmpty
                      ? const Icon(
                          Icons.person,
                          color: Colors.white70,
                          size: 20,
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),

      // --- PENAMBAHAN TOMBOL TULIS ARTIKEL DI SINI ---
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _orangeColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit, size: 18),
        label: const Text(
          'Tulis Artikel',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WriterPage()),
          );
        },
      ),

      // -----------------------------------------------
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
                  Text(
                    'Belum ada artikel',
                    style: TextStyle(color: Colors.white38, fontSize: 15),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: const Color(0xFFFF6D00),
            backgroundColor: const Color(0xFF1E1E1E),
            onRefresh: _syncDrafts,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                top: 4,
                bottom: 80,
              ), // bottom: 80 agar item terbawah tidak tertutup FAB
              itemCount: articles.length,
              itemBuilder: (ctx, i) {
                final draft = articles[i];
                return _DraftCard(
                  article: draft,
                  authorName: _getAuthorName(draft.userId),
                  dateStr: _formatDate(draft.updatedAt),
                  controller: _studioController,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _DraftCard extends StatefulWidget {
  final LocalDraft article;
  final String authorName;
  final String dateStr;
  final StudioController controller;

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

  static const Color _redColor = Color(0xFFE53935);
  static const Color _greenColor = Color(0xFF43A047);
  static const Color _orangeColor = Color(0xFFFF6D00);

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final isDropped =
        article.status == PostStatus.dropped ||
        article.status == PostStatus.archived;

    return GestureDetector(
      onTap: () {
        if (article.status == PostStatus.draft || article.status == PostStatus.rejected) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => WriterPage(draftId: article.localId)),
          );
        } else if (article.status == PostStatus.pending) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Artikel sedang direviu')),
          );
        } else if (article.status == PostStatus.published) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ArticlePage(articleId: article.localId)),
          );
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFF2A2A2A), width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.dateStr,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              article.title,
              style: TextStyle(
                color: isDropped ? Colors.white38 : Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _expanded ? 'Tutup Gambar' : 'Lihat Gambar',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white54,
                    size: 18,
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _expanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  if (article.imageUrls != null &&
                      article.imageUrls!.isNotEmpty)
                    ...article.imageUrls!.map((imgPath) {
                      final isNetwork = imgPath.startsWith('http');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: isNetwork
                                ? Image.network(
                                    imgPath,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (error, stackTrace, details) =>
                                            const Center(
                                              child: Icon(
                                                Icons.broken_image,
                                                color: Colors.white24,
                                                size: 40,
                                              ),
                                            ),
                                  )
                                : Image.file(File(imgPath), fit: BoxFit.cover),
                          ),
                        ),
                      );
                    })
                  else
                    Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: Colors.white24,
                          size: 40,
                        ),
                      ),
                    ),
                ],
              ),
              secondChild: const SizedBox.shrink(),
            ),
            if ((article.status == PostStatus.rejected ||
                    article.status == PostStatus.published) &&
                article.rejectionNote != null &&
                article.rejectionNote!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Komentar:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      article.rejectionNote!,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            _buildStatusRow(article),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(LocalDraft article) {
    switch (article.status) {
      case PostStatus.rejected:
        return Row(
          children: [
            _actionBtn(
              icon: Icons.edit,
              label: 'Edit',
              color: Colors.white,
              bgColor: const Color(0xFF2A2A2A),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WriterPage(draftId: article.localId),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _actionBtn(
              icon: Icons.delete_outline,
              label: 'Drop',
              color: Colors.white,
              bgColor: const Color(0xFF2A2A2A),
              onTap: () async {
                article.status = PostStatus.dropped;
                await Hive.box<LocalDraft>(
                  'local_draft_box',
                ).put(article.localId, article);
              },
            ),
            const Spacer(),
            _statusChip(
              icon: Icons.close,
              label: 'Ditolak',
              color: _redColor,
              filled: true,
            ),
          ],
        );
      case PostStatus.published:
        return Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.arrow_upward, color: _orangeColor, size: 14),
                  SizedBox(width: 6),
                  Text(
                    '300',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            _statusChip(
              icon: Icons.check,
              label: 'Terpublikasi',
              color: _greenColor,
              filled: true,
            ),
          ],
        );
      case PostStatus.dropped:
      case PostStatus.archived:
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _statusChip(
              icon: Icons.delete_outline,
              label: 'Dihapus',
              color: _redColor,
              filled: true,
            ),
          ],
        );
      case PostStatus.pending:
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _statusChip(
              icon: Icons.access_time,
              label: 'Menunggu Verifikasi',
              color: _orangeColor,
              filled: false,
            ),
          ],
        );
      case PostStatus.draft:
      default:
        return Row(
          children: [
            _actionBtn(
              icon: Icons.edit,
              label: 'Edit',
              color: Colors.white,
              bgColor: const Color(0xFF2A2A2A),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WriterPage(draftId: article.localId),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _actionBtn(
              icon: Icons.delete_outline,
              label: 'Drop',
              color: _redColor,
              bgColor: const Color(0xFF2A2A2A),
              onTap: () => widget.controller.deleteArticle(article.localId),
            ),
            const Spacer(),
            _statusChip(
              icon: Icons.edit_note,
              label: 'Draft',
              color: _orangeColor,
              filled: false,
            ),
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
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
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
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: filled ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: filled ? Colors.white : color, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: filled ? Colors.white : color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
