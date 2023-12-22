import 'package:meta/meta.dart';
import 'package:repository/model/receipt_item.dart';

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

  Receipt copyAndReplaceItem(int index, ReceiptItem newItem) {
    var newItems = List<ReceiptItem>.from(items);
    if (index >= 0 && index < items.length) {
      newItems[index] = newItem;
    }
    return copyWith(items: newItems);
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
}
