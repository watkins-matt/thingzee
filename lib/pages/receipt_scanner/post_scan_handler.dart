import 'package:flutter/material.dart';
import 'package:thingzee/pages/receipt_scanner/parser/parser.dart';
import 'package:thingzee/pages/receipt_scanner/parser/stores/target.dart';
import 'package:thingzee/pages/receipt_scanner/receipt_detail_page.dart';
import 'package:thingzee/pages/receipt_scanner/widget/ocr_text_view.dart';

class DebugPostScanHandler extends PostScanHandler {
  DebugPostScanHandler([super.parser]);

  @override
  void handleScannedText(BuildContext context, String text) {
    TargetParser parser = TargetParser();
    text = parser.errorCorrection(text);
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => OCRTextView(text: text)));
  }
}

class ParsingPostScanHandler extends PostScanHandler {
  ParsingPostScanHandler([super.parser]);

  @override
  void handleScannedText(BuildContext context, String text) {
    final parser = super._chooseParser(text);
    parser.parse(text);
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => ReceiptDetailsPage(receipt: parser.receipt, parser: parser)));
  }
}

abstract class PostScanHandler {
  ReceiptParser? parser;
  PostScanHandler([this.parser]);

  void handleScannedText(BuildContext context, String text);

  ReceiptParser _chooseParser(String text) {
    if (parser != null) {
      return parser!;
    }

    return TargetParser();
  }
}
