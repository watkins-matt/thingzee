import 'package:meta/meta.dart';

@immutable
class Receipt {
  final List<ReceiptItem> items;
  final DateTime date;
  final double subtotal;
  final List<double> discounts;
  final double tax;
  final double total;

  const Receipt({
    required this.items,
    required this.date,
    this.subtotal = 0.0,
    this.discounts = const [],
    this.tax = 0.0,
    this.total = 0.0,
  });

  double get calculatedSubtotal {
    return items.fold(0, (previousValue, element) => previousValue + element.totalPrice);
  }

  Receipt copyWith({
    List<ReceiptItem>? items,
    DateTime? date,
    double? subtotal,
    List<double>? discounts,
    double? tax,
    double? total,
  }) {
    return Receipt(
      items: items ?? this.items,
      date: date ?? this.date,
      subtotal: subtotal ?? this.subtotal,
      discounts: discounts ?? this.discounts,
      tax: tax ?? this.tax,
      total: total ?? this.total,
    );
  }

  Receipt replaceItem(int index, ReceiptItem newItem) {
    var newItems = List<ReceiptItem>.from(items);
    if (index >= 0 && index < items.length) {
      newItems[index] = newItem;
    }
    return copyWith(items: newItems);
  }
}

@immutable
class ReceiptItem {
  final String name;
  final double price;
  final double regularPrice;
  final int quantity;
  final String barcode;
  final bool taxable;
  final double bottleDeposit;

  const ReceiptItem({
    required this.name,
    this.price = 0.0,
    this.quantity = 1,
    this.regularPrice = 0.0,
    this.barcode = '',
    this.taxable = true,
    this.bottleDeposit = 0.0,
  });

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
  String toString() {
    String formattedPrice = price != 0.0 ? '\$$price' : '';
    String formattedQuantity = quantity != 1 ? '$quantity x ' : '';

    return '$barcode $name $formattedQuantity$formattedPrice'.trim();
  }
}
