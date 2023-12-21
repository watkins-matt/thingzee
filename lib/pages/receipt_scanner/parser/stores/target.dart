import 'package:intl/intl.dart';
import 'package:log/log.dart';
import 'package:repository/model/receipt.dart';
import 'package:thingzee/pages/receipt_scanner/parser/error_corrector.dart';
import 'package:thingzee/pages/receipt_scanner/parser/order_tracker.dart';
import 'package:thingzee/pages/receipt_scanner/parser/parser.dart';
import 'package:thingzee/pages/receipt_scanner/util/frequency_tracker.dart';
import 'package:thingzee/pages/receipt_scanner/util/receipt_item_frequency.dart';

class TargetParser extends ReceiptParser {
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

  final FrequencyTracker<double> _totalTracker = FrequencyTracker<double>();
  final FrequencyTracker<double> _subtotalTracker = FrequencyTracker<double>();
  final FrequencyTracker<double> _taxTracker = FrequencyTracker<double>();
  final FrequencyTracker<DateTime> _dateTracker = FrequencyTracker<DateTime>();
  final FrequencyTracker<double> _discountTracker = FrequencyTracker<double>();
  final ReceiptItemFrequencySet _frequencySet = ReceiptItemFrequencySet();
  final ErrorCorrector _errorCorrector = ErrorCorrector();

  TargetParser() {
    _errorCorrector.addWords(commonWords);
  }

  @override
  Receipt get receipt {
    return Receipt(
      items: _frequencySet.items,
      date: _dateTracker.getMostFrequent() ?? DateTime.now(),
      subtotal: _subtotalTracker.getMostFrequent() ?? 0.0,
      discounts: _discountTracker.getMostFrequentList(),
      tax: _taxTracker.getMostFrequent() ?? 0.0,
      total: _totalTracker.getMostFrequent() ?? 0.0,
    );
  }

  Receipt get sortedReceipt {
    final items = _frequencySet.items;
    sortItems(items);

    return Receipt(
      items: items,
      date: _dateTracker.getMostFrequent() ?? DateTime.now(),
      subtotal: _subtotalTracker.getMostFrequent() ?? 0.0,
      discounts: _discountTracker.getMostFrequentList(),
      tax: _taxTracker.getMostFrequent() ?? 0.0,
      total: _totalTracker.getMostFrequent() ?? 0.0,
    );
  }

  String correctNameErrors(String text) {
    // Regex pattern: Captures words that are in ALL CAPS,
    //possibly containing spaces or apostrophes
    final nameRegex = RegExp(r"\b([ÁA-Z0\s\']+)\b");

    // Function to replace '0' with 'O' in matched names
    String replaceZerosWithOs(Match match) {
      String matchedName = match.group(1) ?? '';
      matchedName = matchedName.replaceAll('0', 'O');
      return matchedName.replaceAll('Á', 'A');
    }

    // Replace in the whole text
    return text.replaceAllMapped(nameRegex, replaceZerosWithOs);
  }

  String errorCorrection(String text) {
    // Correct 0/O mismatches in item names
    text = correctNameErrors(text);

    // Correct other errors
    text = _errorCorrector.correctErrors(text);

    // Merge price lines that are alone
    text = mergePriceLines(text);

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

  String mergePriceLines(String text) {
    List<String> lines = text.split('\n');
    RegExp pricePattern = RegExp(r'^([A-Z]+\s*)*\$\d+\.\d{2}$');
    RegExp numberStartPattern = RegExp(r'^\d{9}');
    RegExp bottleDepositPattern = RegExp(r'^Bottle Deposit Fee');

    for (int i = 0; i < lines.length; i++) {
      // Check if the current line matches the price pattern
      if (pricePattern.hasMatch(lines[i])) {
        // Look at the previous line if not the first line
        if (i > 0 && numberStartPattern.hasMatch(lines[i - 1]) && !lines[i - 1].contains('\$')) {
          lines[i - 1] += ' ${lines[i]}';
          lines.removeAt(i);
          i--; // Adjust the index after removing an element
        }

        // Look at the next line if not the last line
        else if (i < lines.length - 1 &&
            numberStartPattern.hasMatch(lines[i + 1]) &&
            !lines[i + 1].contains('\$')) {
          lines[i + 1] += ' ${lines[i]}';
          lines.removeAt(i);
          i--;
        }

        // Check to see if there is a "Bottle Deposit Fee" line above or below
        else if (i > 0 &&
            bottleDepositPattern.hasMatch(lines[i - 1]) &&
            !lines[i - 1].contains('\$')) {
          lines[i - 1] += ' ${lines[i]}';
          lines.removeAt(i);
          i--;
        } else if (i < lines.length - 1 &&
            bottleDepositPattern.hasMatch(lines[i + 1]) &&
            !lines[i + 1].contains('\$')) {
          lines[i + 1] += ' ${lines[i]}';
          lines.removeAt(i);
          i--;
        }
      }
    }

    return lines.join('\n');
  }

  @override
  void parse(String text) {
    final page = OrderedPage();

    text = errorCorrection(text);
    final lines = text.split('\n');

    ReceiptItem? currentItem;

    for (final line in lines) {
      if (_isItemLine(line)) {
        currentItem = _parseItemLine(line);

        if (currentItem != null && currentItem.price != 0) {
          _frequencySet.add(currentItem);
          page.add(currentItem.barcode);
        }
      }
      // Found a quantity price line
      else if (currentItem != null && _isQuantityPriceLine(line)) {
        currentItem = _parseQuantityPriceLine(line, currentItem);
        _frequencySet.add(currentItem);
      }
      // Found a regular price line
      else if (currentItem != null && _isRegularPriceLine(line)) {
        currentItem = _parseRegularPriceLine(line, currentItem);
        _frequencySet.add(currentItem);
      }
      // Found a bottle deposit fee line
      else if (currentItem != null && _isBottleDepositFeeLine(line)) {
        final depositFee = _parseBottleDepositLine(line);
        currentItem = currentItem.copyWith(price: currentItem.price + depositFee);
        _frequencySet.add(currentItem);
      } else {
        _parseNonItemLine(line);
      }
    }

    orderTracker.addPage(page);
  }

  bool _isBottleDepositFeeLine(String line) {
    return line.contains(RegExp(r'Bottle Deposit Fee \$\d+\.\d{2}'));
  }

  bool _isDateLine(String line) {
    return RegExp(r'\d{1,2}/\d{1,2}/\d{4} \d{1,2}:\d{2} [AP]M').hasMatch(line);
  }

  bool _isDiscountLine(String line) {
    return RegExp(r'.+ (Discount|Savings) \$\d+\.\d{2}').hasMatch(line);
  }

  bool _isItemLine(String line) {
    final itemRegex = RegExp(r"(\d{9,})\s+([A-Z\s'&]+)");
    return itemRegex.hasMatch(line);
  }

  bool _isQuantityPriceLine(String line) {
    final quantityPriceRegex = RegExp(r'(\d+) @ \$([0-9]+\.[0-9]{2}) ea');
    return quantityPriceRegex.hasMatch(line);
  }

  bool _isRegularPriceLine(String line) {
    final regularPriceRegex = RegExp(r'Regular Price \$([0-9]+\.[0-9]{2})');
    return regularPriceRegex.hasMatch(line);
  }

  bool _isSubtotalLine(String line) {
    return line.startsWith('SUBTOTAL \$');
  }

  bool _isTaxLine(String line) {
    return line.startsWith('T = CA TAX');
  }

  bool _isTotalLine(String line) {
    return line.startsWith('TOTAL \$');
  }

  double _parseBottleDepositLine(String line) {
    final priceRegex = RegExp(r'\$?(\d+\.\d{2})');
    final match = priceRegex.firstMatch(line);
    return match != null ? double.parse(match.group(1)!) : 0.0;
  }

  DateTime? _parseDateLine(String line) {
    final dateRegex = RegExp(r'(\d{1,2}/\d{1,2}/\d{4}) (\d{1,2}:\d{2} [AP]M)');
    final match = dateRegex.firstMatch(line);

    if (match != null) {
      final dateString = match.group(1)!;
      final timeString = match.group(2)!;

      try {
        final format = DateFormat('MM/dd/yyyy hh:mm a');
        return format.parse('$dateString $timeString', true);
      } catch (e) {
        Log.e('Error parsing date: $e');
        return null;
      }
    }

    return null;
  }

  ReceiptItem? _parseItemLine(String line) {
    final strictItemRegex = RegExp(r"(\d{9,})\s+([A-Z&'\s]+)\s+\$?(\d*\.\d{2})");
    final strictMatch = strictItemRegex.firstMatch(line);

    // If strict regex matches, extract detailed information
    if (strictMatch != null) {
      final barcode = strictMatch.group(1)!.trim();
      var name = strictMatch.group(2)!.trim();
      final priceString = strictMatch.group(3);
      final price = priceString != null ? double.tryParse(priceString) ?? 0.0 : 0.0;

      final codes = extractCodes(name);
      name = name.replaceAll(codes, '').trim();

      bool taxable = !codes.contains('N');

      // print('Found barcode: $barcode, name: $name, price: $price, taxable: $taxable');
      return ReceiptItem(name: name, barcode: barcode, price: price, taxable: taxable);
    }

    // If strict regex fails, use a simpler regex
    final simplerItemRegex = RegExp(r"(\d{9,})\s+([A-Z&'\s]+)");
    final simplerMatch = simplerItemRegex.firstMatch(line);

    if (simplerMatch != null) {
      final barcode = simplerMatch.group(1)!.trim();
      var name = simplerMatch.group(2)!.trim();
      final codes = extractCodes(name);
      name = name.replaceAll(codes, '');

      bool taxable = !codes.contains('N');
      return ReceiptItem(name: name, barcode: barcode, price: 0, taxable: taxable);
    }

    // Return null if we can't parse the line
    return null;
  }

  void _parseNonItemLine(String line) {
    if (_isDateLine(line)) {
      final DateTime? parsedDate = _parseDateLine(line);
      if (parsedDate != null) {
        _dateTracker.add(parsedDate);
      }
    } else if (_isSubtotalLine(line)) {
      final double parsedSubtotal = _parsePriceLine(line);
      if (parsedSubtotal != 0) {
        _subtotalTracker.add(parsedSubtotal);
      }
    } else if (_isDiscountLine(line)) {
      final double parsedDiscount = _parsePriceLine(line);
      if (parsedDiscount != 0) {
        _discountTracker.add(parsedDiscount);
      }
    } else if (_isTaxLine(line)) {
      final double parsedTax = _parsePriceLine(line);
      if (parsedTax != 0) {
        _taxTracker.add(parsedTax);
      }
    } else if (_isTotalLine(line)) {
      final double parsedTotal = _parsePriceLine(line);
      if (parsedTotal != 0) {
        _totalTracker.add(parsedTotal);
      }
    }
  }

  double _parsePriceLine(String line) {
    final priceRegex = RegExp(r'\$?(\d*\.\d{2})');
    final match = priceRegex.firstMatch(line);
    return match != null ? double.tryParse(match.group(1)!) ?? 0.0 : 0.0;
  }

  ReceiptItem _parseQuantityPriceLine(String line, ReceiptItem lastItem) {
    final quantityPriceRegex = RegExp(r'(\d+) @ \$([0-9]+\.[0-9]{2}) ea');
    final match = quantityPriceRegex.firstMatch(line)!;
    final quantity = int.parse(match.group(1)!);
    final individualPrice = double.parse(match.group(2)!);
    return lastItem.copyWith(quantity: quantity, price: individualPrice * quantity);
  }

  ReceiptItem _parseRegularPriceLine(String line, ReceiptItem lastItem) {
    final regularPriceRegex = RegExp(r'Regular Price \$([0-9]+\.[0-9]{2})');
    final match = regularPriceRegex.firstMatch(line)!;
    final regularPrice = double.parse(match.group(1)!);
    return lastItem.copyWith(regularPrice: regularPrice);
  }
}
