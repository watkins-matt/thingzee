import 'package:repository/database/location_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/database/synchronized/sync_database.dart';
import 'package:repository/model/location.dart';

class SynchronizedLocationDatabase extends LocationDatabase
    with SynchronizedDatabase<Location, LocationDatabase> {
  static const String tag = 'SynchronizedLocationDatabase';

  SynchronizedLocationDatabase(LocationDatabase local, LocationDatabase remote, Preferences prefs)
      : super() {
    constructSyncDb(
      tag,
      local,
      remote,
      prefs,
    );
  }

  @override
  List<String> get names => local.names;

  @override
  List<String> getSubPaths(String location) => local.getSubPaths(location);

  @override
  List<String> getUpcList(String location) => local.getUpcList(location);

  @override
  int itemCount(String location) => local.itemCount(location);

  @override
  void remove(String location, String upc) {
    local.remove(location, upc);
    remote.remove(location, upc);
  }

  @override
  void store(String location, String upc) {
    local.store(location, upc);
    remote.store(location, upc);
  }
}
