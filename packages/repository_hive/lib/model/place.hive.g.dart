// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place.hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HivePlaceAdapter extends TypeAdapter<HivePlace> {
  @override
  final int typeId = 0;

  @override
  HivePlace read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HivePlace()
      ..created = fields[0] as DateTime
      ..updated = fields[1] as DateTime
      ..phoneNumber = fields[2] as String
      ..name = fields[3] as String
      ..city = fields[4] as String
      ..state = fields[5] as String
      ..zipcode = fields[6] as String;
  }

  @override
  void write(BinaryWriter writer, HivePlace obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.created)
      ..writeByte(1)
      ..write(obj.updated)
      ..writeByte(2)
      ..write(obj.phoneNumber)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.city)
      ..writeByte(5)
      ..write(obj.state)
      ..writeByte(6)
      ..write(obj.zipcode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HivePlaceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
