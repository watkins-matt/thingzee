import 'dart:io';

import 'package:repository_appw/repository.dart';
import 'package:test/test.dart';

void main() {
  group('AppwriteRepository', () {
    late AppwriteRepository repository;
    late String? email;
    late String? password;

    setUpAll(() async {
      repository = await AppwriteRepository.create() as AppwriteRepository;
      email = Platform.environment['TEST_USER_EMAIL'];
      password = Platform.environment['TEST_USER_PASSWORD'];

      if (email == null || password == null) {
        throw Exception(
            'TEST_USER_EMAIL and TEST_USER_PASSWORD environment variables are not set. Please set them before running the tests.');
      }
    });

    // test('Validate user registration works', () async {
    //   final username = 'test';
    //   await repository.registerUser(username, email!, password!);
    // });

    test('User log in works', () async {
      await repository.loginUser(email!, password!);
      expect(repository.loggedIn, true);
    });

    test('User log out works', () async {
      await repository.loginUser(email!, password!);
      await repository.logoutUser();

      // Check that the user is logged out
      expect(repository.loggedIn, false);
    });

    test('Test sync', () async {
      await repository.loginUser(email!, password!);

      final result = await repository.sync();
      expect(result, true);
    });
  });
}
