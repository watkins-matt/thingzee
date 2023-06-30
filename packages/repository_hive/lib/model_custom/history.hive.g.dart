// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history.hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveHistoryAdapter extends TypeAdapter<HiveHistory> {
  @override
  final int typeId = 223;

  @override
  HiveHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveHistory()
      ..upc = fields[0] as String
      ..history = fields[1] as History;
  }

  @override
  void write(BinaryWriter writer, HiveHistory obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.upc)
      ..writeByte(1)
      ..write(obj.history);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
