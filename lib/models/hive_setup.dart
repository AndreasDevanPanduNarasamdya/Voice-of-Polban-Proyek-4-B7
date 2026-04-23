import 'package:hive_flutter/hive_flutter.dart';

import 'app_enums.dart';
import 'article_model.dart';
import 'user_model.dart';

Future<void> setupHive() async {
  await Hive.initFlutter();

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
}
