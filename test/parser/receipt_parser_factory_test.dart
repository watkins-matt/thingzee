// import 'package:flutter_test/flutter_test.dart';
// import 'package:repository/model/receipt_item.dart';
// import 'package:thingzee/pages/receipt_scanner/parser/parser.dart';
// import 'package:thingzee/pages/receipt_scanner/parser/receipt_parser_factory.dart';

void main() {
  // group('ParserFactory tests', () {
  //   late ParserFactory parserFactory;

  //   setUp(() {
  //     parserFactory = TestParserFactory();
  //   });

  //   test('Test parsing primary line', () {
  //     const line = r'1234567890 Item Name $10.99 $9.99';
  //     parserFactory.parsePrimaryLine(line);

  //     expect(parserFactory.currentItem, isNotNull);
  //     expect(parserFactory.currentState, equals(ItemState.primaryLine));
  //     expect(parserFactory.currentItem!.barcode, equals('1234567890'));
  //     expect(parserFactory.currentItem!.name, equals('Item Name'));
  //     expect(parserFactory.currentItem!.price, equals(10.99));
  //     expect(parserFactory.currentItem!.regularPrice, equals(9.99));
  //   });

  //   test('Test parsing secondary line', () {
  //     const line = 'Some extra info';
  //     parserFactory.currentItem = ReceiptItem(
  //       barcode: '1234567890',
  //       name: 'Item Name',
  //       price: 10.99,
  //       regularPrice: 9.99,
  //       quantity: 1,
  //       taxable: true,
  //       bottleDeposit: 0,
  //     );
  //     parserFactory.currentState = ItemState.primaryLine;

  //     parserFactory.parseSecondaryLineOrExtraInfo(line);

  //     expect(parserFactory.currentState, equals(ItemState.secondaryLine));
  //     expect(parserFactory.currentItem!.price, equals(10.99));
  //     expect(parserFactory.currentItem!.regularPrice, equals(9.99));
  //   });

  //   test('Test parsing extra info', () {
  //     const line = 'Some extra info';
  //     parserFactory.currentItem = ReceiptItem(
  //       barcode: '1234567890',
  //       name: 'Item Name',
  //       price: 10.99,
  //       regularPrice: 9.99,
  //       quantity: 1,
  //       taxable: true,
  //       bottleDeposit: 0,
  //     );
  //     parserFactory.currentState = ItemState.primaryLine;

  //     parserFactory.parseExtraInfoOrNewPrimary(line);

  //     expect(parserFactory.currentState, equals(ItemState.extraInfo));
  //     expect(parserFactory.currentItem!.price, equals(10.99));
  //     expect(parserFactory.currentItem!.regularPrice, equals(9.99));
  //   });

  //   test('Test parsing new primary line', () {
  //     const line = r'1234567890 Item Name $10.99 $9.99';
  //     parserFactory.currentItem = ReceiptItem(
  //       barcode: '1234567890',
  //       name: 'Item Name',
  //       price: 10.99,
  //       regularPrice: 9.99,
  //       quantity: 1,
  //       taxable: true,
  //       bottleDeposit: 0,
  //     );
  //     parserFactory.currentState = ItemState.secondaryLine;

  //     parserFactory.parseNewPrimaryLineOrExtraInfo(line);

  //     expect(parserFactory.currentState, equals(ItemState.primaryLine));
  //     expect(parserFactory.currentItem!.barcode, equals('1234567890'));
  //     expect(parserFactory.currentItem!.name, equals('Item Name'));
  //     expect(parserFactory.currentItem!.price, equals(10.99));
  //     expect(parserFactory.currentItem!.regularPrice, equals(9.99));
  //   });
  // });
}

// class TestParserFactory with ParserFactory implements ReceiptParser {
//   @override
//   List<LineElement> get primaryLineFormat =>
//       [LineElement.barcode, LineElement.name, LineElement.price, LineElement.regularPrice];

//   @override
//   List<LineElement>? get secondaryLineFormat => null;
// }
