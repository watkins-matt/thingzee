import 'package:repository/model/receipt.dart';
import 'package:repository/model/receipt_item.dart';
import 'package:thingzee/pages/receipt_scanner/parser/error_corrector.dart';
import 'package:thingzee/pages/receipt_scanner/parser/ocr_text.dart';
import 'package:thingzee/pages/receipt_scanner/parser/order_tracker.dart';
import 'package:thingzee/pages/receipt_scanner/util/frequency_tracker.dart';

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
  Receipt get receipt;
  String getSearchUrl(String barcode);
  void parse(String text);

  List<ReceiptItem> sortItems(List<ReceiptItem> items) {
    // Create a map for quick access to items by their barcode
    final itemMap = {for (final item in items) item.barcode: item};

    // Use the order in canonicalOrder to sort items
    List<ReceiptItem> sortedItems = [];
    for (final barcode in orderTracker.canonicalOrder.keys) {
      if (itemMap.containsKey(barcode)) {
        sortedItems.add(itemMap[barcode]!);
      }
    }

    return sortedItems;
  }
}
