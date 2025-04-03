import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' hide Log, Preferences;
import 'package:log/log.dart';
import 'package:repository/cloud_repository.dart';
import 'package:repository/database/preferences_default.dart';
import 'package:repository/database/preferences_secure.dart';
import 'package:repository/network/connectivity_service.dart';
import 'package:repository/repository.dart';
import 'package:repository/util/hash.dart';
import 'package:repository_appw/database/history_db.dart';
import 'package:repository_appw/database/household_db.dart';
import 'package:repository_appw/database/identifier_db.dart';
import 'package:repository_appw/database/inventory_db.dart';
import 'package:repository_appw/database/invitation_db.dart';
import 'package:repository_appw/database/item_db.dart';
import 'package:repository_appw/database/location_db.dart';

class AppwriteRepository extends CloudRepository {
  late Client _client;
  late Account _account;
  late Databases _databases;
  late Teams _teams;
  final String appwriteEndpoint = 'https://cloud.appwrite.io/v1';
  final String projectId = 'thingzee';
  final String verificationEndpoint = 'https://verify.thingzee.net';
  Session? _session;
  DateTime? _lastFetch;
  final int syncCooldown = 60;
  bool _verified = false;
  String _userId = '';
  String _userEmail = '';

  AppwriteRepository._(super.service);

  @override
  bool get isMultiUser => true;

  @override
  bool get isUserVerified => _verified;

  @override
  bool get loggedIn =>
      _session != null && DateTime.now().isBefore(DateTime.parse(_session!.expire));

  @override
  String get userEmail => _userEmail;

  @override
  String get userId => _userId;

  @override
  Future<bool> checkVerificationStatus() async {
    // Users will never become unverified, so only check once
    if (_verified) return true;

    try {
      final userInfo = await _account.get();
      _verified = userInfo.emailVerification;
    } on AppwriteException catch (e) {
      Log.e('AppwriteRepository: Failed to check verification status: [AppwriteException]',
          e.message);
      return false;
    } on TypeError catch (e) {
      Log.e('AppwriteRepository: Type error:', e);
      return false;
    }

    return _verified;
  }

  @override
  Future<bool> fetch({bool ignoreCooldown = false}) async {
    if (!ready || !loggedIn || connectivity.status != ConnectivityStatus.online) {
      return false;
    }

    // Don't fetch if we are within the cooldown period
    if (!ignoreCooldown &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!).inSeconds < syncCooldown) {
      Log.i('AppwriteRepository: Cooldown period, not fetching data.');
      return false;
    }

    final timer = Log.timerStart('AppwriteRepository: Fetching remote data...');

    // Recheck verification status on each fetch
    await checkVerificationStatus();

    final items = this.items as AppwriteItemDatabase;
    final inv = this.inv as AppwriteInventoryDatabase;
    final hist = this.hist as AppwriteHistoryDatabase;
    final household = this.household as AppwriteHouseholdDatabase;
    final invitation = this.invitation as AppwriteInvitationDatabase;
    final location = this.location as AppwriteLocationDatabase;
    final identifiers = this.identifiers as AppwriteIdentifierDatabase;

    try {
      // Prepare a list of fetch operations for each database
      final fetchOperations = [
        items.handleConnectionChange(true, _session),
        inv.handleConnectionChange(true, _session),
        hist.handleConnectionChange(true, _session),
        household.handleConnectionChange(true, _session),
        invitation.handleConnectionChange(true, _session),
        location.handleConnectionChange(true, _session),
        identifiers.handleConnectionChange(true, _session),
      ];

      // Execute all fetch operations simultaneously and wait for them to complete
      await Future.wait(fetchOperations);

      Log.timerEnd(timer, 'AppwriteRepository: Fetch data completed in \$seconds seconds.');
      _lastFetch = DateTime.now();

      return true;
    } catch (e, stackTrace) {
      Log.e('AppwriteRepository: Error during fetch.', e, stackTrace);
      return false;
    }
  }

  @override
  void handleConnectivityChange(ConnectivityStatus status) {
    // Don't fetch anything if we haven't initialized yet
    if (!ready) {
      return;
    }

    bool online = status == ConnectivityStatus.online;

    scheduleMicrotask(() async {
      if (_lastFetch != null && DateTime.now().difference(_lastFetch!).inSeconds < syncCooldown) {
        Log.i('AppwriteRepository: Cooldown period, not fetching data.');
        return;
      }

      Log.i('AppwriteRepository: Connectivity status change detected: online=$online');
      final items = this.items as AppwriteItemDatabase;
      final inv = this.inv as AppwriteInventoryDatabase;
      final hist = this.hist as AppwriteHistoryDatabase;
      final household = this.household as AppwriteHouseholdDatabase;
      final invitation = this.invitation as AppwriteInvitationDatabase;
      final location = this.location as AppwriteLocationDatabase;
      final identifiers = this.identifiers as AppwriteIdentifierDatabase;

      final connectionChangeOperations = [
        items.handleConnectionChange(online, _session),
        inv.handleConnectionChange(online, _session),
        hist.handleConnectionChange(online, _session),
        household.handleConnectionChange(online, _session),
        invitation.handleConnectionChange(online, _session),
        location.handleConnectionChange(online, _session),
        identifiers.handleConnectionChange(online, _session),
      ];

      await Future.wait(connectionChangeOperations);

      Log.i('AppwriteRepository: Connectivity status handling completed.');
      _lastFetch = DateTime.now();
    });
  }

  @override
  Future<bool> loginUser(String email, String password) async {
    try {
      // Load the user info
      _userId = hashEmail(email);
      _userEmail = email;

      // Store the username and password for later use
      await prefs.setString('appwrite_session_user', _userId);
      await prefs.setString('appwrite_session_email', _userEmail);

      // Attempt to load the existing session
      await _loadSession();

      // If no valid session, then login
      if (_session == null) {
        _session = await _account.createEmailPasswordSession(email: email, password: password);

        await prefs.setString('appwrite_session_id', _session!.$id);
        await prefs.setString('appwrite_session_expire', _session!.expire);
        await fetch(ignoreCooldown: true);
      }
    } catch (e, st) {
      Log.w('AppwriteRepository: Failed to login user:', e, st);
      _userId = '';
      _userEmail = '';
      return false;
    }

    return true;
  }

  @override
  Future<void> logoutUser() async {
    if (_session != null) {
      await _account.deleteSession(sessionId: _session!.$id);
      _session = null;

      await prefs.remove('appwrite_session_id');
      await prefs.remove('appwrite_session_expire');
      await prefs.remove('appwrite_session_user');
      await prefs.remove('appwrite_session_email');

      _userId = '';
      _userEmail = '';

      final items = this.items as AppwriteItemDatabase;
      final inv = this.inv as AppwriteInventoryDatabase;
      final hist = this.hist as AppwriteHistoryDatabase;
      final household = this.household as AppwriteHouseholdDatabase;
      final invitation = this.invitation as AppwriteInvitationDatabase;
      final location = this.location as AppwriteLocationDatabase;
      final identifiers = this.identifiers as AppwriteIdentifierDatabase;

      final connectionChangeOperations = [
        items.handleConnectionChange(false, null),
        inv.handleConnectionChange(false, null),
        hist.handleConnectionChange(false, null),
        household.handleConnectionChange(false, null),
        invitation.handleConnectionChange(false, null),
        location.handleConnectionChange(false, null),
        identifiers.handleConnectionChange(false, null),
      ];

      await Future.wait(connectionChangeOperations);
      Log.i('AppwriteRepository: Successfully logged out user.');
    }
  }

  @override
  Future<bool> registerUser(String username, String email, String password) async {
    // Try to create the user
    try {
      await _account.create(userId: username, email: email, password: password);
    } on AppwriteException catch (e) {
      Log.e('AppwriteRepository: Failed to register user: [AppwriteException]', e.message);
      rethrow; // Rethrow the exception so the UI can handle showing the error
    }

    // Should login immediately after registering
    await loginUser(email, password);

    // Send the verification email
    try {
      await _account.createVerification(url: verificationEndpoint);
    } on AppwriteException catch (e) {
      Log.e(
          'AppwriteRepository: Failed to send verification email: [AppwriteException]', e.message);
      rethrow; // Rethrow the exception so the UI can handle showing the error
    }

    return true;
  }

  @override
  Future<void> sendVerificationEmail(String email) async {
    try {
      await _account.createVerification(url: verificationEndpoint);
    } on AppwriteException catch (e) {
      Log.e(
          'AppwriteRepository: Failed to send verification email: [AppwriteException]', e.message);
    }
  }

  Future<void> _init() async {
    final timer = Log.timerStart();

    _client = Client();
    _client.setEndpoint(appwriteEndpoint).setProject(projectId);

    _account = Account(_client);
    _databases = Databases(_client);
    _teams = Teams(_client);

    prefs = await DefaultSharedPreferences.create();
    securePrefs = await SecurePreferences.create();

    items = AppwriteItemDatabase(prefs, _databases, 'test', 'user_item');
    hist = AppwriteHistoryDatabase(prefs, _databases, 'test', 'user_history');
    inv = AppwriteInventoryDatabase(prefs, _databases, 'test', 'user_inventory');

    household = AppwriteHouseholdDatabase(_teams, _databases, prefs, 'test', 'user_household');
    invitation = AppwriteInvitationDatabase(prefs, _databases, 'test', 'invitation', household.id);
    location = AppwriteLocationDatabase(prefs, _databases, 'test', 'user_location');
    identifiers = AppwriteIdentifierDatabase(prefs, _databases, 'test', 'user_identifier');

    Log.timerEnd(timer, 'AppwriteRepository: initialized in \$seconds seconds.');
    ready = true;
  }

  Future<void> _loadSession() async {
    Log.i('AppwriteRepository: Checking for existing session...');

    // Don't do anything if we have a session already or we are offline
    if (_session != null || connectivity.status != ConnectivityStatus.online) {
      return;
    }

    await _loadUserInfo();

    if (prefs.containsKey('appwrite_session_id') && prefs.containsKey('appwrite_session_expire')) {
      String sessionId = prefs.getString('appwrite_session_id')!;
      String expiration = prefs.getString('appwrite_session_expire')!;
      final expireDate = DateTime.parse(expiration);

      if (DateTime.now().isBefore(expireDate)) {
        Log.i('AppwriteRepository: Session found, loading...');
        try {
          _session = await _account.getSession(sessionId: sessionId);
          await fetch(ignoreCooldown: true);
        } on AppwriteException catch (e) {
          Log.e('AppwriteRepository._loadSession: Failed to load session: [AppwriteException]',
              e.message);
          _session = null;
          Log.i('Appwrite: Removed invalid session. Log in required.');
          await prefs.remove('appwrite_session_id');
          await prefs.remove('appwrite_session_expire');
          await prefs.remove('appwrite_session_user');
          await prefs.remove('appwrite_session_email');
          return;
        }
      }

      // Just remove the preferences if the session is expired
      else {
        Log.i('Appwrite: Session expired, deleting...');
        await prefs.remove('appwrite_session_id');
        await prefs.remove('appwrite_session_expire');
        await prefs.remove('appwrite_session_user');
        await prefs.remove('appwrite_session_email');
      }
    } else {
      Log.i('Appwrite: No session found. Log in required.');
    }
  }

  Future<void> _loadUserInfo() async {
    if (!ready) {
      return;
    }

    // We already have the info loaded
    if (_userId != '' && _userEmail != '') {
      return;
    }

    if (prefs.containsKey('appwrite_session_user') && prefs.containsKey('appwrite_session_email')) {
      _userId = prefs.getString('appwrite_session_user')!;
      _userEmail = prefs.getString('appwrite_session_email')!;
    } else {
      try {
        final userInfo = await _account.get();
        _userId = hashEmail(userInfo.email);
        _userEmail = userInfo.email;

        await prefs.setString('appwrite_session_user', _userId);
        await prefs.setString('appwrite_session_email', _userEmail);
      } on AppwriteException catch (e) {
        if (e.code == 401) {
          Log.i('AppwriteRepository._loadUserInfo: User not logged in.');
          return;
        }

        Log.e('AppwriteRepository._loadUserInfo: Failed to load user: [AppwriteException]',
            e.message);
        _session = null;
        Log.i('Appwrite: Removed invalid session. Log in required.');
        await prefs.remove('appwrite_session_id');
        await prefs.remove('appwrite_session_expire');
        await prefs.remove('appwrite_session_user');
        await prefs.remove('appwrite_session_email');
        return;
      }
    }
  }

  static Future<Repository> create(ConnectivityService service) async {
    final repo = AppwriteRepository._(service);
    await repo._init();
    await repo._loadSession();
    return repo;
  }
}
