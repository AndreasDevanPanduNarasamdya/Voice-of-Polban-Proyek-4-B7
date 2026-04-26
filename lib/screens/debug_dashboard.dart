// import 'package:flutter/material.dart';
// import 'package:hive/hive.dart';

// import '../controllers/editor_controller.dart';
// import '../controllers/auth_controller.dart';
// import '../models/app_enums.dart';
// import '../models/article_model.dart';

// class DebugDashboard extends StatefulWidget {
//   const DebugDashboard({super.key});

//   @override
//   State<DebugDashboard> createState() => _DebugDashboardState();
// }

// class _DebugDashboardState extends State<DebugDashboard> {
//   final AuthController authController = AuthController();
//   final ArticleController articleController = ArticleController();

//   @override
//   void initState() {
//     super.initState();
//     _seedUsers();
//   }

//   Future<void> _seedUsers() async {
//     await authController.seedDummyUsers();
//     if (mounted) {
//       setState(() {});
//     }
//   }

//   void _loginAsWriter() {
//     authController.login('writer@polban.ac.id', 'password123');
//     setState(() {});
//   }

//   void _loginAsEditor() {
//     authController.login('editor@polban.ac.id', 'password123');
//     setState(() {});
//   }

//   void _loginAsReader() {
//     authController.login('reader@polban.ac.id', 'password123');
//     setState(() {});
//   }

//   void _writeDraft() {
//     final currentUser = authController.currentUser;
//     if (currentUser == null) {
//       _showMessage('Login first before writing a draft.');
//       return;
//     }

//     articleController.saveDraft(
//       'Demo Draft Title',
//       'This is a dummy draft created from the debug dashboard.',
//       ArticleCategory.akademik,
//       currentUser.id,
//     );

//     _showMessage('Draft saved for ${currentUser.name}.');
//   }

//   void _getOfflineArticles() {
//     final articles = articleController.getLatestArticlesByCategory(
//       ArticleCategory.akademik,
//     );
//     final titles = articles.map((article) => article.title).toList();

//     // ignore: avoid_print
//     print('Akademik articles count: ${articles.length}');
//     // ignore: avoid_print
//     print('Akademik article titles: $titles');

//     _showMessage('Akademik articles: ${articles.length}');
//   }

//   ArticleModel? _getFirstArticle() {
//     final box = Hive.box<ArticleModel>('articles_box');
//     if (box.isEmpty) {
//       return null;
//     }

//     return box.values.first;
//   }

//   void _submitDraft() {
//     final article = _getFirstArticle();
//     if (article == null) {
//       _showMessage('No article available to submit.');
//       return;
//     }

//     articleController.submitDraft(article.id);
//     _showMessage('Submitted article: ${article.title}');
//   }

//   void _approveArticle() {
//     final article = _getFirstArticle();
//     if (article == null) {
//       _showMessage('No article available to approve.');
//       return;
//     }

//     articleController.approveArticle(article.id);
//     _showMessage('Approved article: ${article.title}');
//   }

//   void _publishArticle() {
//     final article = _getFirstArticle();
//     if (article == null) {
//       _showMessage('No article available to publish.');
//       return;
//     }

//     articleController.publishArticle(article.id);
//     _showMessage('Published article: ${article.title}');
//   }

//   void _archiveArticle() {
//     final article = _getFirstArticle();
//     if (article == null) {
//       _showMessage('No article available to archive.');
//       return;
//     }

//     articleController.archiveArticle(article.id);
//     _showMessage('Archived article: ${article.title}');
//   }

//   void _logout() {
//     authController.logout();
//     setState(() {});
//     _showMessage('Logged out.');
//   }

//   void _showMessage(String message) {
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text(message)));
//   }

//   String _currentUserLabel() {
//     final currentUser = authController.currentUser;
//     if (currentUser == null) {
//       return 'Current user: None';
//     }

//     return 'Current user: ${currentUser.name} (${currentUser.role.name})';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('VOP Prototype')),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           Text(
//             _currentUserLabel(),
//             style: Theme.of(context).textTheme.titleMedium,
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: _loginAsWriter,
//             child: const Text('Login as Writer'),
//           ),
//           const SizedBox(height: 8),
//           ElevatedButton(
//             onPressed: _loginAsEditor,
//             child: const Text('Login as Editor'),
//           ),
//           const SizedBox(height: 8),
//           ElevatedButton(
//             onPressed: _loginAsReader,
//             child: const Text('Login as Reader'),
//           ),
//           const SizedBox(height: 8),
//           ElevatedButton(
//             onPressed: _writeDraft,
//             child: const Text('Write Draft'),
//           ),
//           const SizedBox(height: 8),
//           ElevatedButton(
//             onPressed: _submitDraft,
//             child: const Text('Submit Draft'),
//           ),
//           const SizedBox(height: 8),
//           ElevatedButton(
//             onPressed: _approveArticle,
//             child: const Text('Approve Article'),
//           ),
//           const SizedBox(height: 8),
//           ElevatedButton(
//             onPressed: _publishArticle,
//             child: const Text('Publish Article'),
//           ),
//           const SizedBox(height: 8),
//           ElevatedButton(
//             onPressed: _archiveArticle,
//             child: const Text('Archive Article'),
//           ),
//           const SizedBox(height: 8),
//           ElevatedButton(onPressed: _logout, child: const Text('Logout')),
//           const SizedBox(height: 8),
//           ElevatedButton(
//             onPressed: _getOfflineArticles,
//             child: const Text('Get Offline Articles (Akademik)'),
//           ),
//         ],
//       ),
//     );
//   }
// }
