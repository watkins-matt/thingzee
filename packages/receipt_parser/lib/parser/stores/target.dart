import 'dart:math';

import 'package:petitparser/petitparser.dart';
import 'package:receipt_parser/model/receipt.dart';
import 'package:receipt_parser/model/receipt_item.dart';
import 'package:repository/database/identifier_database.dart';

import '../element/date.dart';
import '../element/phone_number.dart';
import '../element/price.dart';
import '../element/quantity.dart';
import '../element/time.dart';
import '../generic_parser.dart';
import '../ocr_text.dart';

Parser<double> skipToTargetBottleDepositFeeParser() {
  final parser = targetBottleDepositFeeParser();

  // This parser lazily consumes any characters until it reaches the condition defined in targetBottleDepositFeeParser.
  var skipUntilPrice = any().starLazy(parser).flatten();

  // After skipping, capture the price. The use of .map((values) => values.last) ensures the return type is String.
  return skipUntilPrice.seq(parser).map((values) => values[1] as double);
}

Parser<TargetQuantityParseResult> skipToTargetQuantityParser() {
  final parser = targetQuantityParser();

  // This parser lazily consumes any characters until it reaches the condition defined in quantityParser.
  var skipUntilQuantity = any().starLazy(parser).flatten();

  // After skipping, capture the quantity. The use of .map((values) => values.last) ensures the return type is String.
  return skipUntilQuantity.seq(parser).map((values) => values[1] as TargetQuantityParseResult);
}

Parser<double> skipToTargetRegularPriceParser() {
  final parser = targetRegularPriceParser();

  // This parser lazily consumes any characters until it reaches the condition defined in targetRegularPriceParser.
  var skipUntilPrice = any().starLazy(parser).flatten();

  // After skipping, capture the price. The use of .map((values) => values.last) ensures the return type is String.
  return skipUntilPrice.seq(parser).map((values) => values[1] as double);
}

// Create a parser for "Bottle Deposit Fee $0.10" lines
Parser<double> targetBottleDepositFeeParser() {
  return (string('Bottle') &
          whitespace().star() &
          string('Deposit') &
          whitespace().star() &
          string('Fee') &
          whitespace().star() &
          priceParser())
      .map((values) => double.tryParse(values[6] as String) ?? 0.0);
}

// Parses "5 @ $10.99 ea" lines
Parser<TargetQuantityParseResult> targetQuantityParser() {
  return (quantityParser() &
          whitespace().optional() &
          char('@').trim() &
          whitespace().optional() &
          priceParser() &
          whitespace().optional() &
          string('ea'))
      .map((values) {
    final int quantity = int.parse(values[0] as String);
    final double price = double.tryParse(values[4] as String) ?? 0;
    return (quantity: quantity, price: price);
  });
}

// Parses "Regular Price $10.99" lines,
Parser<double> targetRegularPriceParser() {
  return (string('Regular') &
          whitespace().star() &
          string('Price') &
          whitespace().star() &
          priceParser())
      .map((values) => double.tryParse(values[4] as String) ?? 0.0);
}

typedef TargetQuantityParseResult = ({int quantity, double price});

class TargetReceiptParser extends GenericReceiptParser {
  String _phoneNumber = '';
  final List<ReceiptItem> _items = [];
  final List<String> commonWords = [
    'Regular',
    'Price',
    'Bottle',
    'Deposit',
    'Fee',
    'Bag',
    'SUBTOTAL',
    'RedCard',
    'Savings',
    'TOTAL',
    'TARGET',
    'DEBIT',
    'CARD',
    'California',
    'Wellness'
  ];

  TargetReceiptParser() {
    errorCorrector.addWords(commonWords);
  }

  String get phoneNumber => _phoneNumber;

  @override
  Receipt get receipt {
    return Receipt(
      items: _items,
      date: dateTracker.getMostFrequent() ?? DateTime.now(),
      subtotal: subtotalTracker.getMostFrequent() ?? 0.0,
      discounts: discountTracker.getMostFrequentList(),
      tax: taxTracker.getMostFrequent() ?? 0.0,
      total: totalTracker.getMostFrequent() ?? 0.0,
      barcodeType: IdentifierType.target,
    );
  }

  String correctBarcodeDot(String text) {
    // Correcting any 10-digit numbers with a . in a random spot
    RegExp tenDigitWithDotRegExp = RegExp(r'\b(\d{1,9})\.(\d{1,9})\b');
    text = text.replaceAllMapped(tenDigitWithDotRegExp, (match) {
      // Combine the parts before and after the period
      // Ensure the total length is 10 digits, accounting for the removed period
      if ((match[1]!.length + match[2]!.length) == 10) {
        return '${match[1]}${match[2]}';
      }
      // If the total length isn't 10, return the original match to avoid altering unintended patterns
      return match[0]!;
    });
    return text;
  }

  String extractCodes(String name) {
    final codesRegex = RegExp(r'\s+([A-Z]{1,2}(?:\s+[A-Z]{1,2})*)$');
    final codesMatch = codesRegex.firstMatch(name);
    var codes = '';
    if (codesMatch != null) {
      codes = codesMatch.group(1) ?? '';
      name = name.replaceAll(codesRegex, '');
    }
    return codes;
  }

  int findFirstValidLine(String text) {
    final splitText = text.split('\n');
    for (int i = 0; i < splitText.length; i++) {
      final line = splitText[i];
      final result = parseLine(line);
      if (result.price != null && result.text != null && result.barcode != null) {
        return i;
      }
    }

    return -1;
  }

  int findLastValidLine(String text) {
    final splitText = text.split('\n');
    for (int i = splitText.length - 1; i >= 0; i--) {
      final line = splitText[i];

      // Text after the auth code line is not useful
      if (line.toLowerCase().contains('auth code')) {
        return i;
      }

      final result = parseLine(line);
      if (result.price != null && result.text != null && result.barcode != null) {
        return i;
      }
    }

    return -1;
  }

  @override
  String getSearchUrl(String barcode) => 'https://www.target.com/s?searchTerm=$barcode';

  @override
  void parse(String text) {
    _items.clear();
    text = errorCorrector.correctErrors(text);
    text = correctBarcodeDot(text);

    OcrText newText = OcrText.fromString(text);
    ocrText.merge(newText);

    bool startedParsing = false;
    bool doneParsingItems = false;
    final splitText = ocrText.text.split('\n');

    DateTime? date;

    final phoneNumber = skipToPhoneNumberParser();
    final phoneResult = phoneNumber.parse(text);
    if (phoneResult is Success) {
      _phoneNumber = phoneResult.value;
    }

    // Try to parse the date
    final dateParser = skipToDateParser();
    final dateResult = dateParser.parse(text);
    if (dateResult is Success) {
      date = DateTime.parse(dateResult.value);
    }

    // Try to parse time
    final timeParser = skipToTimeParser();
    final timeResult = timeParser.parse(text);
    if (timeResult is Success) {
      final time = timeResult.value.to24HourTime();
      final timePattern = RegExp(r'^(\d{1,2}):(\d{2})');
      final match = timePattern.firstMatch(time);

      if (match != null) {
        final hour = int.parse(match.group(1)!);
        final minute = int.parse(match.group(2)!);
        date = date?.add(Duration(hours: hour, minutes: minute));
      }
    }

    if (date != null) {
      dateTracker.add(date);
    }

    final skipToTargetQuantity = skipToTargetQuantityParser();
    final skipToTargetRegularPrice = skipToTargetRegularPriceParser();
    final skipToTargetBottleDepositFee = skipToTargetBottleDepositFeeParser();

    for (final line in splitText) {
      final result = parseLine(line);

      // Don't start parsing until we reach the first price
      if (result.price != null) {
        startedParsing = true;
      }

      // We have only encountered unrelated text on the receipt so far
      // so don't build any items yet
      if (!startedParsing) {
        continue;
      }

      // Check for bottle deposit
      final parseBottleDeposit = skipToTargetBottleDepositFee.parse(line);
      if (parseBottleDeposit is Success) {
        final fee = parseBottleDeposit.value;

        // If _items has a last item, we should add the bottle deposit to it
        if (_items.isNotEmpty) {
          _items.last = _items.last.copyWith(bottleDeposit: fee);
        }

        continue;
      }

      // Check for 2 @ $10.99 ea type lines
      final parsedQuantity = skipToTargetQuantity.parse(line);
      if (parsedQuantity is Success) {
        final result = parsedQuantity.value;
        final quantity = result.quantity;
        final price = result.price;

        if (_items.isNotEmpty) {
          final totalPrice = quantity * price;
          final existingPrice = _items.last.price;
          final correctPrice = max(totalPrice, existingPrice);

          _items.last = _items.last.copyWith(quantity: quantity, price: correctPrice);
        }

        continue;
      }

      // Check for Regular Price $10.99 type lines
      final parsedRegularPrice = skipToTargetRegularPrice.parse(line);
      if (parsedRegularPrice is Success) {
        final price = parsedRegularPrice.value;

        // If _items has a last item, we should add the regular price to it
        if (_items.isNotEmpty) {
          _items.last = _items.last.copyWith(regularPrice: price);
        }

        continue;
      }

      // If we have a full line, we can process the items
      if (!doneParsingItems && result.count == 3) {
        final barcode = result.barcode;
        var itemText = result.text;
        final price = result.price;
        final codes = extractCodes(itemText!).trim();

        // Remove all codes from the item text
        itemText = itemText.replaceAll(codes, '').trim();

        ReceiptItem item = ReceiptItem(
          barcode: barcode!,
          name: itemText,
          price: price!,
          taxable: codes.contains('T'),
        );

        _items.add(item);
        continue;
      } else if (!doneParsingItems &&
          result.count == 2 &&
          result.text != null &&
          result.barcode != null) {
        final barcode = result.barcode;
        var itemText = result.text;
        final codes = extractCodes(itemText!).trim();

        // Remove all codes from the item text
        itemText = itemText.replaceAll(codes, '').trim();

        ReceiptItem item = ReceiptItem(
          barcode: barcode!,
          name: itemText,
          price: 0,
          taxable: codes.contains('T'),
        );

        _items.add(item);
        continue;
      }

      // If we have text and a price, we can add the item
      else if (result.count == 2 && result.text != null && result.price != null) {
        // Check for special fields at the end of the receipt
        if (line.toLowerCase().contains('subtotal')) {
          subtotalTracker.add(result.price!);
          doneParsingItems = true;
          continue;
        } else if (line.toLowerCase().contains('total')) {
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
      }
    }
  }

  @override
  bool validateBarcode(String barcode) {
    int digitCount = barcode.replaceAll(RegExp(r'[^0-9]'), '').length;
    return digitCount == barcode.length && barcode.length == 9;
  }
}
