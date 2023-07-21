import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:log/log.dart';
import 'package:repository/database/mock/repository.dart';
import 'package:repository/network/connectivity_service.dart';
import 'package:repository/repository.dart';
import 'package:repository_appw/repository.dart';
import 'package:repository_ob/repository.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:thingzee/app.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    // This line must be first
    WidgetsFlutterBinding.ensureInitialized();

    // Set demangleStackTrace to handle Riverpod stack traces
    FlutterError.demangleStackTrace = (StackTrace stack) {
      if (stack is Trace) {
        return stack.vmTrace;
      } else if (stack is Chain) {
        return stack.toTrace().vmTrace;
      }
      return stack;
    };

    // Log any errors from Flutter
    FlutterError.onError = (FlutterErrorDetails details) {
      Log.e('Flutter error:', details.exception, details.stack);
    };

    App.offlineDb = await ObjectBoxRepository.create();
    runApp(const ProviderScope(
      child: App(),
    ));
  },

      // Log any other unhandled errors from within the zone
      (error, stackTrace) {
    Log.e('Unhandled error:', error, stackTrace);
  });
}

final initializationProvider = FutureProvider<Repository>((ref) async {
  final connectivity = ConnectivityService();
  await connectivity.ensureRunning();
  connectivity.addListener((status) {
    Log.d('Connectivity changed: $status');
  });

  final objectbox = ref.watch(offlineDatabaseProvider);
  if (objectbox is MockRepository) {
    throw Exception('Offline database is not ready yet.');
  }

  final appwrite = await AppwriteRepository.create(connectivity) as AppwriteRepository;
  Log.i('initializationProvider: AppwriteRepository initialization complete.');
  final repo = await SynchronizedRepository.create(objectbox, appwrite);
  Log.i('initializationProvider: SynchronizedRepository initialization complete.');

  assert(repo.ready);
  return repo;
});

final offlineDatabaseProvider = Provider<Repository>((ref) {
  // Note that App.offlineDb is initialized in main, so that it is
  // ready before the UI is created
  return App.offlineDb ?? MockRepository();
});

final repositoryProvider = Provider<Repository>((ref) {
  final offlineDbState = ref.watch(offlineDatabaseProvider);
  final initDbState = ref.watch(initializationProvider);

  if (initDbState is AsyncData<Repository>) {
    // Full repository is ready, return it
    return initDbState.value;
  } else {
    // Full repository is not ready, return offline database
    return offlineDbState;
  }
});
