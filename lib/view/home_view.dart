import 'package:flutter/material.dart';
import '../models/article_model.dart';
import '../controller/article_controller.dart';
import 'package:voice_of_polban/view/sidebar.dart';
import 'article_view.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/app_enums.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ArticleController _controller = ArticleController();
  late List<ArticleModel> _feedData;
  UserRole _currentUserRole = UserRole.reader;

  @override
  void initState() {
    super.initState();
    _feedData = _controller.getLatestArticles();

    final sessionBox = Hive.box('session_box');
    final loggedInName = sessionBox.get('logged_in_user');
    final usersBox = Hive.box<UserModel>('users_box');
    for (final user in usersBox.values) {
      if (user.name == loggedInName) {
        _currentUserRole = user.role;
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppSidebar(currentUserRole: _currentUserRole),
      appBar: AppBar(
        title: const Text("HEADER"),
        centerTitle: true,
        actions: const [Icon(Icons.account_circle), SizedBox(width: 16)],
      ),
      body: _feedData.isEmpty
          ? const Center(child: Text("Belum ada artikel yang dipublikasikan."))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _feedData.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildArticleCard(context, _feedData[index]),
                );
              },
            ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            Icon(Icons.language, size: 40), //Kategori Umum
            Icon(Icons.emoji_events_sharp, size: 40), // Kategori Lomba
            Icon(Icons.event, size: 40), //Kategori Event
            Icon(Icons.group, size: 40), //Kategori Ormawa
          ],
        ),
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, ArticleModel article) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArticlePage(articleId: article.id),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 150,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                  ),
                  child: const Text("GAMBAR"),
                ),
                Container(
                  height: 80,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Text(
                    article.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Text(article.content),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.bookmark_border),
                  onPressed: () {},
                ),
                IconButton(icon: const Icon(Icons.share), onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
