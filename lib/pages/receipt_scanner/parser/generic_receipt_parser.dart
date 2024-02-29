import 'package:petitparser/petitparser.dart';
import 'package:repository/model/receipt.dart';
import 'package:repository/model/receipt_item.dart';
import 'package:thingzee/pages/receipt_scanner/parser/element/barcode.dart';
import 'package:thingzee/pages/receipt_scanner/parser/element/item_text.dart';
import 'package:thingzee/pages/receipt_scanner/parser/element/price.dart';
import 'package:thingzee/pages/receipt_scanner/parser/error_corrector.dart';
import 'package:thingzee/pages/receipt_scanner/parser/ocr_text.dart';
import 'package:thingzee/pages/receipt_scanner/parser/parser.dart';
import 'package:thingzee/pages/receipt_scanner/util/frequency_tracker.dart';

typedef LineParseResult = ({String? barcode, String? text, double? price, int count});

class GenericReceiptParser extends ReceiptParser {
  final FrequencyTracker<double> _totalTracker = FrequencyTracker<double>();
  final FrequencyTracker<double> _subtotalTracker = FrequencyTracker<double>();
  final FrequencyTracker<double> _taxTracker = FrequencyTracker<double>();
  final FrequencyTracker<DateTime> _dateTracker = FrequencyTracker<DateTime>();
  final FrequencyTracker<double> _discountTracker = FrequencyTracker<double>();
  // final ReceiptItemFrequencySet _frequencySet = ReceiptItemFrequencySet();
  final ErrorCorrector _errorCorrector = ErrorCorrector();
  final OcrText _ocrText = OcrText();

  final List<String> _queueBarcode = [];
  final List<String> _queueItemText = [];
  final List<String> _queuePrice = [];

  final List<ReceiptItem> _items = [];
  @override
  String get rawText => _ocrText.text;

  @override
  Receipt get receipt {
    return Receipt(
      items: _items,
      date: _dateTracker.getMostFrequent() ?? DateTime.now(),
      subtotal: _subtotalTracker.getMostFrequent() ?? 0.0,
      discounts: _discountTracker.getMostFrequentList(),
      tax: _taxTracker.getMostFrequent() ?? 0.0,
      total: _totalTracker.getMostFrequent() ?? 0.0,
    );
  }

  void clearQueues() {
    _queueBarcode.clear();
    _queueItemText.clear();
    _queuePrice.clear();
  }

  @override
  String getSearchUrl(String barcode) => 'https://www.google.com/search?q=$barcode';

  bool isValidLine(String text) {
    // Check to see if 2/3 parses succeed on the given line
    final parsedBarcode = skipToBarcodeParser().parse(text);
    final parsedItemText = skipToItemTextParser().parse(text);
    final parsedPrice = skipToPriceParser().parse(text);
    int success = 0;

    if (parsedBarcode is Success) {
      success++;
    }
    if (parsedItemText is Success) {
      success++;
    }
    if (parsedPrice is Success) {
      success++;
    }

    return success >= 2;
  }

  @override
  void parse(String text) {
    _items.clear();
    text = _errorCorrector.correctErrors(text);

    OcrText newText = OcrText.fromString(text);
    _ocrText.merge(newText);

    bool startedParsing = false;
    bool doneParsingItems = false;
    final splitText = _ocrText.text.split('\n');

    for (final line in splitText) {
      final result = parseLine(line);

      // There is likely some text before the items on the receipt,
      // so check to see if we can parse at least 2/3 items from the line.
      // If we can, we can start parsing the receipt from this point.
      if (result.text != null && result.price != null && !startedParsing) {
        startedParsing = true;
      }

      // There might be a barcode on the line above the first item, so we check for that
      else if (result.barcode != null) {
        _queueBarcode.clear();
        _queueBarcode.add(result.barcode!);
      }

      // We have only encountered unrelated text on the receipt so far,
      // so continue until we find a line that contains at least 2/3 parsable items.
      if (!startedParsing) {
        continue;
      }

      // If we have a full line, we can process the items
      if (!doneParsingItems && result.count == 3) {
        final barcode = result.barcode;
        final itemText = result.text;
        final price = result.price;

        ReceiptItem item = ReceiptItem(
          barcode: barcode!,
          name: itemText!,
          price: price!,
        );

        _items.add(item);
        clearQueues();
      }

      // If we have text and a price, we can add the item
      else if (result.count == 2 && result.text != null && result.price != null) {
        // Check for special fields at the end of the receipt
        if (line.toLowerCase().contains('subtotal') || line.toLowerCase().contains('sub total')) {
          _subtotalTracker.add(result.price!);
          doneParsingItems = true;
          continue;
        } else if (line.toLowerCase().contains('total') ||
            result.text!.toLowerCase() == 'balance') {
          _totalTracker.add(result.price!);
          doneParsingItems = true;
          continue;
        } else if (line.toLowerCase().contains('tax')) {
          _taxTracker.add(result.price!);
          doneParsingItems = true;
          continue;
        } else if (line.toLowerCase().contains('discount') ||
            line.toLowerCase().contains('savings')) {
          _discountTracker.add(result.price!);
          doneParsingItems = true;
          continue;
        }

        _queueItemText.add(result.text!);
        _queuePrice.add(result.price.toString());
      }

      // We have a barcode only, add it
      else if (result.count == 1 && result.barcode != null) {
        _queueBarcode.add(result.barcode!);
      }

      // Check for a full queue
      if (!doneParsingItems &&
          _queueBarcode.isNotEmpty &&
          _queueItemText.isNotEmpty &&
          _queuePrice.isNotEmpty) {
        final barcode = _queueBarcode.removeAt(0);
        final itemText = _queueItemText.removeAt(0);
        final price = _queuePrice.removeAt(0);

        ReceiptItem item = ReceiptItem(
          barcode: barcode,
          name: itemText,
          price: double.parse(price),
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
          final price = _queuePrice[i];

          ReceiptItem item = ReceiptItem(
            name: itemText,
            price: double.parse(price),
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
    final price = parsedPrice is Success ? double.parse(parsedPrice.value) : null;

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
