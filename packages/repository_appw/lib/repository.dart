import 'package:appwrite/appwrite.dart';
import 'package:repository/repository.dart';

class AppwriteRepository extends SharedRepository {
  late Client _client;
  late Account _account;
  final String appwriteEndpoint = 'https://cloud.appwrite.io/v1';
  final String projectId = 'placeholder_project_id';

  AppwriteRepository() : super() {
    _init();
  }

  void _init() {
    _client = Client();
    _client.setEndpoint(appwriteEndpoint).setProject(projectId);

    _account = Account(_client);
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
    // Unimplemented
    throw UnimplementedError();
  }
}
