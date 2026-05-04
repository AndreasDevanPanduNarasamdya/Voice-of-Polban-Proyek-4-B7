import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../auth/auth_controller.dart';
import '../controller/post_controller.dart';
import '../models/cached_post.dart';
import '../models/local_draft.dart';
import '../models/sync_queue.dart';

class DebugDashboard extends StatefulWidget {
  const DebugDashboard({super.key});

  @override
  State<DebugDashboard> createState() => _DebugDashboardState();
}

class _DebugDashboardState extends State<DebugDashboard> {
  final AuthController _authController = AuthController();
  final PostController _postController = PostController();

  LocalDraft? _lastDraft;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _authController.seedDummyUsers();
    await _seedCachedPosts();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _seedCachedPosts() async {
    final box = Hive.box<CachedPost>('cached_post_box');
    if (box.isNotEmpty) {
      return;
    }

    await box.put(
      'cached-post-1',
      CachedPost(
        postId: 'cached-post-1',
        cachedData: '{"title":"Offline post 1","body":"Cached for debug"}',
        cachedAt: DateTime.now(),
      ),
    );
    await box.put(
      'cached-post-2',
      CachedPost(
        postId: 'cached-post-2',
        cachedData: '{"title":"Offline post 2","body":"Cached for debug"}',
        cachedAt: DateTime.now(),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _log(String message) {
    debugPrint(message);
    _showMessage(message);
  }

  void _loginWriter() {
    final user = _authController.login('writer@polban.ac.id', 'password123');
    if (user == null) {
      _log('Writer login failed.');
      return;
    }

    setState(() {});
    _log('Logged in: ${user.name} (${user.role.name})');
  }

  void _writeLocalDraft() {
    final currentUser = _authController.currentUser;
    if (currentUser == null) {
      _log('Login writer first.');
      return;
    }

    final draft = _postController.saveDraft(
      'Local draft from dashboard',
      'This draft was created while offline.',
      currentUser.userId,
    );

    setState(() {
      _lastDraft = draft;
    });

    _log('Draft saved: ${draft.localId}');
  }

  void _submitDraftToQueue() {
    final draft =
        _lastDraft ??
        (Hive.box<LocalDraft>('local_draft_box').values.isNotEmpty
            ? Hive.box<LocalDraft>('local_draft_box').values.last
            : null);

    if (draft == null) {
      _log('No draft available to submit.');
      return;
    }

    final queueEntry = _postController.submitDraft(draft.localId);
    if (queueEntry == null) {
      _log('Draft not found in local box.');
      return;
    }

    setState(() {
      _lastDraft = _postController.getDraftById(draft.localId);
    });

    _log(
      'Queued draft. Pending queue length: ${_postController.pendingQueueLength}',
    );
  }

  void _getCachedPosts() {
    final posts = _postController.getOfflinePosts();
    final message = 'Cached posts: ${posts.length}';
    debugPrint(message);
    for (final post in posts) {
      debugPrint(' - ${post.postId}: ${post.cachedData}');
    }
    _showMessage(message);
  }

  void _logout() {
    final user = _authController.logout();
    setState(() {});
    _log(user == null ? 'Logged out.' : 'Logged out: ${user.name}');
  }

  String _currentUserLabel() {
    final currentUser = _authController.currentUser;
    if (currentUser == null) {
      return 'Current user: None';
    }

    return 'Current user: ${currentUser.name} (${currentUser.role.name})';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF15161A),
        title: const Text('Voice of Polban Debug Dashboard'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _currentUserLabel(),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Draft in queue: ${_postController.pendingQueueLength}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loginWriter,
            child: const Text('Login Writer'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _writeLocalDraft,
            child: const Text('Write Local Draft'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _submitDraftToQueue,
            child: const Text('Submit Draft to Queue'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _getCachedPosts,
            child: const Text('Get Cached Posts'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _logout, child: const Text('Logout')),
          const SizedBox(height: 16),
          ValueListenableBuilder<Box<SyncQueue>>(
            valueListenable: Hive.box<SyncQueue>('sync_queue_box').listenable(),
            builder: (context, queueBox, _) {
              return Text(
                'Queue entries: ${queueBox.length}',
                style: const TextStyle(color: Colors.white70),
              );
            },
          ),
        ],
      ),
    );
  }
}
