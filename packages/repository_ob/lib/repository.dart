import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:repository/repository.dart';
import 'package:repository_ob/database/history_db.dart';
import 'package:repository_ob/database/inventory_joined_db.dart';
import 'package:repository_ob/database/item_db.dart';

import 'objectbox.g.dart';

class ObjectBoxRepository extends Repository {
  late Store store;

  ObjectBoxRepository._();

  Future<void> _init() async {
    Directory directory = await getApplicationSupportDirectory();
    store = Store(getObjectBoxModel(), directory: '${directory.path}/objectbox');

    items = ObjectBoxItemDatabase(store);
    hist = ObjectBoxHistoryDatabase(store);
    inv = ObjectBoxJoinedInventoryDatabase(store, hist);

    ready = true;
  }

  static Future<Repository> create() async {
    final repo = ObjectBoxRepository._();
    await repo._init();
    return repo;
  }
}
