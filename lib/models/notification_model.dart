import 'package:hive/hive.dart';

part 'notification_model.g.dart';

@HiveType(typeId: 10)
class NotificationModel {
  const NotificationModel({
    required this.notifId,
    required this.userId,
    required this.type,
    required this.relatedArticleId,
    required this.message,
    required this.isRead,
  });

  @HiveField(0)
  final String notifId;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String type;

  @HiveField(3)
  final String relatedArticleId;

  @HiveField(4)
  final String message;

  @HiveField(5)
  final bool isRead;
}
