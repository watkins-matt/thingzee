import 'dart:async';

import 'package:log/log.dart';
import 'package:repository/database/history_database.dart';
import 'package:repository/database/inventory_database.dart';
import 'package:repository/database/item_database.dart';
import 'package:repository/database/joined_inventory_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/database/preferences_default.dart';
import 'package:repository/database/preferences_secure.dart';
import 'package:repository/database/synchronized/sync_history_database.dart';
import 'package:repository/database/synchronized/sync_inventory_database.dart';
import 'package:repository/database/synchronized/sync_item_database.dart';
import 'package:repository/network/connectivity_service.dart';

abstract class CloudRepository extends Repository {
  final ConnectivityService connectivity;

  CloudRepository(this.connectivity) {
    connectivity.addListener(handleConnectivityChange);
  }

  @override
  bool get isMultiUser => true;
  bool get isOnline => connectivity.status == ConnectivityStatus.online;

  void handleConnectivityChange(ConnectivityStatus status);
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
  late SecurePreferences securePrefs;
  bool get isMultiUser => false;
  bool get loggedIn => false;
}

class SynchronizedRepository extends CloudRepository {
  final Repository local;
  final CloudRepository remote;

  SynchronizedRepository._(
    this.local,
    this.remote,
  ) : super(remote.connectivity);

  @override
  bool get isMultiUser => true;

  @override
  bool get isOnline => remote.isOnline;

  @override
  bool get loggedIn => remote.loggedIn;

  @override
  void handleConnectivityChange(ConnectivityStatus status) {
    remote.handleConnectivityChange(status);

    if (status == ConnectivityStatus.online) {
      scheduleMicrotask(() async {
        Log.i('SynchronizedRepository: Connectivity status change detected: online=true');
        await sync();
        Log.i('SynchronizedRepository: Connectivity status handling completed.');
      });
    }
  }

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
    if (!remote.loggedIn) {
      Log.w('SynchronizedRepository: not logged in, cannot sync.');
      return false;
    }

    final timer = Log.timerStart('SynchronizedRepository: starting sync.');
    await remote.sync();

    final syncItems = items as SynchronizedItemDatabase;
    final syncInv = _getSyncDatabase(inv);
    final syncHistory = hist as SynchronizedHistoryDatabase;

    Log.i('SynchronizedRepository: syncing differences between remote and local.');
    syncItems.syncDifferences();
    syncInv.syncDifferences();
    syncHistory.syncDifferences();
    Log.timerEnd(timer, 'SynchronizedRepository: finished sync in \$seconds seconds.');

    return true;
  }

  SynchronizedInventoryDatabase _getSyncDatabase(InventoryDatabase inv) {
    if (inv is SynchronizedInventoryDatabase) {
      return inv;
    } else if (inv is JoinedInventoryDatabase) {
      final joinedInv = inv.inventoryDatabase;
      if (joinedInv is SynchronizedInventoryDatabase) {
        return joinedInv;
      } else {
        throw Exception('Invalid inventory database type: ${joinedInv.runtimeType}');
      }
    } else {
      throw Exception('Invalid inventory database type: ${inv.runtimeType}');
    }
  }

  Future<void> _init() async {
    prefs = await DefaultSharedPreferences.create();
    securePrefs = await SecurePreferences.create();

    items = SynchronizedItemDatabase(local.items, remote.items, prefs);
    hist = SynchronizedHistoryDatabase(local.hist, remote.hist, prefs);

    final inventory = SynchronizedInventoryDatabase(local.inv, remote.inv, prefs);
    inv = JoinedInventoryDatabase(inventory, hist);
    ready = true;
  }

  static Future<Repository> create(Repository local, CloudRepository remote) async {
    final repo = SynchronizedRepository._(local, remote);
    await repo._init();
    return repo;
  }
}
