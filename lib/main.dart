import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/repository.dart';
import 'package:repository_ob/repository.dart';
import 'package:thingzee/app.dart';

final repositoryProvider = Provider<Repository>((ref) {
  return App.repo;
});

Future<void> main() async {
  // This line must be first
  WidgetsFlutterBinding.ensureInitialized();

  // Choose the backend and initialize the database
  App.repo = await ObjectBoxRepository.create();
  assert(App.repo.ready);

  runApp(const ProviderScope(
    child: App(),
  ));
}
