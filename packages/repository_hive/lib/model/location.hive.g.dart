// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location.hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveLocationAdapter extends TypeAdapter<HiveLocation> {
  @override
  final int typeId = 0;

  @override
  HiveLocation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveLocation()
      ..created = fields[0] as DateTime
      ..updated = fields[1] as DateTime
      ..upc = fields[2] as String
      ..name = fields[3] as String
      ..quantity = fields[4] as double?;
  }

  @override
  void write(BinaryWriter writer, HiveLocation obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.created)
      ..writeByte(1)
      ..write(obj.updated)
      ..writeByte(2)
      ..write(obj.upc)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.quantity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveLocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
