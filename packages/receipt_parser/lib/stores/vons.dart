import 'package:receipt_parser/parser.dart';
import 'package:receipt_parser/receipt_parser_factory.dart';

class VonsReceiptParser extends ReceiptParser with ParserFactory {
  @override
  List<LineElement> get primaryLineFormat =>
      [LineElement.barcode, LineElement.name, LineElement.regularPrice, LineElement.price];
}
