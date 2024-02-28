import 'package:petitparser/petitparser.dart';
import 'package:repository/model/receipt.dart';
import 'package:repository/model/receipt_item.dart';
import 'package:thingzee/pages/receipt_scanner/parser/error_corrector.dart';
import 'package:thingzee/pages/receipt_scanner/parser/ocr_text.dart';
import 'package:thingzee/pages/receipt_scanner/parser/parser.dart';
import 'package:thingzee/pages/receipt_scanner/util/frequency_tracker.dart';

Parser<String> barcodeParser() {
  // Start with a digit and allow letters or whitespace, but ensure we capture till the last digit
  final startWithDigit = digit();
  final allowedChar = letter() | whitespace();
  final digitThenOther = digit().seq(allowedChar).star();

  // Combine the parsers to ensure we capture a sequence starting with digits and optionally followed by letters or whitespaces
  final combined = startWithDigit.seq(digitThenOther) & digit().star();

  return combined.flatten().map(correctNumericSequence).where((correctedSequence) {
    // Validation to ensure the corrected sequence is predominantly digits and meets length criteria
    int digitCount = correctedSequence.replaceAll(RegExp(r'[^0-9]'), '').length;
    return digitCount >= (correctedSequence.length * 0.7).floor() && correctedSequence.length >= 4;
  });
}

String correctNumericSequence(String sequence) {
  return sequence
      .toUpperCase()
      .replaceAll('O', '0')
      .replaceAll('I', '1')
      .replaceAll('Z', '2')
      .replaceAll('S', '5')
      .replaceAll('D', '0')
      .replaceAll('A', '4')
      .replaceAll('E', '6')
      .replaceAll('U', '0')
      .replaceAll(RegExp(r'\s+'), ''); // Remove all spaces
}

Parser<String> itemTextParser() {
  // Optional initial whitespace, followed by a letter as the start of the item text.
  var optionalInitialWhitespace = whitespace().optional();
  var startWithLetter = letter();

  // Parser for allowed item text characters: letters, digits, and horizontal spaces (excluding newlines).
  var allowedChars = (letter() | digit() | pattern(' \t\'&.')).star();

  // Combine the initial optional whitespace, mandatory starting letter, and allowed characters.
  var itemTextContent = optionalInitialWhitespace & startWithLetter & allowedChars;

  // Define a parser that consumes trailing whitespace or stops at a newline or the end of the input.
  var endOfText = (whitespace() | char('\n')).star();

  // Combine everything, flatten, and trim the result to remove any leading or trailing whitespace.
  return (itemTextContent & endOfText).flatten().map((String value) => value.trim());
}

// Parser<String> priceParser() {
//   // Matches a digit with optional surrounding spaces.
//   var digitWithOptionalSpaces = digit().trim().flatten();

//   // Matches at least one digit, allowing spaces between digits.
//   var integerPart = digitWithOptionalSpaces.plus().flatten();

//   // Optional currency symbol with spaces allowed around it.
//   var currencySymbols = pattern('\$€£¥₹₩').optional().trim().flatten();
//   var optionalCurrencySymbol = currencySymbols.optional().trim().flatten();

//   // Matches the decimal separator (period) with optional spaces, followed by exactly two digits, allowing spaces.
//   var decimalPartDigits = digit().seq(whitespace().optional()).seq(digit()).flatten();
//   var optionalDecimalPart = char('.')
//       .trim() // Allow spaces before the period.
//       .seq(decimalPartDigits.trim()) // Allow spaces after the period and between digits.
//       .plus()
//       .flatten();

//   // Combine all parts to form the price parser, then remove all whitespace and currency symbols from the result.
//   return (optionalCurrencySymbol & integerPart & optionalDecimalPart)
//       .flatten()
//       .map((String value) => value.replaceAll(RegExp(r'\s+|[^\d\.]'), ''));
// }

Parser<String> priceParser() {
  // Matches a digit with optional surrounding spaces.
  var digitWithOptionalSpaces = digit().trim().flatten();

  // Matches at least one digit, allowing spaces between digits.
  var integerPart = digitWithOptionalSpaces.plus().flatten();

  // Optional currency symbol with spaces allowed around it.
  var currencySymbols = pattern('\$€£¥₹₩').optional().trim().flatten();
  var optionalCurrencySymbol = currencySymbols.optional().trim().flatten();

  // Matches the decimal separator (period) with optional spaces, followed by exactly two digits, allowing spaces.
  var decimalPartDigits = digit().seq(whitespace().optional()).seq(digit()).flatten();
  var optionalDecimalPart = char('.')
      .trim() // Allow spaces before the period.
      .seq(decimalPartDigits.trim()) // Allow spaces after the period and between digits.
      .plus()
      .flatten()
      .optional();

  // Modify the integer part to be optional and handle cases where it is absent by prepending "0".
  var modifiedIntegerPart =
      integerPart.optional().map((value) => value != null && value.isEmpty ? '0' : value);

  // Combine all parts to form the price parser.
  var combinedParser =
      (pattern('-').not() & optionalCurrencySymbol & modifiedIntegerPart & optionalDecimalPart)
          .flatten()
          .where((value) {
    return value.contains(RegExp(r'[\$€£¥₹₩]')) || value.contains('.');
  }).map((String value) => value.replaceAll(RegExp(r'\s+|[^\d\.]'), ''));

  // Ensure that if the decimal part is present without an integer part, "0" is prepended.
  return combinedParser.map((String value) => value.startsWith('.') ? '0$value' : value);
}

Parser<String> quantityParser() {
  return digit().trim().seq(digit().trim().optional()).flatten().map((value) => value.trim());
}

Parser<String> skipToBarcodeParser() {
  final barcode = barcodeParser();

  // Consume any character until a potential barcode sequence is encountered.
  // The logic here should be adjusted to ensure it matches the start of a valid barcode.
  var skipUntilPotentialBarcode = pattern('^-.').starLazy(barcode).flatten();

  // The final parser sequence: skip until a potential barcode is found, then parse the barcode.
  return skipUntilPotentialBarcode.seq(barcode).map((values) => values[1] as String);
}

Parser<String> skipToItemTextParser() {
  final parser = itemTextParser();

  // This parser lazily consumes any characters until it reaches the condition defined in itemTextParser.
  var skipUntilItemText = any().starLazy(parser).flatten();

  // After skipping, capture the item text. The use of .map((values) => values.last) ensures the return type is String.
  return skipUntilItemText.seq(parser).map((values) => values[1] as String);
}

Parser<String> skipToPriceParser() {
  final parser = priceParser();

  // This parser lazily consumes any characters until it reaches the condition defined in priceParser.
  var skipUntilPrice = any().starLazy(parser).flatten();

  // After skipping, capture the price. The use of .map((values) => values.last) ensures the return type is String.
  return skipUntilPrice.seq(parser).map((values) => values[1] as String);
}

Parser<String> skipToQuantityParser() {
  final parser = quantityParser();

  // This parser lazily consumes any characters until it reaches the condition defined in quantityParser.
  var skipUntilQuantity = any().starLazy(parser).flatten();

  // After skipping, capture the quantity. The use of .map((values) => values.last) ensures the return type is String.
  return skipUntilQuantity.seq(parser).map((values) => values[1] as String);
}

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
        if (line.toLowerCase().contains('subtotal')) {
          _subtotalTracker.add(result.price!);
          doneParsingItems = true;
          continue;
        } else if (line.toLowerCase().contains('total')) {
          _totalTracker.add(result.price!);
          doneParsingItems = true;
          continue;
        } else if (line.toLowerCase().contains('tax')) {
          _taxTracker.add(result.price!);
          doneParsingItems = true;
          continue;
        } else if (line.toLowerCase().contains('discount')) {
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
