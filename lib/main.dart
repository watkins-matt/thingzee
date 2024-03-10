import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:log/log.dart';
import 'package:repository/database/joined_item_database.dart';
import 'package:repository/database/mock/repository.dart';
import 'package:repository/ml/history_provider.dart';
import 'package:repository/model/filter.dart';
import 'package:repository/network/connectivity_service.dart';
import 'package:repository/repository.dart';
import 'package:repository/sync_repository.dart';
import 'package:repository_appw/repository.dart';
import 'package:repository_ob/repository.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:thingzee/app.dart';
import 'package:thingzee/pages/inventory/state/item_thumbnail_cache.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    // This line must be first
    WidgetsFlutterBinding.ensureInitialized();

    // Measure app startup time
    final timer = Log.timerStart('Starting app.');

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
    HistoryProvider().init(App.offlineDb!);
    Log.timerShow(timer, r'Initialized offline database ($seconds seconds).');
    App.thumbnailCache = await createThumbnailCache();
    Log.timerShow(timer, r'Initialized thumbnail cache ($seconds seconds).');

    runApp(
      ProviderScope(
        overrides: [
          // Ensure that the offline database is always ready before the UI is created
          offlineDatabaseProvider.overrideWithValue(App.offlineDb!),
          itemThumbnailCache.overrideWith(
            (ref) => App.thumbnailCache!,
          )
        ],
        child: App(
          startupTimer: timer,
        ),
      ),
    );
  },

      // Log any other unhandled errors from within the zone
      (error, stackTrace) {
    Log.e('Unhandled error:', error, stackTrace);
  });
}

final initializationProvider = FutureProvider<Repository>((ref) async {
  final connectivity = ConnectivityService();
  await connectivity.ensureRunning();
  await _waitForOnlineStatus(connectivity);

  final objectbox = ref.watch(offlineDatabaseProvider);
  if (objectbox is MockRepository) {
    throw Exception('Offline database is not ready yet.');
  }

  final appwrite = await _retryOnFailure(() => AppwriteRepository.create(connectivity));
  Log.i('initializationProvider: AppwriteRepository initialization complete.');
  final repo = await SynchronizedRepository.create(objectbox, appwrite as AppwriteRepository);
  Log.i('initializationProvider: SynchronizedRepository initialization complete.');

  HistoryProvider().init(repo);

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

Future<ItemThumbnailCache> createThumbnailCache() async {
  assert(App.offlineDb != null);
  const preloadCount = 10;

  // Offline db must be initialized first
  final joinedItemDb = JoinedItemDatabase(App.offlineDb!.items, App.offlineDb!.inv);
  const defaultFilter = Filter();

  // Create a list of items using the default filter order by name
  // and convert it to a list of upcs
  List<JoinedItem> joinedItems = joinedItemDb.filter(defaultFilter);
  List<String> upcListToPreload = joinedItems.map((e) => e.item.upc).toList();

  // If the list is long, only preload up to preloadCount. Otherwise
  // we don't need a sublist because the list is small enough already.
  if (upcListToPreload.length > preloadCount) {
    upcListToPreload = upcListToPreload.sublist(0, preloadCount);
  }

  final preloadedThumbnailCache = await ItemThumbnailCache.withPreload(upcListToPreload);

  return preloadedThumbnailCache;
}

Future<T> _retryOnFailure<T>(Future<T> Function() operation,
    {int maxAttempts = 3, Duration initialDelay = const Duration(seconds: 2)}) async {
  int attempts = 0;
  Duration delay = initialDelay;

  while (true) {
    try {
      return await operation();
    } catch (e) {
      if (++attempts >= maxAttempts) rethrow;
      Log.w('Operation failed, retrying attempt $attempts after ${delay.inSeconds} seconds', e);
      await Future.delayed(delay);

      // Increase the delay for the next attempt
      delay *= 2;
    }
  }
}

Future<void> _waitForOnlineStatus(ConnectivityService connectivity) async {
  Completer<void> completer = Completer();

  void listener(ConnectivityStatus status) {
    if (status == ConnectivityStatus.online && !completer.isCompleted) {
      completer.complete();
      connectivity.removeListener(listener);
    }
  }

  connectivity.addListener(listener);

  // If already online, complete immediately
  if (connectivity.status == ConnectivityStatus.online && !completer.isCompleted) {
    completer.complete();
  }

  return completer.future;
}
