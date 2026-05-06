import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../models/article_model.dart';
import '../models/user_model.dart';
import '../models/app_enums.dart';
import '../controller/article_controller.dart';
import '../auth/auth_service.dart';
import 'article_view.dart';

class MyArticlesPage extends StatefulWidget {
  const MyArticlesPage({super.key});

  @override
  State<MyArticlesPage> createState() => _MyArticlesPageState();
}

class _MyArticlesPageState extends State<MyArticlesPage> {
  final AuthService _authService = AuthService();
  late final ArticleController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ArticleController(authService: _authService);
  }

  String _getAuthorName(String authorId) {
    final user = Hive.box<UserModel>('user_box').get(authorId);
    return user?.name ?? "Penulis Tidak Diketahui";
  }

  Widget _buildArticleCard(BuildContext context, ArticleModel article) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticlePage(articleId: article.articleId),
          ),
        );
      },
      child: Card(
        color: const Color(0xFF1E1E1E),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Thumbnail
              if (article.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: Image.memory(
                      base64Decode(article.imageUrl!.split(',').last),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              const SizedBox(width: 12),
              // Article Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Penulis: ${_getAuthorName(article.authorId)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      'Dibuat: ${DateFormat('dd MMM yyyy').format(article.createdAt)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: article.status == ArticleStatus.published
                            ? Colors.green.shade900
                            : Colors.orange.shade900,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        article.status.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authService.getCurrentUserId();
    if (currentUserId == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('Anda belum login.', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Artikel Saya', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFFF8C00)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ValueListenableBuilder<Box<ArticleModel>>(
        valueListenable: Hive.box<ArticleModel>('article_box').listenable(),
        builder: (context, articlesBox, _) {
          final myArticles = _controller.getArticlesByAuthor(currentUserId);

          if (myArticles.isEmpty) {
            return const Center(
              child: Text(
                "Anda belum memiliki artikel.",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            itemCount: myArticles.length,
            itemBuilder: (context, index) {
              return _buildArticleCard(context, myArticles[index]);
            },
          );
        },
      ),
    );
  }
}