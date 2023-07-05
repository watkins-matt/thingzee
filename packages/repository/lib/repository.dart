import 'package:repository/database/history_database.dart';
import 'package:repository/database/inventory_database.dart';
import 'package:repository/database/item_database.dart';
import 'package:repository/database/preferences.dart';

abstract class Repository {
  bool ready = false;
  bool get isMultiUser => false;
  bool get loggedIn => false;

  late ItemDatabase items;
  late InventoryDatabase inv;
  late HistoryDatabase hist;
  late Preferences prefs;
}

abstract class CloudRepository extends Repository {
  @override
  bool get isMultiUser => true;

  Future<void> registerUser(String username, String email, String password);
  Future<void> loginUser(String email, String password);
  Future<void> logoutUser();
}

class SynchronizedRepository extends CloudRepository {
  final Repository local;
  final CloudRepository remote;

  SynchronizedRepository(this.local, this.remote);

  @override
  bool get isMultiUser => true;

  @override
  bool get loggedIn => remote.loggedIn;

  @override
  Future<void> registerUser(String username, String email, String password) async {
    await remote.registerUser(username, email, password);
  }

  @override
  Future<void> loginUser(String email, String password) async {
    await remote.loginUser(email, password);
  }

  @override
  Future<void> logoutUser() async {
    await remote.logoutUser();
  }
}
