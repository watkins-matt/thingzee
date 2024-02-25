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
}
