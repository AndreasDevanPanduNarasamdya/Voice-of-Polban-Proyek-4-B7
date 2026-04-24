import 'package:flutter/material.dart';
import '../models/article_model.dart';
import '../controller/article_controller.dart';

class ArticlePage extends StatefulWidget {
  final String articleId;
  const ArticlePage({super.key, required this.articleId});

  @override
  State<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends State<ArticlePage> {
  final ArticleController _controller = ArticleController();
  late final ArticleModel? _article;

  @override
  void initState() {
    super.initState();
    _article = _controller.getArticle(widget.articleId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("HEADER"),
        centerTitle: true,
      ),
      body: _article == null
          ? const Center(child: Text("Artikel tidak ditemukan atau telah dihapus."))
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(_article!.title, textAlign: TextAlign.left, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 8),
                Text("Kategori: ${_article.category.name}", textAlign: TextAlign.left, style: const TextStyle(fontSize: 19)),
                const SizedBox(height: 16),
                Text("Penulis: ${_article.authorId}", textAlign: TextAlign.left),
                const SizedBox(height: 24),
                Container(
                  height: 250,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
                  child: const Text("GAMBAR", style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(height: 24),
                Text(_article!.content, textAlign: TextAlign.left, style: const TextStyle(fontSize: 14)),
              ],
            ),
    );
  }
}