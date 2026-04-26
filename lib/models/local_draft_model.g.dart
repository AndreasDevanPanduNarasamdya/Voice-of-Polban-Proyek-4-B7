// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_draft_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalDraftModelAdapter extends TypeAdapter<LocalDraftModel> {
  @override
  final int typeId = 11;

  @override
  LocalDraftModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalDraftModel(
      localId: fields[0] as String,
      articleId: fields[1] as String,
      userId: fields[2] as String,
      title: fields[3] as String,
      content: fields[4] as String,
      status: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LocalDraftModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.localId)
      ..writeByte(1)
      ..write(obj.articleId)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.content)
      ..writeByte(5)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalDraftModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
