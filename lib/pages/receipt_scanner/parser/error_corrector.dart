class ErrorCorrector {
  Set<String> _wordList = {};

  ErrorCorrector([List<String>? wordList]) {
    if (wordList != null) {
      _wordList = wordList.toSet();
    }
  }

  void addWords(List<String> words) {
    _wordList.addAll(words);
  }

  // Corrects errors in the given text by applying a series of correction rules
  String correctErrors(String text) {
    text = _correctWordErrors(text);
    text = _correctPhoneNumbers(text);
    text = _correctPriceO(text);
    text = _correctPriceComma(text);
    text = _correctQuantityLineFormat(text);
    text = _correctPriceSpace(text);
    text = _correctPriceColon(text);
    text = _correctPriceO(text);
    text = _correctPriceG(text);
    text = _correctPriceMissingDecimal(text);
    text = _correctMissingDollarSign(text);
    text = _correctNineDigitNumberWithO(text);
    text = _correctPriceS(text);
    text = _removeDuplicateDollarSigns(text);
    return text;
  }

  // Corrects a numeric sequence by replacing certain characters with their corresponding digits
  String correctNumericSequence(String sequence) {
    String cleanedSequence = sequence
        .toUpperCase()
        .replaceAll('O', '0')
        .replaceAll('C', '0')
        .replaceAll('I', '1')
        .replaceAll('Z', '2')
        .replaceAll('S', '5')
        .replaceAll('D', '0')
        .replaceAll('A', '4')
        .replaceAll('E', '6')
        .replaceAll('U', '0')
        .replaceAll(RegExp(r'\s+'), ''); // Remove all spaces

    return cleanedSequence;
  }

  // Corrects prices in the given text by adding '$' to prices without dollar sign
  String _correctMissingDollarSign(String text) {
    RegExp priceRegExp = RegExp(r'(?<!\$)\b\d+\.\d{2}\b');
    text = text.replaceAllMapped(priceRegExp, (match) {
      // Directly prepend '$' to the matched price
      return '\$${match[0]}';
    });

    return text;
  }

  // Corrects 9-digit numbers in the given text by replacing 'O' with '0'
  String _correctNineDigitNumberWithO(String text) {
    RegExp nineDigitNumberWithO = RegExp(r'\b\d{0,8}[O]\d{0,8}\b');
    text = text.replaceAllMapped(nineDigitNumberWithO, (match) {
      // Replace 'O' with '0'
      return match[0]!.replaceAll('O', '0');
    });

    return text;
  }

  // Corrects phone numbers in the given text by removing unnecessary spaces
  String _correctPhoneNumbers(String text) {
    RegExp phoneNumRegExp = RegExp(r'(\d{3})-(\d{3})\s*-\s*(\d{4})');
    text = text.replaceAllMapped(phoneNumRegExp, (match) {
      // Reconstruct the phone number without unnecessary spaces
      return '${match[1]}-${match[2]}-${match[3]}';
    });

    return text;
  }

  // Corrects prices in the given text by replacing ':' with '1' (if not part of a time format)
  String _correctPriceColon(String text) {
    RegExp priceColonRegExp =
        RegExp(r'(?:\b|\$):(\d+\.\d{2})\b(?!\s*(AM|PM))', caseSensitive: false);
    text = text.replaceAllMapped(priceColonRegExp, (match) {
      // Replace ':' with '1'
      return '1${match[1]}';
    });

    return text;
  }

  // Corrects prices in the given text by replacing comma with a period
  String _correctPriceComma(String text) {
    RegExp priceCommaRegExp = RegExp(r'\b(\d+),(\d{2})\b');
    text = text.replaceAllMapped(priceCommaRegExp, (match) {
      // Replace comma with a period
      return '${match[1]}.${match[2]}';
    });

    return text;
  }

  String _correctPriceG(String text) {
    RegExp letterBeforePriceRegExp = RegExp(r'\bg(\d+\.\d{2})\b', caseSensitive: false);
    text = text.replaceAllMapped(letterBeforePriceRegExp, (match) {
      return '\$${match[1]}';
    });

    return text;
  }

  String _correctPriceMissingDecimal(String text) {
    // Correcting "$# ##" to "$#.##"
    RegExp dollarSpacePriceRegExp = RegExp(r'\$(\d+)\s{1}(\d{2})');
    text = text.replaceAllMapped(dollarSpacePriceRegExp, (match) {
      return '\$${match[1]}.${match[2]}';
    });
    return text;
  }

  // Corrects prices in the given text by replacing 'o' and 'O' with '0'
  String _correctPriceO(String text) {
    RegExp priceORegExp = RegExp(r'[\dOo]+[\.,][\dOo]{2}\b');
    text = text.replaceAllMapped(priceORegExp, (match) {
      // Replace 'o' and 'O' with '0'
      return match[0]!.replaceAll(RegExp(r'[oO]'), '0');
    });

    return text;
  }

  // Corrects prices in the given text by replacing 'S' with '$'
  String _correctPriceS(String text) {
    final RegExp priceSRegExp = RegExp(r'S(\d+\.\d{2})');
    text = text.replaceAllMapped(priceSRegExp, (Match match) {
      return '\$${match[1]}';
    });

    return text;
  }

  // Corrects prices in the given text by removing space between dollars and cents
  String _correctPriceSpace(String text) {
    RegExp priceSpaceRegExp = RegExp(r'(\d+)\.\s+(\d{2})');
    text = text.replaceAllMapped(priceSpaceRegExp, (match) {
      // Reconstruct the price without the space
      return '\$${match[1]!}.${match[2]!}';
    });

    return text;
  }

  // Corrects quantity line format in the given text by adding '@ $' between quantity and price
  String _correctQuantityLineFormat(String text) {
    final quantityCorrectionRegex = RegExp(r'(\d+)@\s*\$?\s*([\d\w.]+)');
    text = text.replaceAllMapped(quantityCorrectionRegex, (match) {
      final quantity = match.group(1)!;
      final priceOrText = match.group(2)!;
      return '$quantity @ \$$priceOrText';
    });

    return text;
  }

  // Corrects word errors in the given text by replacing split parts of words with the correct word
  String _correctWordErrors(String text) {
    for (final word in _wordList) {
      // Create a regular expression to match split parts of the word
      String pattern = word.split('').join(r'\s*');
      RegExp regExp = RegExp(pattern, caseSensitive: false);

      // Replace occurrences of the split word with the correct word
      text = text.replaceAllMapped(regExp, (match) => word);
    }

    return text;
  }

  // Removes duplicate dollar signs in the given text
  String _removeDuplicateDollarSigns(String text) {
    text = text.replaceAll('\$\$', '\$');

    return text;
  }
}
