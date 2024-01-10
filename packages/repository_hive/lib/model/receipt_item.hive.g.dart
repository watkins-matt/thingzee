// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_item.hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveReceiptItemAdapter extends TypeAdapter<HiveReceiptItem> {
  @override
  final int typeId = 0;

  @override
  HiveReceiptItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveReceiptItem()
      ..name = fields[0] as String
      ..price = fields[1] as double
      ..regularPrice = fields[2] as double
      ..quantity = fields[3] as int
      ..barcode = fields[4] as String
      ..taxable = fields[5] as bool
      ..bottleDeposit = fields[6] as double;
  }

  @override
  void write(BinaryWriter writer, HiveReceiptItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.price)
      ..writeByte(2)
      ..write(obj.regularPrice)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.barcode)
      ..writeByte(5)
      ..write(obj.taxable)
      ..writeByte(6)
      ..write(obj.bottleDeposit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveReceiptItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
