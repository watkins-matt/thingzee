import 'package:repository/database/database.dart';
import 'package:repository/model/identifier.dart';

abstract class IdentifierDatabase extends Database<Identifier> {
  List<Identifier> getAllForUid(String uid);
  List<Identifier> getAllForUpc(String upc);

  Map<String, String> getMapForUpc(String upc) {
    final map = <String, String>{};
    final identifiers = getAllForUpc(upc);

    for (final identifier in identifiers) {
      map[identifier.type] = identifier.value;
    }

    return map;
  }

  Identifier? getTypeForUpc(String upc, String type) =>
      getAllForUpc(upc).where((identifier) => identifier.type == type).firstOrNull;

  String? getUidFromType(String type, String barcode) => get('$type-$barcode')?.uid;
  String? uidFromUPC(String upc);

  String? upcFromUid(String uid) {
    List<Identifier> all = getAllForUid(uid);
    for (final Identifier identifier in all) {
      if (identifier.type == IdentifierType.upc) {
        return identifier.value;
      }
    }

    return null;
  }
}

class IdentifierType {
  static const String upc = 'UPC';
  static const String ean = 'EAN';
  static const String isbn = 'ISBN';
  static const String asin = 'ASIN';
  static const String bestBuy = 'BestBuy';
  static const String walmart = 'Walmart';
  static const String target = 'Target';
  static const String costco = 'Costco';

  static final Set<String> validIdentifierTypes = {
    IdentifierType.upc,
    IdentifierType.ean,
    IdentifierType.isbn,
    IdentifierType.asin,
    IdentifierType.bestBuy,
    IdentifierType.walmart,
    IdentifierType.target,
    IdentifierType.costco,
  };

  static bool isValid(String identifierType) {
    return validIdentifierTypes.contains(identifierType);
  }
}
