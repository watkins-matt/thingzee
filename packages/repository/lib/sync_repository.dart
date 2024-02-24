import 'dart:async';

import 'package:log/log.dart';
import 'package:repository/cloud_repository.dart';
import 'package:repository/database/preferences_default.dart';
import 'package:repository/database/preferences_secure.dart';
import 'package:repository/database/synchronized/sync_history_database.dart';
import 'package:repository/database/synchronized/sync_household_database.dart';
import 'package:repository/database/synchronized/sync_identifier_database.dart';
import 'package:repository/database/synchronized/sync_inventory_database.dart';
import 'package:repository/database/synchronized/sync_item_database.dart';
import 'package:repository/database/synchronized/sync_location_database.dart';
import 'package:repository/network/connectivity_service.dart';
import 'package:repository/repository.dart';

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
  bool get isUserVerified => remote.isUserVerified;

  @override
  bool get loggedIn => remote.loggedIn;

  @override
  String get userEmail => remote.userEmail;

  @override
  String get userId => remote.userId;

  @override
  Future<bool> checkVerificationStatus() async {
    return await remote.checkVerificationStatus();
  }

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
  Future<bool> loginUser(String email, String password) async {
    return await remote.loginUser(email, password);
  }

  @override
  Future<void> logoutUser() async {
    await remote.logoutUser();
  }

  @override
  Future<bool> registerUser(String username, String email, String password) async {
    return await remote.registerUser(username, email, password);
  }

  @override
  Future<void> sendVerificationEmail(String email) async {
    await remote.sendVerificationEmail(email);
  }

  @override
  Future<bool> sync() async {
    if (!remote.loggedIn) {
      Log.w('SynchronizedRepository: not logged in, cannot sync. Working offline.');
      return false;
    }

    final timer = Log.timerStart('SynchronizedRepository: starting sync.');
    await remote.sync();

    final syncItems = items as SynchronizedItemDatabase;
    final syncInv = inv as SynchronizedInventoryDatabase;
    final syncHistory = hist as SynchronizedHistoryDatabase;
    final syncHousehold = household as SynchronizedHouseholdDatabase;
    final syncLocation = location as SynchronizedLocationDatabase;
    final syncIdentifiers = identifiers as SynchronizedIdentifierDatabase;

    Log.i('SynchronizedRepository: syncing differences between remote and local.');
    syncItems.syncDifferences();
    syncInv.syncDifferences();
    syncHistory.syncDifferences();
    syncHousehold.syncDifferences();
    syncLocation.syncDifferences();
    syncIdentifiers.syncDifferences();
    Log.timerEnd(timer, 'SynchronizedRepository: finished sync in \$seconds seconds.');

    return true;
  }

  Future<void> _init() async {
    prefs = await DefaultSharedPreferences.create();
    securePrefs = await SecurePreferences.create();

    items = SynchronizedItemDatabase(local.items, remote.items, prefs);
    hist = SynchronizedHistoryDatabase(local.hist, remote.hist, prefs);

    // Note that we do not join the history and item databases here.
    // This is because they are joined at the lower levels of the local
    // and remote databases.
    inv = SynchronizedInventoryDatabase(local.inv, remote.inv, prefs);

    household = SynchronizedHouseholdDatabase(local.household, remote.household, prefs);
    invitation = remote.invitation;

    location = SynchronizedLocationDatabase(local.location, remote.location, prefs);
    identifiers = SynchronizedIdentifierDatabase(local.identifiers, remote.identifiers, prefs);

    ready = true;
  }

  static Future<Repository> create(Repository local, CloudRepository remote) async {
    final repo = SynchronizedRepository._(local, remote);
    await repo._init();
    await repo.sync();
    return repo;
  }
}
