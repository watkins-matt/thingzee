import 'package:repository/database/database.dart';
import 'package:repository/model/identifier.dart';

abstract class IdentifierDatabase implements Database<Identifier> {
  List<Identifier> getAllForUpc(String upc);

  Map<String, String> getMapForUpc(String upc) {
    final map = <String, String>{};
    final identifiers = getAllForUpc(upc);

    for (final identifier in identifiers) {
      map[identifier.type] = identifier.value;
    }

    return map;
  }

  String? uidFromUPC(String upc);
}

class IdentifierType {
  static const String upc = 'UPC';
  static const String ean = 'EAN';
  static const String isbn = 'ISBN';
  static const String asin = 'ASIN';
  static const String bestBuy = 'BestBuy';
  static const String walmart = 'Walmart';
  static const String target = 'Target';

  static final Set<String> validIdentifierTypes = {
    IdentifierType.upc,
    IdentifierType.ean,
    IdentifierType.isbn,
    IdentifierType.asin,
    IdentifierType.bestBuy,
    IdentifierType.walmart,
    IdentifierType.target,
  };

  static bool isValid(String identifierType) {
    return validIdentifierTypes.contains(identifierType);
  }
}
