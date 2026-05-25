// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_vote.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalVoteAdapter extends TypeAdapter<LocalVote> {
  @override
  final int typeId = 4;

  @override
  LocalVote read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalVote(
      voteId: fields[0] as String,
      postId: fields[1] as String,
      userId: fields[2] as String,
      upvoteStatus: fields[3] as bool,
      isSynced: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, LocalVote obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.voteId)
      ..writeByte(1)
      ..write(obj.postId)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.upvoteStatus)
      ..writeByte(4)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalVoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
