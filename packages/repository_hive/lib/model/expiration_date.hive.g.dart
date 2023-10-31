// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expiration_date.hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveExpirationDateAdapter extends TypeAdapter<HiveExpirationDate> {
  @override
  final int typeId = 7;

  @override
  HiveExpirationDate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveExpirationDate()
      ..upc = fields[0] as String
      ..date = fields[1] as DateTime?
      ..created = fields[2] as DateTime?;
  }

  @override
  void write(BinaryWriter writer, HiveExpirationDate obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.upc)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.created);
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
