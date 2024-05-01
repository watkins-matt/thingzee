// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_member.hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveHouseholdMemberAdapter extends TypeAdapter<HiveHouseholdMember> {
  @override
  final int typeId = 0;

  @override
  HiveHouseholdMember read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveHouseholdMember()
      ..created = fields[0] as DateTime
      ..updated = fields[1] as DateTime
      ..isAdmin = fields[2] as bool
      ..email = fields[3] as String
      ..householdId = fields[4] as String
      ..name = fields[5] as String
      ..userId = fields[6] as String;
  }

  @override
  void write(BinaryWriter writer, HiveHouseholdMember obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.created)
      ..writeByte(1)
      ..write(obj.updated)
      ..writeByte(2)
      ..write(obj.isAdmin)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.householdId)
      ..writeByte(5)
      ..write(obj.name)
      ..writeByte(6)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveHouseholdMemberAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
