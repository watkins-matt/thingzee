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

  String correctErrors(String text) {
    for (final word in _wordList) {
      // Create a regular expression to match split parts of the word
      String pattern = word.split('').join(r'\s*');
      RegExp regExp = RegExp(pattern, caseSensitive: false);

      // Replace occurrences of the split word with the correct word
      text = text.replaceAllMapped(regExp, (match) => word);
    }

    // Correcting spaces within phone numbers
    RegExp phoneNumRegExp = RegExp(r'(\d{3})-(\d{3})\s*-\s*(\d{4})');
    text = text.replaceAllMapped(phoneNumRegExp, (match) {
      // Reconstruct the phone number without unnecessary spaces
      return '${match[1]}-${match[2]}-${match[3]}';
    });

    // Correcting 'o' and 'O' in prices including those without dollar sign
    RegExp priceORegExp = RegExp(r'[\dOo]+[\.,][\dOo]{2}\b');
    text = text.replaceAllMapped(priceORegExp, (match) {
      // Replace 'o' and 'O' with '0'
      return match[0]!.replaceAll(RegExp(r'[oO]'), '0');
    });

    // Correcting commas within prices
    RegExp priceCommaRegExp = RegExp(r'\b(\d+),(\d{2})\b');
    text = text.replaceAllMapped(priceCommaRegExp, (match) {
      // Replace comma with a period
      return '${match[1]}.${match[2]}';
    });

    // Correct quantity line format (e.g., "2@$2.79")
    final quantityCorrectionRegex = RegExp(r'(\d+)@\s*\$?\s*([\d\w.]+)');
    text = text.replaceAllMapped(quantityCorrectionRegex, (match) {
      final quantity = match.group(1)!;
      final priceOrText = match.group(2)!;
      return '$quantity @ \$$priceOrText';
    });

    // Correcting spaces within prices
    RegExp priceSpaceRegExp = RegExp(r'(\d+)\.\s+(\d{2})');
    text = text.replaceAllMapped(priceSpaceRegExp, (match) {
      // Reconstruct the price without the space
      return '\$${match[1]!}.${match[2]!}';
    });

    // Correcting ':' within prices where ':' is the first part and should be '1',
    // but avoiding situations where the pattern could be part of a time format.
    RegExp priceColonRegExp = RegExp(r'\b:(\d+\.\d{2})\b(?!\s*(AM|PM))', caseSensitive: false);
    text = text.replaceAllMapped(priceColonRegExp, (match) {
      // Replace ':' with '1'
      return '1${match[1]}';
    });

    // Correcting 'o' and 'O' in prices again in case
    // we have new matches from fixing :
    text = text.replaceAllMapped(priceORegExp, (match) {
      // Replace 'o' and 'O' with '0'
      return match[0]!.replaceAll(RegExp(r'[oO]'), '0');
    });

    // Price correction (for missing $)
    RegExp priceRegExp = RegExp(r'(?<!\$)\b\d+\.\d{2}\b(?!\s+on)');
    text = text.replaceAllMapped(priceRegExp, (match) {
      // Extract the matched string
      String matchedPrice = match[0]!;
      // Remove the first character and prepend with '$'
      return '\$${matchedPrice.substring(1)}';
    });

    // Regular expression to find prices starting with 'S'
    // which should be changed to $
    final RegExp priceSRegExp = RegExp(r'S(\d+\.\d{2})');

    // Replace occurrences of prices starting with 'S' with '$'
    text = text.replaceAllMapped(priceSRegExp, (Match match) {
      return '\$${match[1]}';
    });

    // Duplicate dollar signs
    text = text.replaceAll('\$\$', '\$');

    return text;
  }
}
