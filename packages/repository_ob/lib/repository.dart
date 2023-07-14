import 'dart:io';

import 'package:log/log.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:repository/database/preferences_default.dart';
import 'package:repository/repository.dart';
import 'package:repository_ob/database/history_db.dart';
import 'package:repository_ob/database/inventory_joined_db.dart';
import 'package:repository_ob/database/item_db.dart';

import 'objectbox.g.dart';

class ObjectBoxRepository extends Repository {
  late Store store;

  ObjectBoxRepository._();

  Future<void> _init() async {
    final timer = Log.timerStart();
    Directory directory = await getApplicationSupportDirectory();
    String dbPath = path.join(directory.path, 'objectbox');

    if (!Directory(dbPath).existsSync()) {
      Directory(dbPath).createSync(recursive: true);
    }

    store = Store(getObjectBoxModel(), directory: dbPath);

    prefs = await DefaultSharedPreferences.create();
    items = ObjectBoxItemDatabase(store);
    hist = ObjectBoxHistoryDatabase(store);
    inv = ObjectBoxJoinedInventoryDatabase(store, hist);

    Log.timerEnd(timer, 'ObjectBox repository initialized in \$seconds seconds');
    ready = true;
  }

  static Future<Repository> create() async {
    final repo = ObjectBoxRepository._();
    await repo._init();
    return repo;
  }
}
