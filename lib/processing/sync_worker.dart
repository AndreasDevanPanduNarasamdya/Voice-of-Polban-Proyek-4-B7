import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../storage/sync_queue.dart';
import '../api/feed_repository.dart';

class SyncWorker {
  static final SyncWorker _instance = SyncWorker._internal();
  factory SyncWorker() => _instance;
  SyncWorker._internal();

  static const String _queueBoxName = 'sync_queue_box';
  final FeedRepository _feedRepository = FeedRepository();

  // --- ADDED FOR TESTABILITY ---
  @visibleForTesting
  Box<SyncQueue>? mockBox;

  @visibleForTesting
  SupabaseClient? mockSupabase;
  // -----------------------------

  Box<SyncQueue> get _queueBox => mockBox ?? Hive.box<SyncQueue>(_queueBoxName);

  // Use the getter so we can intercept it in tests
  SupabaseClient get _supabase => mockSupabase ?? Supabase.instance.client;

  String? get _currentUserId {
    try {
      // Use Hive.isBoxOpen to prevent crashes if the worker fires before init
      if (Hive.isBoxOpen('session_box')) {
        final sessionBox = Hive.box('session_box');
        final userId = sessionBox.get('logged_in_user_id');
        if (userId != null) return userId.toString();
      }
      return _supabase.auth.currentUser?.id;
    } catch (_) {
      return _supabase.auth.currentUser?.id;
    }
  }

  int get pendingQueueLength =>
      _queueBox.values.where((entry) => !entry.isProcessed).length;

  Future<void> processSyncQueue() async {
    final pendingTasks = _queueBox.values
        .where((entry) => !entry.isProcessed)
        .toList();

    if (pendingTasks.isEmpty) return;

    for (final task in pendingTasks) {
      try {
        final payload = jsonDecode(task.payload);

        // Change 'supabase' to '_supabase' here to use our testable getter
        if (task.actionType == 'UPLOAD_DRAFT') {
          await _supabase.from('posts').upsert({
            'post_id': payload['postId'],
            'title': payload['title'],
            'content': payload['content'],
            'author_id': payload['userId'],
            'status': payload['status'],
          });
        } else if (task.actionType == 'UPDATE_DRAFT') {
          await _supabase
              .from('posts')
              .update({
                'title': payload['title'],
                'content': payload['content'],
              })
              .eq('post_id', payload['postId']);
        } else if (task.actionType == 'DELETE_POST') {
          await _supabase
              .from('posts')
              .delete()
              .eq('post_id', payload['postId']);
        }

        task.isProcessed = true;
        await _queueBox.put(task.queueId, task);
        debugPrint('Successfully synced offline task: ${task.actionType}');
      } catch (e) {
        debugPrint('Sync task failed (still offline?): $e');
      }
    }
  }

  Future<void> syncLiveVoteCount(String postId) async {
    // Ambil ID user yang sedang login menggunakan getter milik SyncWorker
    final userId = _currentUserId ?? '';

    // Panggil fungsi internal yang sudah dipublikasikan di FeedRepository
    await _feedRepository.refreshCachedPostVoteState(
      postId: postId,
      userId: userId,
    );
  }
}
