// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_song.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HistorySongAdapter extends TypeAdapter<HistorySong> {
  @override
  final int typeId = 1;

  @override
  HistorySong read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HistorySong(
      title: fields[0] as String,
      artist: fields[1] as String?,
      path: fields[2] as String?,
      uri: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HistorySong obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.artist)
      ..writeByte(2)
      ..write(obj.path)
      ..writeByte(3)
      ..write(obj.uri);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistorySongAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
