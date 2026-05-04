import 'package:hive/hive.dart';

part 'sync_queue.g.dart';

@HiveType(typeId: 3)
class SyncQueue {
  SyncQueue({
    required this.queueId,
    required this.actionType,
    required this.payload,
    required this.isProcessed,
    required this.createdAt,
  });

  @HiveField(0)
  String queueId;

  @HiveField(1)
  String actionType;

  @HiveField(2)
  String payload;

  @HiveField(3)
  bool isProcessed;

  @HiveField(4)
  DateTime createdAt;
}
