import 'package:petitparser/petitparser.dart';

Parser<String> quantityParser() {
  return digit().trim().seq(digit().trim().optional()).flatten().map((value) => value.trim());
}

Parser<String> skipToQuantityParser() {
  final parser = quantityParser();

  // This parser lazily consumes any characters until it reaches the condition defined in quantityParser.
  var skipUntilQuantity = any().starLazy(parser).flatten();

  // After skipping, capture the quantity. The use of .map((values) => values.last) ensures the return type is String.
  return skipUntilQuantity.seq(parser).map((values) => values[1] as String);
}
