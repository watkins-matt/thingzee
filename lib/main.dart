import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:log/log.dart';
import 'package:repository/cloud_repository.dart';
import 'package:repository/database/joined_item_database.dart';
import 'package:repository/database/mock/repository.dart';
import 'package:repository/database/synchronized/synchronization_service.dart';
import 'package:repository/ml/history.dart';
import 'package:repository/model/filter.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository/model/item.dart';
import 'package:repository/model_provider.dart';
import 'package:repository/network/connectivity_service.dart';
import 'package:repository/repository.dart';
import 'package:repository_appw/repository.dart';
import 'package:repository_ob/repository.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:thingzee/app.dart';
import 'package:thingzee/async_initializer.dart';
import 'package:thingzee/pages/inventory/state/item_thumbnail_cache.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    // This line must be first
    WidgetsFlutterBinding.ensureInitialized();

    // Measure app startup time
    final timer = Log.timerStart('Starting app...');

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

    App.db = await ObjectBoxRepository.create();

    // Initialize model providers
    ModelProvider<History>().init(App.db!.hist);
    ModelProvider<Item>().init(App.db!.items);
    ModelProvider<Inventory>().init(App.db!.inv);

    Log.timerShow(timer, r'Initialized offline database ($seconds seconds).');
    App.thumbnailCache = await createThumbnailCache();
    Log.timerShow(timer, r'Initialized thumbnail cache ($seconds seconds).');

    runApp(
      ProviderScope(
        overrides: [
          // Ensure that the offline database is always ready before the UI is created
          repositoryProvider.overrideWithValue(App.db!),
          itemThumbnailCache.overrideWith(
            (ref) => App.thumbnailCache!,
          )
        ],
        child: const AsyncInitializer(
          child: App(),
        ),
      ),
    );
  },

      // Log any other unhandled errors from within the zone
      (error, stackTrace) {
    Log.e('Unhandled error:', error, stackTrace);
  });
}

final cloudRepoProvider = FutureProvider<CloudRepository>((ref) async {
  final connectivity = ref.watch(connectivityProvider);
  await connectivity.ensureRunning();
  await _waitForOnlineStatus(connectivity);

  final db = ref.watch(repositoryProvider);
  if (db is MockRepository) {
    throw Exception('Offline database is not ready yet.');
  }

  final appwrite = await _retryOnFailure(() => AppwriteRepository.create(connectivity));
  Log.i('initializationProvider: AppwriteRepository initialization complete.');

  assert(appwrite.ready);
  return appwrite as CloudRepository;
});

final connectivityProvider = Provider<ConnectivityService>((ref) => ConnectivityService());

final repositoryProvider = Provider<Repository>((ref) => MockRepository());

final syncServiceProvider = FutureProvider<SynchronizationService>((ref) async {
  final db = ref.watch(repositoryProvider);
  if (db is MockRepository) {
    throw Exception('Database is not ready yet.');
  }

  final connectivity = ref.watch(connectivityProvider);
  final cloud = await ref.watch(cloudRepoProvider.future);
  final syncService = SynchronizationService(db.prefs, connectivity);

  // Set up the synchronization service. This ensures
  // that when the app is online, all changes between the local
  // and remote databases are synchronized.
  syncService.add('Items', db.items, cloud.items);
  syncService.add('Inventory', db.inv, cloud.inv);
  syncService.add('History', db.hist, cloud.hist);
  syncService.add('Household', db.household, cloud.household);
  syncService.add('Location', db.location, cloud.location);
  syncService.add('Identifiers', db.identifiers, cloud.identifiers);

  // We need to add the remote so that the sync service
  // will fetch new data from the remote before attempting synchronization
  syncService.addRemote(cloud);

  // We set up the local database with replication, so that changes
  // made locally are instantly replicated to the cloud database.
  db.items.replicateTo(cloud.items);
  db.inv.replicateTo(cloud.inv);
  db.hist.replicateTo(cloud.hist);
  db.household.replicateTo(cloud.household);
  db.location.replicateTo(cloud.location);
  db.identifiers.replicateTo(cloud.identifiers);

  await syncService.synchronize(skipFetch: true);

  return syncService;
});

Future<ItemThumbnailCache> createThumbnailCache() async {
  assert(App.db != null);
  const preloadCount = 10;

  // Offline db must be initialized first
  final joinedItemDb = JoinedItemDatabase(App.db!.items, App.db!.inv);
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
