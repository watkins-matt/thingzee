import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:receipt_parser/parser/generic_parser.dart';
import 'package:receipt_parser/parser/parser.dart';
import 'package:receipt_parser/parser/stores/target.dart';

import '../widget/ocr_text_view.dart';
import 'receipt_detail_page.dart';

class DebugPostScanHandler extends PostScanHandler {
  DebugPostScanHandler({super.parser});

  @override
  void handleScannedText(BuildContext context, WidgetRef ref, String text) {
    TargetReceiptParser parser = TargetReceiptParser();
    text = parser.errorCorrector.correctErrors(text);
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => OCRTextView(text: text)));
  }
}

abstract class PostScanHandler {
  ReceiptParser parser;
  PostScanHandler({ReceiptParser? parser}) : parser = parser ?? GenericReceiptParser();

  void handleScannedText(BuildContext context, WidgetRef ref, String text);
}

class ShowReceiptDetailHandler extends PostScanHandler {
  final AcceptPressedCallback? onAcceptPressed;

  ShowReceiptDetailHandler({
    super.parser,
    this.onAcceptPressed,
  });

  @override
  void handleScannedText(BuildContext context, WidgetRef ref, String text) {
    parser.parse(text);
    ReceiptDetailPage.pushReplacement(context, ref, parser, onAcceptPressed);
  }
}
