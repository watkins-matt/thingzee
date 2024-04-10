import 'dart:async';

import 'package:log/log.dart';
import 'package:repository/cloud_repository.dart';
import 'package:repository/database/database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/database/synchronized/synchronized_pair.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:repository/network/connectivity_service.dart';

class SynchronizationService<T extends Model> {
  final List<SynchronizedPair<T>> pairs = [];
  final List<CloudRepository> remotes = [];
  final Preferences prefs;
  final ConnectivityService connectivity;

  SynchronizationService(this.prefs, this.connectivity) {
    connectivity.addListener(handleConnectivityChange);
  }

  void add(String name, Database<T> first, Database<T> second) {
    final pair = SynchronizedPair<T>(name, first, second, prefs);
    pairs.add(pair);
  }

  void addRemote(CloudRepository remote) {
    remotes.add(remote);
  }

  void handleConnectivityChange(ConnectivityStatus status) {
    if (status == ConnectivityStatus.online) {
      scheduleMicrotask(() async {
        Log.i('SynchronizationService: Connectivity status change detected: online=true');
        await synchronize();
        Log.i('SynchronizationService: Connectivity status handling completed.');
      });
    }
  }

  Future<void> synchronize({bool skipFetch = false}) async {
    // First, call synchronize on all the remote repositories to get the most
    // recent data.
    if (!skipFetch) {
      await Future.wait(remotes.map((remote) => Future.sync(() => remote.fetch())));
      Log.i('SynchronizationService: Synchronized ${remotes.length} remote repositories.');
    }

    // Then, synchronize all the pairs.
    await Future.wait(pairs.map((pair) => Future.sync(() => pair.synchronize())));
    Log.i('SynchronizationService: Synchronized ${pairs.length} database pairs.');
  }
}
