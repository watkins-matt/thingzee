import 'package:petitparser/petitparser.dart';
import 'package:repository/model/receipt.dart';
import 'package:repository/model/receipt_item.dart';
import 'package:thingzee/pages/receipt_scanner/parser/element/barcode.dart';
import 'package:thingzee/pages/receipt_scanner/parser/element/item_text.dart';
import 'package:thingzee/pages/receipt_scanner/parser/element/price.dart';
import 'package:thingzee/pages/receipt_scanner/parser/element/quantity.dart';
import 'package:thingzee/pages/receipt_scanner/parser/ocr_text.dart';
import 'package:thingzee/pages/receipt_scanner/parser/parser.dart';

enum ItemState { empty, primaryLine, secondaryLine, extraInfo }

enum LineElement { barcode, name, price, regularPrice, quantity }

mixin ParserFactory on ReceiptParser {
  ReceiptItem? currentItem;
  ItemState currentState = ItemState.empty;

  final List<ReceiptItem> _items = [];
  Map<LineElement, Parser<String>> elementToParser = {
    LineElement.barcode: barcodeParser(),
    LineElement.name: itemTextParser(),
    LineElement.price: priceParser(),
    LineElement.regularPrice: priceParser(),
    LineElement.quantity: quantityParser(),
  };

  List<LineElement> get primaryLineFormat;

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

  List<LineElement>? get secondaryLineFormat;

  ReceiptItem createNewItemFromPrimary(Map<LineElement, String> results) {
    var price = double.tryParse(results[LineElement.price] ?? '0') ?? 0.0;
    var regularPrice = double.tryParse(results[LineElement.regularPrice] ?? '0') ?? price;

    return ReceiptItem(
      barcode: results[LineElement.barcode] ?? '',
      name: results[LineElement.name] ?? '',
      price: price,
      regularPrice: regularPrice,
      quantity: 1, // Default quantity
      taxable: true, // Assuming taxable by default
      bottleDeposit: 0, // Assuming no bottle deposit by default
    );
  }

  void finalizeCurrentItem() {
    if (currentItem != null) {
      _items.add(currentItem!);
      currentItem = null;
    }
  }

  @override
  void parse(String text) {
    _items.clear();
    currentItem = null;
    currentState = ItemState.empty;
    text = errorCorrector.correctErrors(text);

    OcrText newText = OcrText.fromString(text);
    ocrText.merge(newText);

    final splitText = ocrText.text.split('\n');

    for (final line in splitText) {
      parseLine(line);
    }

    // Finalize the last item if it exists after exiting the loop
    finalizeCurrentItem();
  }

  /// Called once we have already parsed the primary and possibly secondary
  /// line. This method checks if the line contains primary data, and if not,
  /// treats it as extra info. If the line contains primary data, it finalizes
  /// the current item and starts a new one.
  void parseExtraInfoOrNewPrimary(String line) {
    // Check to see if the line contains primary data
    var extraPrimaryResults = parseLineAccordingToFormat(line, primaryLineFormat);

    // The line does not have primary data, so treat it as extra info
    if (extraPrimaryResults.isEmpty) {
      currentItem = parseSpecialCases(currentItem!, line);
      currentState = ItemState.extraInfo;
    }

    // The line contains primary data, so finalize the current item and start a new one
    else {
      finalizeCurrentItem();
      currentItem = createNewItemFromPrimary(extraPrimaryResults);
      currentState = ItemState.primaryLine;
    }
  }

  void parseLine(String line) {
    switch (currentState) {
      // Attempt to parse the primary line format when we have no current item data
      case ItemState.empty:
        parsePrimaryLine(line);
        break;
      // Try parsing secondary line format or handle as extra info
      case ItemState.primaryLine:
        parseSecondaryLineOrExtraInfo(line);
        break;
      // Look for a new primary line or treat as additional extra info
      case ItemState.secondaryLine:
      case ItemState.extraInfo:
        parseNewPrimaryLineOrExtraInfo(line);
        break;
    }
  }

  Map<LineElement, String> parseLineAccordingToFormat(String line, List<LineElement> format) {
    if (format.isEmpty) {
      throw ArgumentError('Format list cannot be empty.');
    }

    List<Parser> parsers = format
        .map((element) => elementToParser[element] ?? FailureParser('Unknown element'))
        .toList();

    if (parsers.isEmpty || parsers.any((parser) => parser is FailureParser)) {
      throw ArgumentError('There must be a valid parser for each element in the format.');
    }

    // Start with the first parser in the list
    Parser<List<dynamic>> compositeParser = parsers.first.map((result) => [result]);

    // Sequentially combine each subsequent parser
    for (var i = 1; i < parsers.length; i++) {
      compositeParser = compositeParser.seq(parsers[i]).map((List<dynamic> results) {
        // The current results list contains the accumulated results in the first slot
        // and the latest result as the second slot
        var accumulatedResults = results[0] as List;
        var newResult = results[1];
        return accumulatedResults..add(newResult);
      });
    }

    var result = compositeParser.parse(line);

    Map<LineElement, String> parsedResults = {};
    if (result is Success) {
      List<dynamic> values = result.value;
      for (int i = 0; i < format.length; i++) {
        parsedResults[format[i]] = values[i] as String;
      }
    }

    return parsedResults;
  }

  void parseNewPrimaryLineOrExtraInfo(String line) {
    var newPrimaryResults = parseLineAccordingToFormat(line, primaryLineFormat);
    if (newPrimaryResults.isNotEmpty) {
      finalizeCurrentItem();
      currentItem = createNewItemFromPrimary(newPrimaryResults);
      currentState = ItemState.primaryLine; // Start new item
    } else {
      currentItem = parseSpecialCases(currentItem!, line); // Continue accumulating extra info
    }
  }

  void parsePrimaryLine(String line) {
    var primaryResults = parseLineAccordingToFormat(line, primaryLineFormat);
    if (primaryResults.isNotEmpty) {
      currentItem = createNewItemFromPrimary(primaryResults);
      currentState = ItemState.primaryLine; // We now have primary data
    }
  }

  void parseSecondaryLineOrExtraInfo(String line) {
    // If we have a secondary line format, try parsing it first
    if (secondaryLineFormat != null) {
      var secondaryResults = parseLineAccordingToFormat(line, secondaryLineFormat!);
      if (secondaryResults.isNotEmpty) {
        updateCurrentItemWithSecondary(secondaryResults);
        currentState = ItemState.secondaryLine; // We have secondary data
        return; // Ready for extra info or new primary line
      }
    }

    // If we don't have a secondary line format, treat the line as extra info
    parseExtraInfoOrNewPrimary(line);
  }

  /// Handles parsing of additional lines that are not item lines, but
  /// contain information that should be included in the item.
  /// For example, if the item is a bottle deposit, the line containing
  /// the bottle deposit amount should be included in the item. The
  /// item returned becomes the new current item.
  /// The default implementation does not do anything, but subclasses
  /// can override this method to handle special cases.
  ReceiptItem parseSpecialCases(ReceiptItem item, String line) {
    return item;
  }

  void updateCurrentItemWithSecondary(Map<LineElement, String> results) {
    if (currentItem != null) {
      // The secondary line might contain updates to price or additional details like bottle deposit
      var updatedPrice = double.tryParse(results[LineElement.price] ?? '') ?? currentItem!.price;
      var updatedRegularPrice =
          double.tryParse(results[LineElement.regularPrice] ?? '') ?? currentItem!.regularPrice;
      var updatedQuantity =
          int.tryParse(results[LineElement.quantity] ?? '') ?? currentItem!.quantity;

      // Update the current item with new values
      currentItem = currentItem!.copyWith(
        price: updatedPrice,
        regularPrice: updatedRegularPrice,
        quantity: updatedQuantity,
      );
    }
  }
}
