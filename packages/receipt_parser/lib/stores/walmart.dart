import 'package:intl/intl.dart';
import 'package:log/log.dart';
import 'package:receipt_parser/error_corrector.dart';
import 'package:receipt_parser/model/receipt.dart';
import 'package:receipt_parser/model/receipt_item.dart';
import 'package:receipt_parser/parser.dart';
import 'package:receipt_parser/util/frequency_tracker.dart';
import 'package:receipt_parser/util/receipt_item_frequency.dart';

class WalmartParser extends ReceiptParser {
  String _rawText = '';
  final List<String> commonWords = [
    'SUBTOTAL',
    'SAVINGS',
    'TOTAL',
    'DEBIT',
    'CREDIT',
    'TAX',
    'WAS',
    'YOU',
    'SAVED',
    'CASH',
    'TEND',
    'ITEMS',
    'SOLD',
  ];

  final FrequencyTracker<double> _totalTracker = FrequencyTracker<double>();

  final FrequencyTracker<double> _subtotalTracker = FrequencyTracker<double>();
  final FrequencyTracker<double> _taxTracker = FrequencyTracker<double>();
  final FrequencyTracker<DateTime> _dateTracker = FrequencyTracker<DateTime>();
  final ReceiptItemFrequencySet _frequencySet = ReceiptItemFrequencySet();
  final ErrorCorrector _errorCorrector = ErrorCorrector();
  WalmartParser() {
    _errorCorrector.addWords(commonWords);
  }

  @override
  String get rawText => _rawText;

  @override
  Receipt get receipt {
    return Receipt(
      items: _frequencySet.items,
      date: _dateTracker.getMostFrequent() ?? DateTime.now(),
      subtotal: _subtotalTracker.getMostFrequent() ?? 0.0,
      tax: _taxTracker.getMostFrequent() ?? 0.0,
      total: _totalTracker.getMostFrequent() ?? 0.0,
    );
  }

  // Correct common OCR errors in item names
  String correctNameErrors(String text) {
    final nameRegex = RegExp(r"\b([A-Z0\s\']+)\b");
    String replaceZerosWithOs(Match match) {
      String matchedName = match.group(1) ?? '';
      matchedName = matchedName.replaceAll('0', 'O');
      return matchedName;
    }

    return text.replaceAllMapped(nameRegex, replaceZerosWithOs);
  }

  // Perform general error correction on the receipt text
  String errorCorrection(String text) {
    text = correctNameErrors(text);
    text = _errorCorrector.correctErrors(text);
    return text;
  }

  @override
  String getSearchUrl(String barcode) {
    return 'https://www.walmart.com/search/?query=$barcode';
  }

  @override
  void parse(String text) {
    text = errorCorrection(text);
    _rawText = text;

    final lines = text.split('\n');

    for (final line in lines) {
      if (_isItemLine(line)) {
        final currentItem = _parseItemLine(line);
        if (currentItem != null) {
          _frequencySet.add(currentItem);
        }
      } else {
        _parseNonItemLine(line);
      }
    }
  }

  bool _isDateLine(String line) {
    final dateRegex = RegExp(r'\d{2}/\d{2}/\d{2}');
    return dateRegex.hasMatch(line);
  }

  // Determine if a line contains an item entry
  bool _isItemLine(String line) {
    return RegExp(r"(\d{9})\s+[A-Z\s'&]+ \$\d+\.\d{2}").hasMatch(line);
  }

  // Determine if a line contains the subtotal
  bool _isSubtotalLine(String line) {
    return line.trim().startsWith('SUBTOTAL \$');
  }

  // Determine if a line contains the tax
  bool _isTaxLine(String line) {
    return line.trim().startsWith('TAX \$');
  }

  // Determine if a line contains the total price
  bool _isTotalLine(String line) {
    return line.trim().startsWith('TOTAL \$');
  }

  // Parse and extract date and time information from the receipt
  DateTime? _parseDateLine(String line) {
    final dateRegex = RegExp(r'(\d{2}/\d{2}/\d{2}) (\d{2}:\d{2}:\d{2})');
    final match = dateRegex.firstMatch(line);

    if (match != null) {
      final dateString = match.group(1)!;
      final timeString = match.group(2)!;
      try {
        final format = DateFormat('MM/dd/yy HH:mm:ss');
        return format.parse('$dateString $timeString', true);
      } catch (e) {
        Log.e('Error parsing date: $e');
        return null;
      }
    }
    return null;
  }

  // Parse a line to determine if it is an item line and extract details
  ReceiptItem? _parseItemLine(String line) {
    final strictItemRegex = RegExp(r"(\d{9})\s+([A-Z\s'&]+)\s+\$(\d+\.\d{2})");
    final strictMatch = strictItemRegex.firstMatch(line);

    if (strictMatch != null) {
      final barcode = strictMatch.group(1)!.trim();
      var name = strictMatch.group(2)!.trim();
      final priceString = strictMatch.group(3);
      final price = priceString != null ? double.tryParse(priceString) ?? 0.0 : 0.0;

      return ReceiptItem(name: name, barcode: barcode, price: price);
    }
    return null;
  }

  // Parse non-item lines for date, totals, tax, etc.
  void _parseNonItemLine(String line) {
    // Date line
    if (_isDateLine(line)) {
      final DateTime? parsedDate = _parseDateLine(line);
      if (parsedDate != null) {
        _dateTracker.add(parsedDate);
      }
    }

    // Total line
    else if (_isTotalLine(line)) {
      final double parsedTotal = _parsePriceLine(line);
      if (parsedTotal != 0) {
        _totalTracker.add(parsedTotal);
      }
    }

    // Subtotal line
    else if (_isSubtotalLine(line)) {
      final double parsedSubtotal = _parsePriceLine(line);
      if (parsedSubtotal != 0) {
        _subtotalTracker.add(parsedSubtotal);
      }
    }

    // Tax line
    else if (_isTaxLine(line)) {
      final double parsedTax = _parsePriceLine(line);
      if (parsedTax != 0) {
        _taxTracker.add(parsedTax);
      }
    }
  }

  // Extract price from a line
  double _parsePriceLine(String line) {
    final priceRegex = RegExp(r'\$?(\d+\.\d{2})');
    final match = priceRegex.firstMatch(line);
    return match != null ? double.tryParse(match.group(1)!) ?? 0.0 : 0.0;
  }
}
