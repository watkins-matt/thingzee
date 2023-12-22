import 'package:repository/model/receipt_item.dart';
import 'package:thingzee/pages/receipt_scanner/util/frequency_tracker.dart';

class ReceiptItemFrequencies {
  int totalCount = 0;
  DateTime firstAdded;
  String barcode = '';

  FrequencyTracker<String> nameTracker = FrequencyTracker<String>();

  FrequencyTracker<double> priceTracker = FrequencyTracker<double>();
  FrequencyTracker<double> regularPriceTracker = FrequencyTracker<double>();
  FrequencyTracker<int> quantityTracker = FrequencyTracker<int>();
  FrequencyTracker<bool> taxableTracker = FrequencyTracker<bool>();
  FrequencyTracker<double> bottleDepositTracker = FrequencyTracker<double>();
  ReceiptItemFrequencies() : firstAdded = DateTime.now();

  Duration get age {
    return DateTime.now().difference(firstAdded);
  }

  ReceiptItem get item {
    return ReceiptItem(
      barcode: barcode,
      name: nameTracker.getMostFrequent() ?? '',
      price: priceTracker.getMostFrequent() ?? 0.0,
      regularPrice: regularPriceTracker.getMostFrequent() ?? 0.0,
      quantity: quantityTracker.getMostFrequent() ?? 1,
      taxable: taxableTracker.getMostFrequent() ?? false,
      bottleDeposit: bottleDepositTracker.getMostFrequent() ?? 0.0,
    );
  }

  void add(ReceiptItem item) {
    if (barcode.isEmpty) {
      barcode = item.barcode;
    }

    nameTracker.add(item.name);
    priceTracker.add(item.price);
    regularPriceTracker.add(item.regularPrice);
    quantityTracker.add(item.quantity);
    taxableTracker.add(item.taxable);
    bottleDepositTracker.add(item.bottleDeposit);

    totalCount++;
  }

  @override
  String toString() {
    return '$totalCount $barcode ${nameTracker.getMostFrequent()} ${priceTracker.getMostFrequent()}';
  }
}

class ReceiptItemFrequencySet {
  Map<String, ReceiptItemFrequencies> itemMap = {};

  List<ReceiptItem> get items {
    if (itemMap.isEmpty) {
      return [];
    }

    double averageAdds =
        itemMap.values.map((e) => e.totalCount).reduce((a, b) => a + b) / itemMap.length;

    final entries = itemMap.entries
        .where((entry) {
          return entry.value.totalCount >= averageAdds * 0.5; // * timeFactor;
        })
        .map((entry) => entry.value.item)
        .toList();

    _removeSuspiciousEntries();
    return entries;
  }

  void add(ReceiptItem item) {
    if (item.barcode.isEmpty || item.price == 0.0) return;

    String itemKey = _getItemUniqueKey(item);
    itemMap.putIfAbsent(itemKey, () => ReceiptItemFrequencies()).add(item);
  }

  ReceiptItem? get(String barcode) {
    return itemMap[barcode]?.item;
  }

  List<String> _determineItemsToRemove(List<String> keys) {
    // Extract the items and their prices
    var itemsWithPrices = keys.where((key) => itemMap.containsKey(key)).map((key) {
      var item = itemMap[key]!.item;
      return {'key': key, 'price': item.price};
    }).toList();
    // Sort by price, keeping the original keys
    itemsWithPrices.sort((a, b) => (a['price'] as double).compareTo(b['price'] as double));

    // Decide which item to remove based on criteria
    var prices = itemsWithPrices.map((e) => e['price'] as double).toList();

    // Prefer to remove the price that doesn't end in 9, unless it's less than 1
    var lowerPrice = prices.first;
    if (lowerPrice < 1) {
      return itemsWithPrices
          .where((e) => e['price'] == lowerPrice)
          .map((e) => e['key'] as String)
          .toList();
    } else {
      var itemsToRemove = itemsWithPrices
          .where((e) => !(e['price'] as double).toStringAsFixed(2).endsWith('9'))
          .map((e) => e['key'] as String)
          .toList();
      if (itemsToRemove.length == keys.length) {
        return [itemsToRemove.first]; // Keep the first element if removing everything
      } else {
        return itemsToRemove;
      }
    }
  }

  String _getItemUniqueKey(ReceiptItem item) {
    return '${item.barcode}_${item.price.toStringAsFixed(2)}';
  }

  void _removeSuspiciousEntries() {
    var itemsByBarcode = <String, List<String>>{};
    itemMap.forEach((key, value) {
      var barcode = key.split('_')[0];
      itemsByBarcode.putIfAbsent(barcode, () => []).add(key);
    });

    itemsByBarcode.forEach((barcode, keys) {
      if (keys.length > 1) {
        var suspiciousKeys = _determineItemsToRemove(keys);
        suspiciousKeys.forEach(itemMap.remove);
      }
    });
  }
}
