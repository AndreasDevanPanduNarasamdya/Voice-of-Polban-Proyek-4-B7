import 'package:hive_flutter/hive_flutter.dart';

import 'article_cache_model.dart';
import 'article_model.dart';
import 'attachment_model.dart';
import 'bookmark_model.dart';
import 'comment_model.dart';
import 'local_draft_model.dart';
import 'notification_model.dart';
import 'revision_history_model.dart';
import 'section_model.dart';
import 'sync_queue_model.dart';
import 'user_model.dart';
import 'vote_model.dart';

Future<void> setupHive() async {
  await Hive.initFlutter();

  await Hive.deleteBoxFromDisk('users_box');
  await Hive.deleteBoxFromDisk('articles_box');
  await Hive.openBox('session_box');

  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(SectionModelAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(UserModelAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(ArticleModelAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(CommentModelAdapter());
  }
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(AttachmentModelAdapter());
  }
  if (!Hive.isAdapterRegistered(6)) {
    Hive.registerAdapter(RevisionHistoryModelAdapter());
  }
  if (!Hive.isAdapterRegistered(7)) {
    Hive.registerAdapter(ArticleCacheModelAdapter());
  }
  if (!Hive.isAdapterRegistered(8)) {
    Hive.registerAdapter(VoteModelAdapter());
  }
  if (!Hive.isAdapterRegistered(9)) {
    Hive.registerAdapter(BookmarkModelAdapter());
  }
  if (!Hive.isAdapterRegistered(10)) {
    Hive.registerAdapter(NotificationModelAdapter());
  }
  if (!Hive.isAdapterRegistered(11)) {
    Hive.registerAdapter(LocalDraftModelAdapter());
  }
  if (!Hive.isAdapterRegistered(12)) {
    Hive.registerAdapter(SyncQueueModelAdapter());
  }

  await Hive.openBox<SectionModel>('section_box');
  await Hive.openBox<UserModel>('user_box');
  await Hive.openBox<ArticleModel>('article_box');
  await Hive.openBox<CommentModel>('comment_box');
  await Hive.openBox<AttachmentModel>('attachment_box');
  await Hive.openBox<RevisionHistoryModel>('revision_history_box');
  await Hive.openBox<ArticleCacheModel>('article_cache_box');
  await Hive.openBox<VoteModel>('vote_box');
  await Hive.openBox<BookmarkModel>('bookmark_box');
  await Hive.openBox<NotificationModel>('notification_box');
  await Hive.openBox<LocalDraftModel>('local_draft_box');
  await Hive.openBox<SyncQueueModel>('sync_queue_box');
}
