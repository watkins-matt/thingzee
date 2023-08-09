// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_member.hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveHouseholdMemberAdapter extends TypeAdapter<HiveHouseholdMember> {
  @override
  final int typeId = 5;

  @override
  HiveHouseholdMember read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveHouseholdMember()
      ..isAdmin = fields[0] as bool
      ..timestamp = fields[1] as DateTime
      ..email = fields[2] as String
      ..householdId = fields[3] as String
      ..name = fields[4] as String
      ..userId = fields[5] as String;
  }

  @override
  void write(BinaryWriter writer, HiveHouseholdMember obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.isAdmin)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.householdId)
      ..writeByte(4)
      ..write(obj.name)
      ..writeByte(5)
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
