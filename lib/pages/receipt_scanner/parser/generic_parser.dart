import 'package:intl/intl.dart';
import 'package:log/log.dart';
import 'package:repository/model/receipt.dart';
import 'package:repository/model/receipt_item.dart';
import 'package:thingzee/pages/receipt_scanner/parser/error_corrector.dart';
import 'package:thingzee/pages/receipt_scanner/parser/parser.dart';
import 'package:thingzee/pages/receipt_scanner/util/frequency_tracker.dart';
import 'package:thingzee/pages/receipt_scanner/util/receipt_item_frequency.dart';

class GenericParser extends ReceiptParser {
  final FrequencyTracker<double> _totalTracker = FrequencyTracker<double>();
  final FrequencyTracker<double> _subtotalTracker = FrequencyTracker<double>();
  final FrequencyTracker<double> _taxTracker = FrequencyTracker<double>();
  final FrequencyTracker<DateTime> _dateTracker = FrequencyTracker<DateTime>();
  final FrequencyTracker<double> _discountTracker = FrequencyTracker<double>();
  final ReceiptItemFrequencySet _frequencySet = ReceiptItemFrequencySet();

  // final RegExp _phonePattern = RegExp(r'\d{3}-\d{3}-\d{4}');
  final RegExp _datePattern = RegExp(r'\d{1,2}/\d{1,2}/\d{2,4}|\d{1,2}-\d{1,2}-\d{2,4}');
  final RegExp _timePattern = RegExp(r'\d{1,2}:\d{2} (AM|PM|am|pm)');
  final RegExp _itemNamePattern = RegExp(r'[A-Za-z0-9\s]+');
  final RegExp _pricePattern = RegExp(r'\$?(\d+\.\d{2})');
  final RegExp _barcodePattern = RegExp(r'\b\d{6,}\b');
  final RegExp _quantityPattern = RegExp(r'\b\d{1,2}\b');

  final RegExp _subtotalPattern = RegExp(r'subtotal', caseSensitive: false);
  final RegExp _taxPattern = RegExp(r'tax', caseSensitive: false);
  final RegExp _totalPattern = RegExp(r'total', caseSensitive: false);
  final ErrorCorrector _errorCorrector = ErrorCorrector();

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

  @override
  void parse(String text) {
    text = _errorCorrector.correctErrors(text);

    final lines = text.split('\n');
    ReceiptItem? lastItem;

    for (final line in lines) {
      if (_isItemLine(line)) {
        final item = _parseItemLine(line);
        if (item != null) {
          _frequencySet.add(item);
          lastItem = item;
        }
      } else {
        _parseNonItemLine(line, lastItem);
      }
    }
  }

  bool _isDateLine(String line) => _datePattern.hasMatch(line);

  bool _isItemLine(String line) {
    return _itemNamePattern.hasMatch(line) &&
        (_pricePattern.hasMatch(line) || _barcodePattern.hasMatch(line));
  }

  // bool _isPhoneLine(String line) => _phonePattern.hasMatch(line);
  bool _isSubtotalLine(String line) => _subtotalPattern.hasMatch(line);
  bool _isTaxLine(String line) => _taxPattern.hasMatch(line);
  bool _isTimeLine(String line) => _timePattern.hasMatch(line);
  bool _isTotalLine(String line) => _totalPattern.hasMatch(line);

  DateTime? _parseDate(String line) {
    final match = _datePattern.firstMatch(line);
    if (match != null) {
      try {
        final format = DateFormat('MM/dd/yyyy');
        return format.parse(match.group(0)!, true);
      } catch (e) {
        Log.e('Error parsing date: $e');
        return null;
      }
    }
    return null;
  }

  ReceiptItem? _parseItemLine(String line) {
    final itemNameMatch = _itemNamePattern.firstMatch(line);
    final priceMatch = _pricePattern.firstMatch(line);
    final barcodeMatch = _barcodePattern.firstMatch(line);
    final quantityMatch = _quantityPattern.firstMatch(line);

    if (itemNameMatch != null) {
      String name = itemNameMatch.group(0)!;
      double? price = priceMatch != null ? double.tryParse(priceMatch.group(1)!) : null;
      String? barcode = barcodeMatch?.group(0);
      int quantity = quantityMatch != null ? int.parse(quantityMatch.group(0)!) : 1;

      return ReceiptItem(
          name: name,
          barcode: barcode ?? '',
          price: price ?? 0.0,
          quantity: quantity,
          taxable: true);
    }

    return null;
  }

  void _parseNonItemLine(String line, ReceiptItem? lastItem) {
    if (_isSubtotalLine(line)) {
      final subtotal = _parsePrice(line);
      _subtotalTracker.add(subtotal);
    } else if (_isTaxLine(line)) {
      final tax = _parsePrice(line);
      _taxTracker.add(tax);
    } else if (_isTotalLine(line)) {
      final total = _parsePrice(line);
      _totalTracker.add(total);
    } else if (_isDateLine(line) || _isTimeLine(line)) {
      final date = _parseDate(line);
      if (date != null) {
        _dateTracker.add(date);
      }
    }
  }

  double _parsePrice(String line) {
    final match = _pricePattern.firstMatch(line);
    return match != null ? double.parse(match.group(0)!.replaceAll('\$', '')) : 0.0;
  }
}
