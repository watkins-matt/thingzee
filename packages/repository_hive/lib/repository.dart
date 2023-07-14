import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:repository/database/joined_inventory_database.dart';
import 'package:repository/database/preferences_default.dart';
import 'package:repository/database/preferences_secure.dart';
import 'package:repository/repository.dart';
import 'package:repository_hive/adapter/history_adapter.dart';
import 'package:repository_hive/database/history_db.dart';
import 'package:repository_hive/database/inventory_db.dart';
import 'package:repository_hive/database/item_db.dart';

class HiveRepository extends Repository {
  HiveRepository._();

  Future<void> _init() async {
    if (!kIsWeb) {
      await Hive.initFlutter('hive');
    }

    // Register type adapter for History
    Hive.registerAdapter(HistoryAdapter());

    prefs = await DefaultSharedPreferences.create();
    securePrefs = await SecurePreferences.create();

    items = HiveItemDatabase();
    hist = HiveHistoryDatabase();

    final inventory = HiveInventoryDatabase();
    inv = JoinedInventoryDatabase(inventory, hist);

    ready = true;
  }

  static Future<Repository> create() async {
    final repo = HiveRepository._();
    await repo._init();
    return repo;
  }
}
