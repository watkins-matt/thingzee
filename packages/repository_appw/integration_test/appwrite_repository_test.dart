import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:repository_appw/repository.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  AppwriteRepository repo = await AppwriteRepository.create() as AppwriteRepository;

  assert(repo.ready);

  String? email = Platform.environment['TEST_USER_EMAIL'];
  String? password = Platform.environment['TEST_USER_PASSWORD'];

  if (email == null || password == null) {
    throw Exception(
        'TEST_USER_EMAIL and TEST_USER_PASSWORD environment variables are not set. Please set them before running the tests.');
  }

  group('AppwriteRepository', () {
    test('User log in works', () async {
      await repo.loginUser(email, password);
      expect(repo.loggedIn, true);
    });

    test('User log out works', () async {
      // await repo.loginUser(email!, password!);
      // await repo.logoutUser();

      // Check that the user is logged out
      expect(repo.loggedIn, false);
    });
  });
}
