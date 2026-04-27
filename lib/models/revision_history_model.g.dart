// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'revision_history_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RevisionHistoryModelAdapter extends TypeAdapter<RevisionHistoryModel> {
  @override
  final int typeId = 6;

  @override
  RevisionHistoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RevisionHistoryModel(
      revisionId: fields[0] as String,
      articleId: fields[1] as String,
      editorId: fields[2] as String,
      action: fields[3] as String,
      note: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, RevisionHistoryModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.revisionId)
      ..writeByte(1)
      ..write(obj.articleId)
      ..writeByte(2)
      ..write(obj.editorId)
      ..writeByte(3)
      ..write(obj.action)
      ..writeByte(4)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RevisionHistoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
