import 'package:repository/database/item_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/database/synchronized/sync_database.dart';
import 'package:repository/model/filter.dart';
import 'package:repository/model/item.dart';

class SynchronizedItemDatabase extends ItemDatabase with SynchronizedDatabase<Item, ItemDatabase> {
  static const String tag = 'SynchronizedItemDatabase';

  SynchronizedItemDatabase(ItemDatabase local, ItemDatabase remote, Preferences prefs) : super() {
    constructSyncDb(
      tag,
      local,
      remote,
      prefs,
    );
  }

  @override
  List<Item> filter(Filter filter) => local.filter(filter);

  @override
  List<Item> search(String string) => local.search(string);
}
