import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:repository/model/serializer_datetime.dart';

part 'receipt_item.g.dart';

@JsonSerializable()
@immutable
class ReceiptItem extends Model<ReceiptItem> {
  @JsonKey(defaultValue: '')
  final String name;

  @JsonKey(defaultValue: 0.0)
  final double price;

  @JsonKey(defaultValue: 0.0)
  final double regularPrice;

  @JsonKey(defaultValue: 1)
  final int quantity;

  @JsonKey(defaultValue: '')
  final String barcode;

  @JsonKey(defaultValue: true)
  final bool taxable;

  @JsonKey(defaultValue: 0.0)
  final double bottleDeposit;

  ReceiptItem({
    required this.name,
    this.price = 0.0,
    this.quantity = 1,
    this.regularPrice = 0.0,
    this.barcode = '',
    this.taxable = true,
    this.bottleDeposit = 0.0,
    super.created,
    super.updated,
  });

  factory ReceiptItem.fromJson(Map<String, dynamic> json) => _$ReceiptItemFromJson(json);

  @override
  String get id => '$barcode-$price';

  double get totalPrice => price + bottleDeposit;

  ReceiptItem copyWith({
    String? name,
    double? price,
    double? regularPrice,
    int? quantity,
    String? barcode,
    bool? taxable,
    double? bottleDeposit,
  }) {
    return ReceiptItem(
      name: name ?? this.name,
      price: price ?? this.price,
      regularPrice: regularPrice ?? this.regularPrice,
      quantity: quantity ?? this.quantity,
      barcode: barcode ?? this.barcode,
      taxable: taxable ?? this.taxable,
      bottleDeposit: bottleDeposit ?? this.bottleDeposit,
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
        bottleDeposit == other.bottleDeposit;
  }

  @override
  ReceiptItem merge(ReceiptItem other) {
    // Determine the newer updated object
    final newer = (updated != null &&
            updated!.isAfter(other.updated ?? DateTime.fromMillisecondsSinceEpoch(0)))
        ? this
        : other;

    // Use data from the newer updated object unless it's empty or null
    final mergedReceiptItem = ReceiptItem(
      name: newer.name.isNotEmpty ? newer.name : name,
      price: newer.price != 0.0 ? newer.price : price,
      regularPrice: newer.regularPrice != 0.0 ? newer.regularPrice : regularPrice,
      quantity: newer.quantity != 0 ? newer.quantity : quantity,
      barcode: newer.barcode.isNotEmpty ? newer.barcode : barcode,
      taxable: newer.taxable,
      bottleDeposit: newer.bottleDeposit != 0.0 ? newer.bottleDeposit : bottleDeposit,
      created: _determineOlderCreatedDate(created, other.created),
      updated: DateTime.now(), // Set to now initially
    );

    // Check if the merged object is equal to the newer one
    DateTime? finalUpdatedDate = mergedReceiptItem.equalTo(newer) ? newer.updated : DateTime.now();

    return ReceiptItem(
      name: mergedReceiptItem.name,
      price: mergedReceiptItem.price,
      regularPrice: mergedReceiptItem.regularPrice,
      quantity: mergedReceiptItem.quantity,
      barcode: mergedReceiptItem.barcode,
      taxable: mergedReceiptItem.taxable,
      bottleDeposit: mergedReceiptItem.bottleDeposit,
      created: mergedReceiptItem.created,
      updated: finalUpdatedDate ?? DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toJson() => _$ReceiptItemToJson(this);

  @override
  String toString() {
    String formattedPrice = price != 0.0 ? '\$$price' : '';
    String formattedQuantity = quantity != 1 ? '$quantity x ' : '';

    return '$barcode $name $formattedQuantity$formattedPrice'.trim();
  }

  static DateTime _determineOlderCreatedDate(DateTime? date1, DateTime? date2) {
    return date1 ?? date2 ?? DateTime.now();
  }
}
