import 'package:receipt_parser/error_corrector.dart';
import 'package:receipt_parser/model/receipt.dart';
import 'package:receipt_parser/model/receipt_item.dart';
import 'package:receipt_parser/ocr_text.dart';
import 'package:receipt_parser/order_tracker.dart';
import 'package:receipt_parser/util/frequency_tracker.dart';

abstract class ReceiptParser {
  final FrequencyTracker<double> totalTracker = FrequencyTracker<double>();
  final FrequencyTracker<double> subtotalTracker = FrequencyTracker<double>();
  final FrequencyTracker<double> taxTracker = FrequencyTracker<double>();
  final FrequencyTracker<DateTime> dateTracker = FrequencyTracker<DateTime>();
  final FrequencyTracker<double> discountTracker = FrequencyTracker<double>();
  final ErrorCorrector errorCorrector = ErrorCorrector();
  final OcrText ocrText = OcrText();

  RelativeOrderTracker orderTracker = RelativeOrderTracker();
  String get rawText;
  ParsedReceipt get receipt;
  String getSearchUrl(String barcode) => 'https://www.google.com/search?q=$barcode';

  void parse(String text);

  List<ParsedReceiptItem> sortItems(List<ParsedReceiptItem> items) {
    // Create a map for quick access to items by their barcode
    final itemMap = {for (final item in items) item.barcode: item};

    // Use the order in canonicalOrder to sort items
    List<ParsedReceiptItem> sortedItems = [];
    for (final barcode in orderTracker.canonicalOrder.keys) {
      if (itemMap.containsKey(barcode)) {
        sortedItems.add(itemMap[barcode]!);
      }
    }

    return sortedItems;
  }

  bool validateBarcode(String barcode) => true;
  bool validatePrice(double price) => price > 0.0 && price < 1000.0;
}
