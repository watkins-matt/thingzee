// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invitation.hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveInvitationAdapter extends TypeAdapter<HiveInvitation> {
  @override
  final int typeId = 0;

  @override
  HiveInvitation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveInvitation()
      ..created = fields[0] as DateTime
      ..updated = fields[1] as DateTime
      ..uniqueKey = fields[2] as String
      ..householdId = fields[3] as String
      ..inviterEmail = fields[4] as String
      ..inviterUserId = fields[5] as String
      ..recipientEmail = fields[6] as String
      ..status = fields[7] as InvitationStatus;
  }

  @override
  void write(BinaryWriter writer, HiveInvitation obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.created)
      ..writeByte(1)
      ..write(obj.updated)
      ..writeByte(2)
      ..write(obj.uniqueKey)
      ..writeByte(3)
      ..write(obj.householdId)
      ..writeByte(4)
      ..write(obj.inviterEmail)
      ..writeByte(5)
      ..write(obj.inviterUserId)
      ..writeByte(6)
      ..write(obj.recipientEmail)
      ..writeByte(7)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveInvitationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
