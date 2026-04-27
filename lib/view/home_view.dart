import 'package:flutter/material.dart';
import 'package:voice_of_polban/view/article_view.dart';

class ArticleModel {
  final String title;
  final String description;
  final String author;
  final String date;
  final String? imageUrl;
  final String category;
  final String content;

  const ArticleModel({
    required this.title,
    required this.description,
    required this.author,
    required this.date,
    this.imageUrl,
    required this.category,
    required this.content,
  });
}

final List<ArticleModel> dummyArticles = [
  ArticleModel(
    title: 'HVHTK Mempersembahkan Explore 2025 Event',
    description: 'Event tahunan Explore 2025 hadir kembali dengan berbagai kegiatan menarik.',
    author: 'Ahmad Loe',
    date: '24 Agustus 2025',
    category: 'Event',
    content:
        'HVHTK kembali mempersembahkan Explore 2025, sebuah event tahunan yang dinantikan oleh seluruh civitas akademika Polban. Event ini menampilkan berbagai kegiatan menarik mulai dari pameran karya mahasiswa hingga pertunjukan seni budaya.',
  ),
  ArticleModel(
    title: 'Polban Perkuat Implementasi SDGs Melalui Lomba Berbasis Keberlanjutan',
    description: 'Polban mengadakan lomba inovasi berbasis SDGs untuk mahasiswa.',
    author: 'Siti Lae',
    date: '30 Agustus 2025',
    category: 'Lomba',
    content:
        'Dalam rangka memperkuat komitmen terhadap Sustainable Development Goals (SDGs), Polban menyelenggarakan serangkaian lomba inovasi yang mendorong mahasiswa untuk berpikir kreatif dan berkelanjutan.',
  ),
  ArticleModel(
    title: 'Cara mudah mengatasi Insomnia akibat SKS',
    description: 'Tips ampuh mengatasi insomnia bagi mahasiswa yang sering begadang.',
    author: 'Charelin',
    date: '31 Agustus 2025',
    category: 'Umum',
    content:
        'Insomnia akibat sistem kebut semalam (SKS) menjadi masalah umum di kalangan mahasiswa. Berikut beberapa tips yang bisa membantu kamu mendapatkan tidur berkualitas meski di tengah padatnya jadwal kuliah.',
  ),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedCategory = 0;
  int _selectedNav = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const Color _bgColor      = Color(0xFF1A1A2E);
  static const Color _cardColor    = Color(0xFF16213E);
  static const Color _accentColor  = Color(0xFF0F3460);
  static const Color _highlightColor = Color(0xFFE94560);

  final List<String> _categories = ['Semua', 'Umum', 'Lomba', 'Event', 'Ormawa'];

  List<ArticleModel> get _filteredArticles {
    if (_selectedCategory == 0) return dummyArticles;
    final cat = _categories[_selectedCategory];
    return dummyArticles.where((a) => a.category == cat).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bgColor,
      drawer: _buildDrawer(),

      // ── Bottom navbar: STICKY di bawah layar, tidak ikut scroll ──
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: _cardColor,
          border: Border(top: BorderSide(color: _accentColor, width: 1)),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          selectedItemColor: _highlightColor,
          unselectedItemColor: Colors.white38,
          currentIndex: _selectedNav,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: (i) => setState(() => _selectedNav = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.language), label: 'Umum'),
            BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Lomba'),
            BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Event'),
            BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Ormawa'),
          ],
        ),
      ),

      // ── Body: CustomScrollView agar AppBar & filter ikut scroll ──
      body: CustomScrollView(
        slivers: [
          // AppBar yang ikut scroll ke atas saat user scroll
          SliverAppBar(
            backgroundColor: _cardColor,
            floating: true,   // muncul kembali saat scroll ke atas
            snap: true,        // langsung muncul penuh (tidak setengah)
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: _highlightColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.campaign, color: Colors.white, size: 15),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Voice of Polban',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            centerTitle: true,
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.account_circle, color: Colors.white, size: 28),
              ),
            ],
            // Filter kategori menempel di bawah AppBar, ikut scroll juga
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(46),
              child: Container(
                color: _cardColor,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: List.generate(_categories.length, (i) {
                      final sel = i == _selectedCategory;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = i),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 5),
                          decoration: BoxDecoration(
                            color: sel ? _highlightColor : _accentColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _categories[i],
                            style: TextStyle(
                              color: sel ? Colors.white : Colors.white70,
                              fontWeight:
                                  sel ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),

          // Konten berita
          _filteredArticles.isEmpty
              ? const SliverFillRemaining(child: _EmptyState())
              : SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) =>
                          _buildArticleCard(ctx, _filteredArticles[i]),
                      childCount: _filteredArticles.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, ArticleModel article) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ArticlePage(article: article)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _accentColor.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: article.imageUrl != null
                  ? Image.network(
                      article.imageUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imgPlaceholder(),
                    )
                  : _imgPlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge kategori
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _highlightColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: _highlightColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      article.category,
                      style: const TextStyle(
                          color: _highlightColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(article.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(article.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 13)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          color: Colors.white38, size: 14),
                      const SizedBox(width: 4),
                      Text(article.author,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12)),
                      const SizedBox(width: 12),
                      const Icon(Icons.calendar_today_outlined,
                          color: Colors.white38, size: 12),
                      const SizedBox(width: 4),
                      Text(article.date,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12)),
                      const Spacer(),
                      _iconBtn(Icons.bookmark_border, () {}),
                      _iconBtn(Icons.share_outlined, () {}),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
        height: 180,
        width: double.infinity,
        color: _accentColor,
        child: const Center(
          child: Icon(Icons.image_outlined, color: Colors.white24, size: 48),
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

  Widget _buildDrawer() => Drawer(
        backgroundColor: _cardColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: _accentColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.account_circle, color: Colors.white, size: 52),
                  SizedBox(height: 10),
                  Text('Voice of Polban',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            _drawerItem(Icons.home, 'Beranda', () => Navigator.pop(context)),
            _drawerItem(Icons.language, 'Umum', () => Navigator.pop(context)),
            _drawerItem(Icons.emoji_events, 'Lomba', () => Navigator.pop(context)),
            _drawerItem(Icons.event, 'Event', () => Navigator.pop(context)),
            _drawerItem(Icons.group, 'Ormawa', () => Navigator.pop(context)),
            const Divider(color: Colors.white12),
            _drawerItem(Icons.settings, 'Pengaturan', () => Navigator.pop(context)),
          ],
        ),
      );

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap) =>
      ListTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(label, style: const TextStyle(color: Colors.white70)),
        onTap: onTap,
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, color: Colors.white24, size: 64),
          SizedBox(height: 16),
          Text('Belum ada berita',
              style: TextStyle(color: Colors.white38, fontSize: 16)),
        ],
      ),
    );
  }
}