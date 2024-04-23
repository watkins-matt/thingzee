import 'dart:async';

import 'package:log/log.dart';
import 'package:repository/cloud_repository.dart';
import 'package:repository/network/connectivity_service.dart';
import 'package:repository_ha/database/shopping_list_db.dart';
import 'package:repository_ha/home_assistant_api.dart';

class HomeAssistantRepository extends CloudRepository {
  HomeAssistantApi homeAssistant;
  DateTime? _lastFetch;
  final int syncCooldown = 60;

  HomeAssistantRepository(
      String baseUrl, String token, String entityId, ConnectivityService service)
      : homeAssistant = HomeAssistantApi(baseUrl, token),
        super(service) {
    homeAssistant.connect();
    shopping = HomeAssistantShoppingListDatabase(homeAssistant, entityId);
    ready = true;
  }

  @override
  bool get isMultiUser => false;

  @override
  bool get isUserVerified => false;

  @override
  bool get loggedIn => false;

  @override
  String get userEmail => throw UnimplementedError();

  @override
  String get userId => throw UnimplementedError();

  @override
  Future<bool> checkVerificationStatus() => throw UnimplementedError();

  @override
  Future<bool> fetch({bool ignoreCooldown = false}) async {
    if (!ready || connectivity.status != ConnectivityStatus.online) {
      return false;
    }

    // Don't fetch if we are within the cooldown period
    if (!ignoreCooldown &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!).inSeconds < syncCooldown) {
      Log.i('HomeAssistantRepository: Cooldown period, not fetching data.');
      return false;
    }

    final timer = Log.timerStart('HomeAssistantRepository: Fetching remote data...');

    final list = shopping as HomeAssistantShoppingListDatabase;
    await list.fetch();

    Log.timerEnd(timer, 'HomeAssistantRepository: Fetch data completed in \$seconds seconds.');
    _lastFetch = DateTime.now();
    return true;
  }

  @override
  void handleConnectivityChange(ConnectivityStatus status) {
    // Don't fetch anything if we haven't initialized yet
    if (!ready) {
      return;
    }

    bool online = status == ConnectivityStatus.online;

    scheduleMicrotask(() async {
      if (online) {
        await fetch();
      }
    });
  }

  @override
  Future<bool> loginUser(String email, String password) => throw UnimplementedError();

  @override
  Future<void> logoutUser() async => throw UnimplementedError();

  @override
  Future<bool> registerUser(String username, String email, String password) async =>
      throw UnimplementedError();

  @override
  Future<void> sendVerificationEmail(String email) async => throw UnimplementedError();
}
