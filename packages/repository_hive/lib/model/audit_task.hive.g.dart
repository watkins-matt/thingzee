// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_task.hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveAuditTaskAdapter extends TypeAdapter<HiveAuditTask> {
  @override
  final int typeId = 0;

  @override
  HiveAuditTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveAuditTask()
      ..created = fields[0] as DateTime
      ..updated = fields[1] as DateTime
      ..upc = fields[2] as String
      ..type = fields[3] as String
      ..data = fields[4] as String
      ..uid = fields[5] as String
      ..completed = fields[6] as DateTime?;
  }

  @override
  void write(BinaryWriter writer, HiveAuditTask obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.created)
      ..writeByte(1)
      ..write(obj.updated)
      ..writeByte(2)
      ..write(obj.upc)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.data)
      ..writeByte(5)
      ..write(obj.uid)
      ..writeByte(6)
      ..write(obj.completed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveAuditTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
