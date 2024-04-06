import 'package:petitparser/petitparser.dart';
import 'package:repository/model/receipt_item.dart';
import 'package:thingzee/pages/receipt_scanner/parser/element/barcode.dart';
import 'package:thingzee/pages/receipt_scanner/parser/element/item_text.dart';
import 'package:thingzee/pages/receipt_scanner/parser/element/price.dart';
import 'package:thingzee/pages/receipt_scanner/parser/ocr_text.dart';
import 'package:thingzee/pages/receipt_scanner/parser/parser.dart';

enum ItemState { empty, primaryLine, secondaryLine, extraInfo }

enum LineElement {
  barcode,
  name,
  price,
  regularPrice,
}

mixin ParserFactory on ReceiptParser {
  ReceiptItem? _currentItem;
  ItemState _currentState = ItemState.empty;

  final List<ReceiptItem> _items = [];
  List<LineElement> get primaryLineFormat;
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
    if (_currentItem != null) {
      _items.add(_currentItem!);
      _currentItem = null;
    }
  }

  @override
  void parse(String text) {
    _items.clear();
    _currentItem = null;
    _currentState = ItemState.empty;
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
      _currentItem = parseSpecialCases(_currentItem!, line);
      _currentState = ItemState.extraInfo;
    }

    // The line contains primary data, so finalize the current item and start a new one
    else {
      finalizeCurrentItem();
      _currentItem = createNewItemFromPrimary(extraPrimaryResults);
      _currentState = ItemState.primaryLine;
    }
  }

  void parseLine(String line) {
    switch (_currentState) {
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
    Map<LineElement, String> parsedResults = {};

    // Iterate over the format to use the specific parser for each element
    for (final element in format) {
      String? value;
      switch (element) {
        case LineElement.barcode:
          var parsed = skipToBarcodeParser().parse(line);
          if (parsed is Success) value = parsed.value;
          break;
        case LineElement.name:
          var parsed = skipToItemTextParser().parse(line);
          if (parsed is Success) value = parsed.value;
          break;
        case LineElement.price:
          var parsed = skipToPriceParser().parse(line);
          if (parsed is Success && parsed.value.isNotEmpty) {
            value = parsed.value;
          }
          break;
        case LineElement.regularPrice:
          var parsed = skipToPriceParser().parse(line);
          if (parsed is Success && parsed.value.isNotEmpty) {
            value = parsed.value;
          }
          break;
      }
      if (value != null) {
        parsedResults[element] = value;
      }
    }

    return parsedResults;
  }

  void parseNewPrimaryLineOrExtraInfo(String line) {
    var newPrimaryResults = parseLineAccordingToFormat(line, primaryLineFormat);
    if (newPrimaryResults.isNotEmpty) {
      finalizeCurrentItem();
      _currentItem = createNewItemFromPrimary(newPrimaryResults);
      _currentState = ItemState.primaryLine; // Start new item
    } else {
      _currentItem = parseSpecialCases(_currentItem!, line); // Continue accumulating extra info
    }
  }

  void parsePrimaryLine(String line) {
    var primaryResults = parseLineAccordingToFormat(line, primaryLineFormat);
    if (primaryResults.isNotEmpty) {
      _currentItem = createNewItemFromPrimary(primaryResults);
      _currentState = ItemState.primaryLine; // We now have primary data
    }
  }

  void parseSecondaryLineOrExtraInfo(String line) {
    // If we have a secondary line format, try parsing it first
    if (secondaryLineFormat != null) {
      var secondaryResults = parseLineAccordingToFormat(line, secondaryLineFormat!);
      if (secondaryResults.isNotEmpty) {
        updateCurrentItemWithSecondary(secondaryResults);
        _currentState = ItemState.secondaryLine; // We have secondary data
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
    if (_currentItem != null) {
      // The secondary line might contain updates to price or additional details like bottle deposit
      var updatedPrice = double.tryParse(results[LineElement.price] ?? '') ?? _currentItem!.price;
      var updatedRegularPrice =
          double.tryParse(results[LineElement.regularPrice] ?? '') ?? _currentItem!.regularPrice;

      // Update the current item with new values
      _currentItem = _currentItem!.copyWith(
        price: updatedPrice,
        regularPrice: updatedRegularPrice,
      );
    }
  }
}
