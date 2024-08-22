import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

@immutable
class ParsedReceiptItem {
  @JsonKey(defaultValue: '')
  final String name;

  final double price;
  final double regularPrice;
  final int quantity;
  final String barcode;
  final bool taxable;
  final double bottleDeposit;
  final String receiptUid;

  const ParsedReceiptItem({
    required this.name,
    this.price = 0.0,
    this.quantity = 1,
    this.regularPrice = 0.0,
    this.barcode = '',
    this.taxable = true,
    this.bottleDeposit = 0.0,
    this.receiptUid = '',
  });

  double get totalPrice => price + bottleDeposit;

  ParsedReceiptItem copyWith({
    String? name,
    double? price,
    double? regularPrice,
    int? quantity,
    String? barcode,
    bool? taxable,
    double? bottleDeposit,
    DateTime? created,
    DateTime? updated,
    String? receiptUid,
  }) {
    return ParsedReceiptItem(
      name: name ?? this.name,
      price: price ?? this.price,
      regularPrice: regularPrice ?? this.regularPrice,
      quantity: quantity ?? this.quantity,
      barcode: barcode ?? this.barcode,
      taxable: taxable ?? this.taxable,
      bottleDeposit: bottleDeposit ?? this.bottleDeposit,
      receiptUid: receiptUid ?? this.receiptUid,
    );
  }

  bool equalTo(ParsedReceiptItem other) {
    return barcode == other.barcode &&
        name == other.name &&
        price == other.price &&
        regularPrice == other.regularPrice &&
        quantity == other.quantity &&
        taxable == other.taxable &&
        bottleDeposit == other.bottleDeposit &&
        receiptUid == other.receiptUid;
  }

  @override
  String toString() {
    String formattedPrice = price != 0.0 ? '\$$price' : '';
    String formattedQuantity = quantity != 1 ? '$quantity x ' : '';

    return '$barcode $name $formattedQuantity$formattedPrice'.trim();
  }
}
