import 'package:petitparser/petitparser.dart';

Parser<String> itemTextParser() {
  // Optional initial whitespace, followed by a letter as the start of the item text.
  var optionalInitialWhitespace = whitespace().optional();
  var startWithLetter = letter();

  // Parser for allowed item text characters: letters, digits, and horizontal spaces (excluding newlines).
  var allowedChars = (letter() | digit() | pattern(' \t\'&.')).star();

  // Combine the initial optional whitespace, mandatory starting letter, and allowed characters.
  var itemTextContent = optionalInitialWhitespace & startWithLetter & allowedChars;

  // Define a parser that consumes trailing whitespace or stops at a newline or the end of the input.
  var endOfText = (whitespace() | char('\n')).star();

  // Combine everything, flatten, and trim the result to remove any leading or trailing whitespace.
  return (itemTextContent & endOfText).flatten().map((String value) => value.trim());
}

Parser<String> skipToItemTextParser() {
  final parser = itemTextParser();

  // This parser lazily consumes any characters until it reaches the condition defined in itemTextParser.
  var skipUntilItemText = any().starLazy(parser).flatten();

  // After skipping, capture the item text. The use of .map((values) => values.last) ensures the return type is String.
  return skipUntilItemText.seq(parser).map((values) => values[1] as String);
}
