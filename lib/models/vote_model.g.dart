// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vote_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VoteModelAdapter extends TypeAdapter<VoteModel> {
  @override
  final int typeId = 8;

  @override
  VoteModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VoteModel(
      voteId: fields[0] as String,
      upvoteStatus: fields[1] as bool,
      articleId: fields[2] as String,
      userId: fields[3] as String,
      isSynced: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, VoteModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.voteId)
      ..writeByte(1)
      ..write(obj.upvoteStatus)
      ..writeByte(2)
      ..write(obj.articleId)
      ..writeByte(3)
      ..write(obj.userId)
      ..writeByte(4)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoteModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
