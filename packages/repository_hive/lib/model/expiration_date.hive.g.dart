// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expiration_date.hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveExpirationDateAdapter extends TypeAdapter<HiveExpirationDate> {
  @override
  final int typeId = 0;

  @override
  HiveExpirationDate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveExpirationDate()
      ..created = fields[0] as DateTime
      ..updated = fields[1] as DateTime
      ..upc = fields[2] as String
      ..expirationDate = fields[3] as DateTime?;
  }

  @override
  void write(BinaryWriter writer, HiveExpirationDate obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.created)
      ..writeByte(1)
      ..write(obj.updated)
      ..writeByte(2)
      ..write(obj.upc)
      ..writeByte(3)
      ..write(obj.expirationDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveExpirationDateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
