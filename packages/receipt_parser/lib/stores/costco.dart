import 'package:receipt_parser/parser.dart';
import 'package:receipt_parser/receipt_parser_factory.dart';
import 'package:repository/database/identifier_database.dart';

class CostcoReceiptParser extends ReceiptParser with ParserFactory {
  @override
  String get barcodeType => IdentifierType.costco;

  @override
  List<LineElement> get primaryLineFormat =>
      [LineElement.barcode, LineElement.name, LineElement.price];
}
