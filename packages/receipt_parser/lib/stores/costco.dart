import 'package:receipt_parser/parser.dart';
import 'package:receipt_parser/receipt_identifier_type.dart';
import 'package:receipt_parser/receipt_parser_factory.dart';

class CostcoReceiptParser extends ReceiptParser with ParserFactory {
  @override
  String get barcodeType => ReceiptIdentifierType.costco;

  @override
  List<LineElement> get primaryLineFormat =>
      [LineElement.barcode, LineElement.name, LineElement.price];

  @override
  String getSearchUrl(String barcode) => 'https://www.google.com/search?q=costco+item+$barcode';
}
