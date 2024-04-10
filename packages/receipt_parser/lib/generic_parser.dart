import 'package:petitparser/petitparser.dart';
import 'package:receipt_parser/element/barcode.dart';
import 'package:receipt_parser/element/item_text.dart';
import 'package:receipt_parser/element/price.dart';
import 'package:receipt_parser/model/receipt.dart';
import 'package:receipt_parser/model/receipt_item.dart';
import 'package:receipt_parser/ocr_text.dart';
import 'package:receipt_parser/parser.dart';

typedef LineParseResult = ({String? barcode, String? text, double? price, int count});

class GenericReceiptParser extends ReceiptParser {
  final List<String> _queueBarcode = [];
  final List<String> _queueItemText = [];
  final List<String> _queuePrice = [];
  final List<ReceiptItem> _items = [];

  @override
  String get rawText => ocrText.text;

  @override
  Receipt get receipt {
    return Receipt(
      items: _items,
      date: dateTracker.getMostFrequent() ?? DateTime.now(),
      subtotal: subtotalTracker.getMostFrequent() ?? 0.0,
      discounts: discountTracker.getMostFrequentList(),
      tax: taxTracker.getMostFrequent() ?? 0.0,
      total: totalTracker.getMostFrequent() ?? 0.0,
    );
  }

  void clearQueues() {
    _queueBarcode.clear();
    _queueItemText.clear();
    _queuePrice.clear();
  }

  /// Returns the index of the last item in the list that does not
  /// have a bottle deposit. This is necessary because in some receipts,
  /// the bottle deposits are not always listed directly after the item, but
  /// as a sequence of bottle deposits after all the items requiring deposits.
  int getLastWithoutBottleDeposit() {
    for (int i = _items.length - 1; i >= 0; i--) {
      if (_items[i].bottleDeposit == 0) {
        return i;
      }
    }

    return -1;
  }

  bool isBottleDeposit(double price) => price == 0.05 || price == 0.10 || price == 0.15;

  @override
  void parse(String text) {
    clearQueues();
    _items.clear();
    text = errorCorrector.correctErrors(text);

    OcrText newText = OcrText.fromString(text);
    ocrText.merge(newText);

    bool startedParsing = false;
    bool doneParsingItems = false;
    final splitText = ocrText.text.split('\n');

    for (final line in splitText) {
      final result = parseLine(line);

      // Don't start parsing until we reach the first price
      if (result.price != null) {
        startedParsing = true;
        _queuePrice.add(result.price.toString());
      }

      // There might be a barcode on the line above the first item, so we check for that
      if (result.barcode != null) {
        _queueBarcode.clear();
        _queueBarcode.add(result.barcode!);
      }

      if (result.text != null) {
        _queueItemText.clear();
        _queueItemText.add(result.text!);
      }

      // We have only encountered unrelated text on the receipt so far
      // so don't build any items yet
      if (!startedParsing) {
        continue;
      }

      // If we have a full line, we can process the items
      if (!doneParsingItems && result.count == 3) {
        final barcode = result.barcode;
        final itemText = result.text;
        final price = result.price;

        // Handle lines specifically for bottle deposits
        if (isBottleDeposit(price!) && _items.isNotEmpty) {
          int lastItem = getLastWithoutBottleDeposit();
          if (lastItem != -1) {
            _items[lastItem] = _items[lastItem].copyWith(
              bottleDeposit: price,
            );
          }

          continue;
        }

        ReceiptItem item = ReceiptItem(
          barcode: barcode!,
          name: itemText!,
          price: price,
        );

        _items.add(item);
        clearQueues();
        continue;
      }

      // If we have text and a price, we can add the item
      else if (result.count == 2 && result.text != null && result.price != null) {
        // Check for special fields at the end of the receipt
        if (line.toLowerCase().contains('subtotal') ||
            line.toLowerCase().contains('sub total') ||
            line.toLowerCase().contains('net total')) {
          subtotalTracker.add(result.price!);
          doneParsingItems = true;
          continue;
        } else if (line.toLowerCase().contains('total') ||
            result.text!.toLowerCase() == 'balance') {
          totalTracker.add(result.price!);
          doneParsingItems = true;
          continue;
        } else if (line.toLowerCase().contains('tax')) {
          taxTracker.add(result.price!);
          doneParsingItems = true;
          continue;
        } else if (line.toLowerCase().contains('discount') ||
            line.toLowerCase().contains('savings')) {
          discountTracker.add(result.price!);
          doneParsingItems = true;
          continue;
        }

        _queueItemText.add(result.text!);
        _queuePrice.add(result.price.toString());
      }

      // Check for a full queue
      if (!doneParsingItems &&
          _queueBarcode.isNotEmpty &&
          _queueItemText.isNotEmpty &&
          _queuePrice.isNotEmpty) {
        final barcode = _queueBarcode.removeAt(0);
        final itemText = _queueItemText.removeAt(0);
        final price = double.tryParse(_queuePrice.removeAt(0)) ?? 0;

        // Handle lines specifically for bottle deposits
        if (isBottleDeposit(price) && _items.isNotEmpty) {
          int lastItem = getLastWithoutBottleDeposit();
          if (lastItem != -1) {
            _items[lastItem] = _items[lastItem].copyWith(
              bottleDeposit: price,
            );
          }

          continue;
        }

        ReceiptItem item = ReceiptItem(
          barcode: barcode,
          name: itemText,
          price: price,
        );

        _items.add(item);
        clearQueues();
      }
    }

    if (_items.isEmpty) {
      // If we did not parse any items, this means that the receipt does not
      // have one of the required fields (barcode, item text, price).
      // So we go through the queues, and add items based on which fields are
      // present in the queue.
      if (_queueItemText.isNotEmpty && _queuePrice.isNotEmpty) {
        for (int i = 0; i < _queueItemText.length; i++) {
          final itemText = _queueItemText[i];
          final price = double.tryParse(_queuePrice[i]) ?? 0;

          // Handle lines specifically for bottle deposits
          if (isBottleDeposit(price) && _items.isNotEmpty) {
            int lastItem = getLastWithoutBottleDeposit();
            if (lastItem != -1) {
              _items[lastItem] = _items[lastItem].copyWith(
                bottleDeposit: price,
              );
            }

            continue;
          }

          ReceiptItem item = ReceiptItem(
            name: itemText,
            price: price,
          );

          _items.add(item);
        }
      }
    }
  }

  LineParseResult parseLine(String text) {
    final parsedBarcode = skipToBarcodeParser().parse(text);
    final parsedItemText = skipToItemTextParser().parse(text);
    final parsedPrice = skipToPriceParser().parse(text);

    // If the parser is Success, we return parser.value, otherwise an empty string
    final barcode = parsedBarcode is Success ? parsedBarcode.value : null;
    final itemText = parsedItemText is Success ? parsedItemText.value : null;
    final price = parsedPrice is Success && parsedPrice.value.isNotEmpty
        ? double.tryParse(parsedPrice.value) ?? 0
        : null;

    // Set count to 0 if any of the values are null, otherwise increment it
    int count = 0;
    if (barcode != null) {
      count++;
    }
    if (itemText != null) {
      count++;
    }
    if (price != null) {
      count++;
    }

    return (barcode: barcode, text: itemText, price: price, count: count);
  }
}
