// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'identifier.hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveItemIdentifierAdapter extends TypeAdapter<HiveItemIdentifier> {
  @override
  final int typeId = 0;

  @override
  HiveItemIdentifier read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveItemIdentifier()
      ..type = fields[0] as String
      ..value = fields[1] as String
      ..uid = fields[2] as String
      ..created = fields[3] as DateTime?
      ..updated = fields[4] as DateTime?;
  }

  @override
  void write(BinaryWriter writer, HiveItemIdentifier obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.value)
      ..writeByte(2)
      ..write(obj.uid)
      ..writeByte(3)
      ..write(obj.created)
      ..writeByte(4)
      ..write(obj.updated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveItemIdentifierAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
