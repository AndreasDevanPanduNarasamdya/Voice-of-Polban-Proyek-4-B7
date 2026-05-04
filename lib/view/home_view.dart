import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart'; // Used for formatting real dates
import '../models/article_model.dart';
import '../models/user_model.dart';
import '../models/app_enums.dart';
import '../controller/article_controller.dart';
import '../auth/auth_service.dart';
import 'package:voice_of_polban/view/sidebar.dart';
import 'article_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  late final ArticleController _controller;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = ArticleController(authService: _authService);
  }

  String _getAuthorName(String authorId) {
    final user = Hive.box<UserModel>('user_box').get(authorId);
    return user?.name ?? "Penulis Tidak Diketahui";
  }

  @override
  Widget build(BuildContext context) {
    // 1. REACTIVE SESSION: Listens to logins/logouts instantly
    return ValueListenableBuilder<Box>(
      valueListenable: Hive.box('session_box').listenable(),
      builder: (context, sessionBox, _) {
        final currentUserRole = _authService.getCurrentUserRole();

        return Scaffold(
          backgroundColor: Colors.black, // Dark Theme
          drawer: AppSidebar(currentUserRole: currentUserRole),
          appBar: AppBar(
            backgroundColor: const Color(0xFF121212),
            elevation: 0,
            iconTheme: const IconThemeData(color: Color(0xFFFF8C00)),
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

          // 2. REACTIVE FEED: Listens to new articles/publications instantly
          body: ValueListenableBuilder<Box<ArticleModel>>(
            valueListenable: Hive.box<ArticleModel>('article_box').listenable(),
            builder: (context, articlesBox, _) {
              // The controller fetches the FRESH data every time the box changes
              final feedData = _controller.getLatestArticles();

              if (feedData.isEmpty) {
                return const Center(
                  child: Text(
                    "Belum ada artikel yang dipublikasikan.",
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              return ListView.builder(
                itemCount: feedData.length,
                itemBuilder: (context, index) {
                  return _buildArticleCard(context, feedData[index]);
                },
              );
            },
          ),

          bottomNavigationBar: Container(
            color: const Color(0xFF121212),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(Icons.emoji_events_outlined, "Akademik", 0),
                _buildNavItem(Icons.school_outlined, "Kampus", 1),
                _buildNavItem(Icons.calendar_today_outlined, "Acara", 2),
                _buildNavItem(Icons.people_outline, "Organisasi", 3),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? const Color(0xFFFF8C00) : Colors.grey;
    return InkWell(
      onTap: () {
        setState(() => _selectedIndex = index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, ArticleModel article) {
    final dateString = DateFormat(
      'EEEE, dd MMMM yyyy',
    ).format(article.createdAt);

    final authorName = _getAuthorName(article.authorId);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticlePage(articleId: article.articleId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        color: const Color(0xFF121212),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 12,
                    backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/100?img=11',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    authorName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateString,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                article.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 250,
              width: double.infinity,
              color: const Color(0xFF2A2A2A),
              child: const Center(
                child: Icon(Icons.image, color: Colors.grey, size: 50),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildInteractionPill(Icons.chat_bubble_outline, "30"),
                  const SizedBox(width: 12),
                  _buildInteractionPillGroup(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionPill(IconData icon, String count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 16),
          const SizedBox(width: 6),
          Text(
            count,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionPillGroup() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: const [
          Icon(Icons.arrow_upward, color: Color(0xFFFF8C00), size: 16),
          SizedBox(width: 4),
          Text(
            "300",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 12),
          Icon(Icons.arrow_downward, color: Color(0xFF000080), size: 16),
          SizedBox(width: 4),
          Text(
            "300",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 12),
          Icon(Icons.bookmark_border, color: Colors.grey, size: 16),
        ],
      ),
    );
  }
}