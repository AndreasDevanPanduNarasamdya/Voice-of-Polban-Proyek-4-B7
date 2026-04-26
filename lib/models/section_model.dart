import 'package:hive/hive.dart';

part 'section_model.g.dart';

@HiveType(typeId: 1)
class SectionModel {
  const SectionModel({
    required this.sectionId,
    required this.name,
    required this.createdAt,
  });

  @HiveField(0)
  final String sectionId;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final DateTime createdAt;
}
