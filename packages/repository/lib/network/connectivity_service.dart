import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._();
  StreamSubscription<ConnectivityResult>? _subscription;
  ConnectivityStatus status = ConnectivityStatus.offline;

  final _listeners = <void Function(ConnectivityStatus)>[];
  factory ConnectivityService() {
    return _instance;
  }

  ConnectivityService._() {
    _subscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      _updateConnectionStatus(result);
    });
  }

  void addListener(void Function(ConnectivityStatus) callback) {
    _listeners.add(callback);
  }

  void close() {
    _subscription?.cancel();
    _subscription = null;
  }

  void ensureRunning() {
    _subscription ??= Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      _updateConnectionStatus(result);
    });
  }

  void removeListener(void Function(ConnectivityStatus) callback) {
    _listeners.remove(callback);
  }

  void _notifyListeners(ConnectivityStatus status) {
    for (final listener in _listeners) {
      listener(status);
    }
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    // If ConnectivityResult is none, then we are offline
    if (result == ConnectivityResult.none) {
      _notifyListeners(ConnectivityStatus.offline);
    }

    // Try to look up an address to verify we are online
    else {
      try {
        final result = await InternetAddress.lookup('cloud.appwrite.io');
        // We connected successfully, and are online
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          _notifyListeners(ConnectivityStatus.online);
        }
        // We're offline
        else {
          _notifyListeners(ConnectivityStatus.offline);
        }
      }

      // If we get an exception, then we are offline
      on SocketException catch (_) {
        _notifyListeners(ConnectivityStatus.offline);
      }
    }
  }
}

enum ConnectivityStatus { online, offline }
