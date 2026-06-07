import 'package:hive_flutter/hive_flutter.dart';
import '../config/app_enums.dart';
import 'cached_user.dart';
import 'cached_post.dart';
import 'local_draft.dart';
import 'local_bookmark.dart';
import 'local_vote.dart';
import 'sync_queue.dart';

Future<void> setupHive() async {
  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(LocalDraftAdapter());
  }
  if (!Hive.isAdapterRegistered(8)) {
    Hive.registerAdapter(UserRoleAdapter());
  }
  if (!Hive.isAdapterRegistered(9)) {
    Hive.registerAdapter(PostStatusAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(CachedPostAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(SyncQueueAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(LocalVoteAdapter());
  }
  if (!Hive.isAdapterRegistered(6)) {
    Hive.registerAdapter(LocalBookmarkAdapter());
  }
  if (!Hive.isAdapterRegistered(7)) {
    Hive.registerAdapter(CachedUserAdapter());
  }

  if (!Hive.isBoxOpen('local_draft_box')) {
    await Hive.openBox<LocalDraft>('local_draft_box');
  }
  if (!Hive.isBoxOpen('cached_post_box')) {
    await Hive.openBox<CachedPost>('cached_post_box');
  }
  if (!Hive.isBoxOpen('sync_queue_box')) {
    await Hive.openBox<SyncQueue>('sync_queue_box');
  }
  if (!Hive.isBoxOpen('local_vote_box')) {
    await Hive.openBox<LocalVote>('local_vote_box');
  }
  if (!Hive.isBoxOpen('local_bookmark_box')) {
    await Hive.openBox<LocalBookmark>('local_bookmark_box');
  }
  if (!Hive.isBoxOpen('cached_user_box')) {
    await Hive.openBox<CachedUser>('cached_user_box');
  }
  // Session box used by UI to listen for login/logout changes
  if (!Hive.isBoxOpen('session_box')) {
    await Hive.openBox('session_box');
  }
  if (!Hive.isBoxOpen('pending_post_box')) {
    await Hive.openBox<CachedPost>('pending_post_box');
  }
}
