import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:log/log.dart';
import 'package:repository/network/connectivity_service.dart';
import 'package:repository/repository.dart';
//import 'package:repository_appw/repository.dart';
import 'package:repository_ob/repository.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:thingzee/app.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    // This line must be first
    WidgetsFlutterBinding.ensureInitialized();

    // Ensure the connectivity checker is running
    final connectivity = ConnectivityService();
    connectivity.ensureRunning();

    // Set demangleStackTrace to handle Riverpod stack traces
    FlutterError.demangleStackTrace = (StackTrace stack) {
      if (stack is Trace) {
        return stack.vmTrace;
      } else if (stack is Chain) {
        return stack.toTrace().vmTrace;
      }
      return stack;
    };

    // Choose the backend and initialize the database
    // final appwrite = await AppwriteRepository.create(connectivity) as AppwriteRepository;
    // final objectbox = await ObjectBoxRepository.create();
    // App.repo = await SynchronizedRepository.create(objectbox, appwrite);
    App.repo = await ObjectBoxRepository.create();
    assert(App.repo.ready);

    // Log any errors from Flutter
    FlutterError.onError = (FlutterErrorDetails details) {
      Log.e('Flutter error:', details.exception, details.stack);
    };

    runApp(const ProviderScope(
      child: App(),
    ));
  },

      // Log any other unhandled errors from within the zone
      (error, stackTrace) {
    Log.e('Unhandled error:', error, stackTrace);
  });
}

final repositoryProvider = Provider<Repository>((ref) {
  return App.repo;
});
