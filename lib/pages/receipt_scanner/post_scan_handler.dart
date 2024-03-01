import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/receipt_scanner/parser/generic_parser.dart';
import 'package:thingzee/pages/receipt_scanner/parser/parser.dart';
import 'package:thingzee/pages/receipt_scanner/parser/stores/target.dart';
import 'package:thingzee/pages/receipt_scanner/receipt_detail_page.dart';
import 'package:thingzee/pages/receipt_scanner/widget/ocr_text_view.dart';

class DebugPostScanHandler extends PostScanHandler {
  DebugPostScanHandler([super.parser]);

  @override
  void handleScannedText(BuildContext context, WidgetRef ref, String text) {
    TargetParser parser = TargetParser();
    text = parser.errorCorrection(text);
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => OCRTextView(text: text)));
  }
}

class ParsingPostScanHandler extends PostScanHandler {
  ParsingPostScanHandler([super.parser]);

  @override
  void handleScannedText(BuildContext context, WidgetRef ref, String text) {
    final parser = super._chooseParser(text);
    parser.parse(text);

    ReceiptDetailsPage.pushReplacement(context, ref, parser);
  }
}

abstract class PostScanHandler {
  ReceiptParser? parser;
  PostScanHandler([this.parser]);

  void handleScannedText(BuildContext context, WidgetRef ref, String text);

  ReceiptParser _chooseParser(String text) {
    if (parser != null) {
      return parser!;
    }

    return GenericReceiptParser();
  }
}
