// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'identifier.hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveIdentifierAdapter extends TypeAdapter<HiveIdentifier> {
  @override
  final int typeId = 0;

  @override
  HiveIdentifier read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveIdentifier()
      ..created = fields[0] as DateTime
      ..updated = fields[1] as DateTime
      ..type = fields[2] as String
      ..value = fields[3] as String
      ..uid = fields[4] as String;
  }

  @override
  void write(BinaryWriter writer, HiveIdentifier obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.created)
      ..writeByte(1)
      ..write(obj.updated)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.value)
      ..writeByte(4)
      ..write(obj.uid);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveIdentifierAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
