class ReceiptIdentifierType {
  static const String upc = 'UPC';
  static const String ean = 'EAN';
  static const String isbn = 'ISBN';
  static const String asin = 'ASIN';
  static const String bestBuy = 'BestBuy';
  static const String walmart = 'Walmart';
  static const String target = 'Target';
  static const String costco = 'Costco';

  static final Set<String> validIdentifierTypes = {
    ReceiptIdentifierType.upc,
    ReceiptIdentifierType.ean,
    ReceiptIdentifierType.isbn,
    ReceiptIdentifierType.asin,
    ReceiptIdentifierType.bestBuy,
    ReceiptIdentifierType.walmart,
    ReceiptIdentifierType.target,
    ReceiptIdentifierType.costco,
  };

  static bool isValid(String identifierType) {
    return validIdentifierTypes.contains(identifierType);
  }
}
