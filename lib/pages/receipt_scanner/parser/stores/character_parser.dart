import 'package:repository/model/receipt.dart';
import 'package:thingzee/pages/receipt_scanner/parser/parser.dart';

class CharacterParser extends ReceiptParser {
  List<Token> tokens = [];
  StringBuffer currentText = StringBuffer();
  TokenType tokenType = TokenType.text;

  @override
  String get rawText => throw UnimplementedError();

  @override
  Receipt get receipt => throw UnimplementedError();

  @override
  String getSearchUrl(String barcode) => 'https://www.google.com/search?q=$barcode';

  @override
  void parse(String text) {
    for (int i = 0; i < text.length; i++) {
      String char = text[i];
      String lookahead = i + 1 < text.length ? text[i + 1] : '';

      push(char, lookahead);
    }
  }

  void push(String char, String lookahead) {
    // Check if the character is numeric
    if (char.isNumeric) {
      if (lookahead == '-') {
        tokenType = TokenType.phoneNumber;
      }

      // Check if the current token is a product price
      else if (currentText.isMajorityNumeric) {
        int currentLength = currentText.length;

        if (currentLength <= 2) {
          tokenType = TokenType.productQuantity;
        } else if (currentLength <= 5 && currentText.contains(r'$') || currentText.contains('.')) {
          tokenType = TokenType.productPrice;
        } else {
          tokenType = TokenType.productIdNumber;
        }
      }
    }

    // Check if we need to end the current token
    else if (char == ' ' || char == '\n' || char == '\t' || char == '\r') {
      if (currentText.isEmpty) {
        return;
      }

      tokens.add(Token(tokenType, currentText.text));
      currentText.clear();
      tokenType = TokenType.text;
      return;
    }

    // Add the character to the token text
    currentText.write(char);
  }
}

class Token {
  final TokenType type;
  final String value;

  Token(this.type, this.value);
}

enum TokenType {
  productIdNumber,
  productName,
  productQuantity,
  productPrice,
  productRegularPrice,
  phoneNumber,
  address,
  subtotal,
  total,
  tax,
  date,
  time,
  text,
}

extension StringBufferExtension on StringBuffer {
  bool get isMajorityNumeric {
    int numericCount = text.runes.where((int rune) {
      var character = String.fromCharCode(rune);
      return ('0'.compareTo(character) <= 0 && '9'.compareTo(character) >= 0) || character == '.';
    }).length;

    // Check if numeric characters are the majority
    return numericCount > (length / 2);
  }

  String get text => toString();

  bool contains(String pattern) {
    return toString().contains(pattern);
  }
}

extension StringExtension on String {
  bool get isAlphabetic => RegExp(r'[\w]').hasMatch(this);
  bool get isNumeric => double.tryParse(this) != null;
}
