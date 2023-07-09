import 'package:repository/database/history_database.dart';
import 'package:repository/database/inventory_database.dart';
import 'package:repository/database/item_database.dart';
import 'package:repository/database/joined_inventory_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/database/synchronized/sync_history_database.dart';
import 'package:repository/database/synchronized/sync_inventory_database.dart';
import 'package:repository/database/synchronized/sync_item_database.dart';

abstract class CloudRepository extends Repository {
  @override
  bool get isMultiUser => true;

  Future<void> loginUser(String email, String password);
  Future<void> logoutUser();
  Future<void> registerUser(String username, String email, String password);
  Future<bool> sync();
}

abstract class Repository {
  bool ready = false;
  late ItemDatabase items;
  late InventoryDatabase inv;
  late HistoryDatabase hist;
  late Preferences prefs;
  bool get isMultiUser => false;
  bool get loggedIn => false;
}

class SynchronizedRepository extends CloudRepository {
  final Repository local;
  final CloudRepository remote;

  SynchronizedRepository._(this.local, this.remote) : super();

  @override
  bool get isMultiUser => true;

  @override
  bool get loggedIn => remote.loggedIn;

  @override
  Future<void> loginUser(String email, String password) async {
    await remote.loginUser(email, password);
  }

  @override
  Future<void> logoutUser() async {
    await remote.logoutUser();
  }

  @override
  Future<void> registerUser(String username, String email, String password) async {
    await remote.registerUser(username, email, password);
  }

  @override
  Future<bool> sync() async {
    await remote.sync();

    final syncItems = items as SynchronizedItemDatabase;
    final syncInv = inv as SynchronizedInventoryDatabase;
    final syncHistory = hist as SynchronizedHistoryDatabase;

    syncItems.syncDifferences();
    syncInv.syncDifferences();
    syncHistory.syncDifferences();

    return true;
  }

  Future<void> _init() async {
    prefs = await DefaultSharedPreferences.create();
    items = SynchronizedItemDatabase(local.items, remote.items);
    hist = SynchronizedHistoryDatabase(local.hist, remote.hist);

    final inventory = SynchronizedInventoryDatabase(local.inv, remote.inv);
    inv = JoinedInventoryDatabase(inventory, hist);
    ready = true;
  }

  static Future<Repository> create(Repository local, CloudRepository remote) async {
    final repo = SynchronizedRepository._(local, remote);
    await repo._init();
    return repo;
  }
}
