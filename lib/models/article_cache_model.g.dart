// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article_cache_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ArticleCacheModelAdapter extends TypeAdapter<ArticleCacheModel> {
  @override
  final int typeId = 7;

  @override
  ArticleCacheModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ArticleCacheModel(
      cacheId: fields[0] as String,
      articleId: fields[1] as String,
      sectionId: fields[2] as String,
      cachedData: (fields[3] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, ArticleCacheModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.cacheId)
      ..writeByte(1)
      ..write(obj.articleId)
      ..writeByte(2)
      ..write(obj.sectionId)
      ..writeByte(3)
      ..write(obj.cachedData);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArticleCacheModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
