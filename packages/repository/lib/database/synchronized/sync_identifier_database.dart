import 'package:repository/database/identifier_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/database/synchronized/sync_database.dart';
import 'package:repository/model/identifier.dart';

class SynchronizedIdentifierDatabase extends IdentifierDatabase
    with SynchronizedDatabase<Identifier, IdentifierDatabase> {
  static const String tag = 'SynchronizedIdentifierDatabase';

  SynchronizedIdentifierDatabase(
      IdentifierDatabase local, IdentifierDatabase remote, Preferences prefs)
      : super() {
    constructSyncDb(
      tag,
      local,
      remote,
      prefs,
    );
  }

  @override
  List<Identifier> getAllForUid(String uid) {
    return local.getAllForUid(uid);
  }

  @override
  List<Identifier> getAllForUpc(String upc) => local.getAllForUpc(upc);

  @override
  String? uidFromUPC(String upc) => local.uidFromUPC(upc);
}
