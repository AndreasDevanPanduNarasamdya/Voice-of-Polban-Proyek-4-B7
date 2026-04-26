import 'package:hive_flutter/hive_flutter.dart';

import 'app_enums.dart';
import 'article_model.dart';
import 'user_model.dart';

Future<void> setupHive() async {
  await Hive.initFlutter();

  await Hive.deleteBoxFromDisk('users_box');
  await Hive.deleteBoxFromDisk('articles_box');
  await Hive.openBox('session_box');

  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(UserRoleAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(ArticleStatusAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(ArticleCategoryAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(UserModelAdapter());
  }
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(ArticleModelAdapter());
  }

  await Hive.openBox<UserModel>('users_box');
  await Hive.openBox<ArticleModel>('articles_box');

  final box = Hive.box<UserModel>('users_box');

  if (box.isEmpty) {
    print("Users box is empty. Seeding generic accounts...");

    final editor = UserModel(
      id: 'usr_editor',
      name: 'Chief Editor',
      email: 'editor',
      password: 'password123',
      role: UserRole.editor,
    );

    final writer = UserModel(
      id: 'usr_writer',
      name: 'Staff Writer',
      email: 'writer',
      password: 'password123',
      role: UserRole.writer,
    );

    final reader = UserModel(
      id: 'usr_reader',
      name: 'Student Reader',
      email: 'reader',
      password: 'password123',
      role: UserRole.reader,
    );

    await box.put(editor.id, editor);
    await box.put(writer.id, writer);
    await box.put(reader.id, reader);

    print("Generic users injected successfully!");
  } else {
    print("Users already exist. Skipping seed.");
  }
}

Future<void> seedInitialUsers() async {
  final box = Hive.box<UserModel>('users_box');

  if (box.isEmpty) {
    print("Users box is empty. Seeding generic accounts...");

    final editor = UserModel(
      id: 'usr_editor',
      name: 'Chief Editor',
      email: 'editor',
      password: 'password123',
      role: UserRole.editor,
    );

    final writer = UserModel(
      id: 'usr_writer',
      name: 'Staff Writer',
      email: 'writer',
      password: 'password123',
      role: UserRole.writer,
    );

    final reader = UserModel(
      id: 'usr_reader',
      name: 'Student Reader',
      email: 'reader',
      password: 'password123',
      role: UserRole.reader,
    );

    await box.put(editor.id, editor);
    await box.put(writer.id, writer);
    await box.put(reader.id, reader);

    print("Generic users injected successfully!");
  } else {
    print("Users already exist. Skipping seed.");
  }
}

// 4. MOVED OUTSIDE: This is now a standalone function
Future<void> seedInitialArticles() async {
  final box = Hive.box<ArticleModel>('articles_box');

  if (box.isEmpty) {
    print("Articles box is empty. Seeding dummy articles...");

    final article1 = ArticleModel(
      id: 'art_001',
      title: 'Berita Utama MetroPolban',
      content:
          'Ini adalah teks isi artikel. Bayangkan ini berisi banyak paragraf penting mengenai perkembangan kampus.',
      category: ArticleCategory.beritaKampus,
      authorId: 'usr_writer',
      status: ArticleStatus.published,
      createdAt: DateTime.now(),
    );

    final article2 = ArticleModel(
      id: 'art_002',
      title: 'Review Makanan Kantin Baru',
      content: 'Ayam geprek di kantin baru ternyata sangat direkomendasikan.',
      category: ArticleCategory.ormawa,
      authorId: 'usr_writer',
      status: ArticleStatus.pending,
      createdAt: DateTime.now(),
    );

    await box.put(article1.id, article1);
    await box.put(article2.id, article2);

    print("Dummy articles injected successfully!");
  }
}
