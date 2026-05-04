// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_post.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedPostAdapter extends TypeAdapter<CachedPost> {
  @override
  final int typeId = 2;

  @override
  CachedPost read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedPost(
      postId: fields[0] as String,
      cachedData: fields[1] as String,
      cachedAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CachedPost obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.postId)
      ..writeByte(1)
      ..write(obj.cachedData)
      ..writeByte(2)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedPostAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
