import 'dart:io';
import 'package:flutter/material.dart';
import 'package:voice_of_polban/view/article_view.dart';
import 'package:voice_of_polban/controller/home_controller.dart';
import 'package:voice_of_polban/models/article_model.dart'; // ← Change 1a: new import

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  final HomeController _controller = HomeController();
  late List<ArticleModel> _feedData; // ← Change 1b: variable type

  @override
  void initState() {
    super.initState();
    _feedData = _controller.loadFeedData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.menu),
        title: const Text("HEADER"),
        centerTitle: true,
        actions: const [Icon(Icons.account_circle), SizedBox(width: 16)],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _feedData.length,
        itemBuilder: (context, index) {
          final articleData = _feedData[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _buildPlaceholderCard(context, articleData),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            Icon(Icons.circle, size: 40),
            Icon(Icons.circle, size: 40),
            Icon(Icons.circle, size: 40),
            Icon(Icons.circle, size: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderCard(BuildContext context, ArticleModel article) {
    // ← Change 2: parameter type
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArticlePage(
                    articleId: article.id,
                  ), // ← Change 3: dot notation
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
                  child: Text("article.image"),
                ),
                Container(
                  height: 80,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Text(
                    article.title, // ← Change 4b
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Text(article.content), // ← Change 4c
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
