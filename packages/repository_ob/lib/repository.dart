import 'dart:io';

import 'package:log/log.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:repository/database/preferences_default.dart';
import 'package:repository/database/preferences_secure.dart';
import 'package:repository/repository.dart';
import 'package:repository_ob/database/audit_task_db.dart';
import 'package:repository_ob/database/history_db.dart';
import 'package:repository_ob/database/household_db.dart';
import 'package:repository_ob/database/identifier_db.dart';
import 'package:repository_ob/database/inventory_db.dart';
import 'package:repository_ob/database/item_db.dart';
import 'package:repository_ob/database/location_db.dart';
import 'package:repository_ob/database/receipt_db.dart';
import 'package:repository_ob/database/receipt_item_db.dart';
import 'package:repository_ob/database/shopping_list_db.dart';
import 'package:repository_ob/objectbox.g.dart';

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
    securePrefs = await SecurePreferences.create();

    items = ObjectBoxItemDatabase(store);
    hist = ObjectBoxHistoryDatabase(store);
    inv = ObjectBoxInventoryDatabase(store);
    household = ObjectBoxHouseholdDatabase(store, prefs);
    location = ObjectBoxLocationDatabase(store);
    identifiers = ObjectBoxIdentifierDatabase(store);
    shopping = ObjectBoxShoppingListDatabase(store);
    receiptItems = ObjectBoxReceiptItemDatabase(store);
    receipts = ObjectBoxReceiptDatabase(store, receiptItems as ObjectBoxReceiptItemDatabase);
    audits = ObjectBoxAuditTaskDatabase(store);

    Log.timerEnd(timer, 'Initialized ObjectBox repository (\$seconds seconds)');
    ready = true;
  }

  static Future<Repository> create() async {
    final repo = ObjectBoxRepository._();
    await repo._init();
    return repo;
  }
}
