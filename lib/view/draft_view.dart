import 'package:flutter/material.dart';
import '../models/app_enums.dart';

// Alias lokal untuk kemudahan baca
typedef DraftStatus = ArticleStatus;

class DraftArticle {
  final String author;
  final String date;
  final String title;
  final String? rejectionNote;
  final int? upvotes;
  final DraftStatus status;

  const DraftArticle({
    required this.author,
    required this.date,
    required this.title,
    this.rejectionNote,
    this.upvotes,
    required this.status,
  });
}

final List<DraftArticle> sampleDrafts = [
  DraftArticle(
    author: 'Richard Joe',
    date: 'Senin, 24 Agustus 2025',
    title: 'HMHTK Mempersembahkan Explore 2025 Event',
    rejectionNote: 'Tidak sesuai dengan kaidah kebahasaan indonesia',
    status: ArticleStatus.rejected,
  ),
  DraftArticle(
    author: 'Richard Joe',
    date: 'Senin, 24 Agustus 2025',
    title: 'Polban Perkuat Implementasi SDGs Melalui Lomba Berbasis Keberlanjutan',
    upvotes: 300,
    status: ArticleStatus.published,
  ),
  DraftArticle(
    author: 'Richard Joe',
    date: 'Senin, 24 Agustus 2025',
    title: 'Cara mudah mengatasi insomnia akibat SKS',
    status: ArticleStatus.archived,
  ),
];

class DraftPage extends StatefulWidget {
  const DraftPage({super.key});

  @override
  State<DraftPage> createState() => _DraftPageState();
}

class _DraftPageState extends State<DraftPage> {
  static const Color _bgColor      = Color(0xFF1A1A1A);
  static const Color _cardColor    = Color(0xFF232323);
  static const Color _orangeColor  = Color(0xFFFF6D00);
  static const Color _redColor     = Color(0xFFE53935);
  static const Color _greenColor   = Color(0xFF43A047);
  static const Color _dividerColor = Color(0xFF333333);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 26),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
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
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: sampleDrafts.length,
        itemBuilder: (ctx, i) => _buildDraftCard(ctx, sampleDrafts[i]),
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

  Widget _buildDraftCard(BuildContext context, DraftArticle draft) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
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
                Text(draft.author,
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(width: 8),
                Text(draft.date,
                    style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),

            // Judul
            Text(
              draft.title,
              style: const TextStyle(
                  color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Lihat gambar
            Center(
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.keyboard_arrow_down,
                    color: Colors.white54, size: 18),
                label: const Text('Lihat Gambar',
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
              ),
            ),

            // Konten berdasarkan status
            if (draft.status == ArticleStatus.rejected) ...[
              // Kotak komentar penolakan
              if (draft.rejectionNote != null) ...[
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
                      Text(draft.rejectionNote!,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Tombol Edit, Drop, Ditolak
              Row(
                children: [
                  _actionBtn(
                    icon: Icons.edit,
                    label: 'Edit',
                    color: Colors.white,
                    bgColor: const Color(0xFF333333),
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  _actionBtn(
                    icon: Icons.delete,
                    label: 'Drop',
                    color: _redColor,
                    bgColor: const Color(0xFF333333),
                    onTap: () {},
                  ),
                  const Spacer(),
                  _statusChip(
                    icon: Icons.close,
                    label: 'Ditolak',
                    color: _redColor,
                  ),
                ],
              ),
            ] else if (draft.status == ArticleStatus.published) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  // Upvote
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF333333),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_upward,
                            color: Color(0xFFFF6D00), size: 16),
                        const SizedBox(width: 6),
                        Text('${draft.upvotes ?? 0}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14)),
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
            ] else if (draft.status == ArticleStatus.archived) ...[
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