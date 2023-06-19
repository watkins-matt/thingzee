import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:repository/repository.dart';
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

  void _init() {
    _client = Client();
    _client.setEndpoint(appwriteEndpoint).setProject(projectId).setSelfSigned(status: true);

    _account = Account(_client);
    _databases = Databases(_client);

    items = AppwriteItemDatabase(_databases, 'production', 'items');
  }

  @override
  bool get isMultiUser => true;

  @override
  Future<void> registerUser(String username, String email, String password) async {
    try {
      await _account.create(userId: username, email: email, password: password);
    } catch (e) {
      throw Exception('Failed to register user: $e');
    }
  }

  @override
  Future<void> loginUser(String username, String password) async {
    try {
      _session = await _account.createEmailSession(email: username, password: password);
    } catch (e) {
      throw Exception('Failed to login user: $e');
    }
  }

  @override
  bool get loggedIn =>
      _session != null && DateTime.now().isBefore(DateTime.parse(_session!.expire));
}
