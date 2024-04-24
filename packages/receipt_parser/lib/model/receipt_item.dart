import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/merge_generator.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:repository/model/serializer_datetime.dart';
import 'package:util/extension/date_time.dart';

part 'receipt_item.g.dart';
part 'receipt_item.merge.dart';

@JsonSerializable()
@immutable
@Mergeable()
class ReceiptItem extends Model<ReceiptItem> {
  @JsonKey(defaultValue: '')
  final String name;

  final double price;
  final double regularPrice;
  final int quantity;
  final String barcode;
  final bool taxable;
  final double bottleDeposit;
  final String receiptUid;

  ReceiptItem({
    required this.name,
    this.price = 0.0,
    this.quantity = 1,
    this.regularPrice = 0.0,
    this.barcode = '',
    this.taxable = true,
    this.bottleDeposit = 0.0,
    this.receiptUid = '',
    super.created,
    super.updated,
  });

  factory ReceiptItem.fromJson(Map<String, dynamic> json) => _$ReceiptItemFromJson(json);

  double get totalPrice => price + bottleDeposit;

  @override
  String get uniqueKey => '$receiptUid-$barcode-$price';

  @override
  ReceiptItem copyWith({
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
    return ReceiptItem(
      name: name ?? this.name,
      price: price ?? this.price,
      regularPrice: regularPrice ?? this.regularPrice,
      quantity: quantity ?? this.quantity,
      barcode: barcode ?? this.barcode,
      taxable: taxable ?? this.taxable,
      bottleDeposit: bottleDeposit ?? this.bottleDeposit,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      receiptUid: receiptUid ?? this.receiptUid,
    );
  }

  @override
  bool equalTo(ReceiptItem other) {
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
  ReceiptItem merge(ReceiptItem other) => _$mergeReceiptItem(this, other);

  @override
  Map<String, dynamic> toJson() => _$ReceiptItemToJson(this);

  @override
  String toString() {
    String formattedPrice = price != 0.0 ? '\$$price' : '';
    String formattedQuantity = quantity != 1 ? '$quantity x ' : '';

    return '$barcode $name $formattedQuantity$formattedPrice'.trim();
  }
}
