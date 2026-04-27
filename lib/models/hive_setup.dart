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
import 'package:voice_of_polban/models/app_enums.dart';

Future<void> setupHive() async {
  await Hive.initFlutter();

  await Hive.openBox('session_box');

  Hive.registerAdapter(UserRoleAdapter());
  Hive.registerAdapter(ArticleStatusAdapter());

  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(ArticleModelAdapter());
  Hive.registerAdapter(SectionModelAdapter());
  Hive.registerAdapter(CommentModelAdapter());
  Hive.registerAdapter(AttachmentModelAdapter());
  Hive.registerAdapter(RevisionHistoryModelAdapter());
  Hive.registerAdapter(ArticleCacheModelAdapter());
  Hive.registerAdapter(VoteModelAdapter());
  Hive.registerAdapter(BookmarkModelAdapter());
  Hive.registerAdapter(NotificationModelAdapter());
  Hive.registerAdapter(LocalDraftModelAdapter());
  Hive.registerAdapter(SyncQueueModelAdapter());

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
