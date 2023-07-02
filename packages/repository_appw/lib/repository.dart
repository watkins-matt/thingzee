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
  Future<void> registerUser(String username, String email, String password) async {
    try {
      await _account.create(userId: username, email: email, password: password);
    } catch (e) {
      throw Exception('Failed to register user: $e');
    }

    try {
      _session = await _account.createEmailSession(email: username, password: password);
      await _account.createVerification(url: 'https://appwrite.thingzee.net/verify');
    } catch (e) {
      throw Exception('Failed to send verification email: $e');
    }
  }

  bool sync() {
    if (!loggedIn) {
      return false;
    }

    (items as AppwriteItemDatabase).online = true;
    (inv as AppwriteInventoryDatabase).online = true;
    (hist as AppwriteHistoryDatabase).online = true;
    return true;
  }

  void _init() {
    _client = Client();
    _client.setEndpoint(appwriteEndpoint).setProject(projectId);

    _account = Account(_client);
    _databases = Databases(_client);

    prefs = DefaultSharedPreferences();
    items = AppwriteItemDatabase(_databases, 'test', 'item');
    inv = AppwriteInventoryDatabase(_databases, 'test', 'inventory');
    hist = AppwriteHistoryDatabase(_databases, 'test', 'history');
    ready = true;
  }

  Future<void> _loadSession() async {
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
