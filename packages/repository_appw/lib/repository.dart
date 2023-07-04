import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/repository.dart';
import 'package:repository_appw/database/history_db.dart';
import 'package:repository_appw/database/inventory_db.dart';
import 'package:repository_appw/database/item_db.dart';

class AppwriteRepository extends SharedRepository {
  late Client _client;
  late Account _account;
  late Databases _databases;
  final String appwriteEndpoint = 'https://cloud.appwrite.io/v1';
  final String projectId = 'thingzee';
  Session? _session;

  AppwriteRepository() : super() {
    _init();
    scheduleMicrotask(_loadSession);
  }

  @override
  bool get isMultiUser => true;

  @override
  bool get loggedIn =>
      _session != null && DateTime.now().isBefore(DateTime.parse(_session!.expire));

  @override
  Future<void> loginUser(String email, String password) async {
    try {
      await _loadSession();

      // If no valid session, then login
      if (_session == null) {
        _session = await _account.createEmailSession(email: email, password: password);

        await prefs.setString('appwrite_session_id', _session!.$id);
        await prefs.setString('appwrite_session_expire', _session!.expire);
        sync();
      }
    } catch (e) {
      throw Exception('Failed to login user: $e');
    }
  }

  @override
  Future<void> logoutUser() async {
    if (_session != null) {
      await _account.deleteSession(sessionId: _session!.$id);
      _session = null;

      await prefs.remove('appwrite_session_id');
      await prefs.remove('appwrite_session_expire');
    }
  }

  @override
  Future<void> registerUser(String username, String email, String password) async {
    // Try to create the user
    try {
      await _account.create(userId: username, email: email, password: password);
    } catch (e) {
      throw Exception('Failed to register user: $e');
    }

    // Should login immediately after registering
    await loginUser(email, password);

    // Send the verification email
    try {
      await _account.createVerification(url: 'https://appwrite.thingzee.net/verify');
    } catch (e) {
      throw Exception('Failed to send verification email: $e');
    }
  }

  bool sync() {
    if (!loggedIn) {
      return false;
    }

    final items = this.items as AppwriteItemDatabase;
    final inv = this.inv as AppwriteInventoryDatabase;
    final hist = this.hist as AppwriteHistoryDatabase;

    items.handleConnectionChange(true, _session!);
    inv.handleConnectionChange(true, _session!);
    hist.handleConnectionChange(true, _session!);

    return true;
  }

  void _init() {
    _client = Client();
    _client.setEndpoint(appwriteEndpoint).setProject(projectId);

    _account = Account(_client);
    _databases = Databases(_client);

    prefs = DefaultSharedPreferences();
    items = AppwriteItemDatabase(_databases, 'test', 'user_item');
    inv = AppwriteInventoryDatabase(_databases, 'test', 'user_inventory');
    hist = AppwriteHistoryDatabase(_databases, 'test', 'user_history');
    ready = true;
  }

  Future<void> _loadSession() async {
    // Don't do anything if we have a session already
    if (_session != null) {
      return;
    }

    if (prefs.containsKey('appwrite_session_id') && prefs.containsKey('appwrite_session_expire')) {
      String sessionId = prefs.getString('appwrite_session_id')!;
      String expiration = prefs.getString('appwrite_session_expire')!;
      final expireDate = DateTime.parse(expiration);

      if (DateTime.now().isBefore(expireDate)) {
        _session = await _account.getSession(sessionId: sessionId);
        sync();
      }

      // Just remove the preferences if the session is expired
      else {
        await prefs.remove('appwrite_session_id');
        await prefs.remove('appwrite_session_expire');
      }
    }
  }
}
