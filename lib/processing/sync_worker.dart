import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../storage/sync_queue.dart';

class SyncWorker {
  // --- 1. ADD THIS SINGLETON PATTERN ---
  static final SyncWorker _instance = SyncWorker._internal();
  factory SyncWorker() => _instance;
  SyncWorker._internal();

  static const String _queueBoxName = 'sync_queue_box';

  Box<SyncQueue> get _queueBox => Hive.box<SyncQueue>(_queueBoxName);

  int get pendingQueueLength =>
      _queueBox.values.where((entry) => !entry.isProcessed).length;

  Future<void> processSyncQueue() async {
    final pendingTasks = _queueBox.values
        .where((entry) => !entry.isProcessed)
        .toList();

    if (pendingTasks.isEmpty) return;

    final supabase = Supabase.instance.client;

    for (final task in pendingTasks) {
      try {
        final payload = jsonDecode(task.payload);

        if (task.actionType == 'UPLOAD_DRAFT') {
          await supabase.from('posts').upsert({
            'post_id': payload['postId'],
            'title': payload['title'],
            'content': payload['content'],
            'author_id': payload['userId'],
            'status': payload['status'],
          });
        } else if (task.actionType == 'UPDATE_DRAFT') {
          await supabase
              .from('posts')
              .update({
                'title': payload['title'],
                'content': payload['content'],
              })
              .eq('post_id', payload['postId']);
        } else if (task.actionType == 'DELETE_POST') {
          await supabase
              .from('posts')
              .delete()
              .eq('post_id', payload['postId']);
        }

        task.isProcessed = true;
        await _queueBox.put(task.queueId, task);
        debugPrint('Successfully synced offline task: ${task.actionType}');
      } catch (e) {
        // Still offline — leave isProcessed = false to retry next time
        debugPrint('Sync task failed (still offline?): $e');
      }
    }
  }
}
