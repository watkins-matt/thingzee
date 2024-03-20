// ignore_for_file: avoid_renaming_method_parameters

import 'package:appwrite/appwrite.dart';
import 'package:log/log.dart';
import 'package:repository/database/household_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/model/household_member.dart';
import 'package:repository/util/hash.dart';
import 'package:repository_appw/util/appwrite_database.dart';
import 'package:repository_appw/util/synchronizable.dart';
import 'package:uuid/uuid.dart';

class AppwriteHouseholdDatabase extends HouseholdDatabase
    with AppwriteSynchronizable<HouseholdMember>, AppwriteDatabase<HouseholdMember> {
  static const String TAG = 'AppwriteHouseholdDatabase';
  final Teams _teams;
  final Preferences prefs;
  String _householdId = '';
  DateTime _created = DateTime.now();

  AppwriteHouseholdDatabase(
    this._teams,
    Databases database,
    this.prefs,
    String databaseId,
    String collectionId,
  ) : super() {
    constructDatabase(TAG, database, databaseId, collectionId);
    constructSynchronizable(TAG, prefs, onConnectivityChange: connectivityChanged);
  }

  @override
  List<HouseholdMember> get admins => values.where((element) => element.isAdmin).toList();

  @override
  DateTime get created => _created;

  @override
  String get id => _householdId;

  Future<void> connectivityChanged(bool online) async {
    if (online) {
      await _initializeHousehold();
      await taskQueue.runUntilComplete();
    }
  }

  @override
  HouseholdMember? deserialize(Map<String, dynamic> json) => HouseholdMember.fromJson(json);

  @override
  void leave() {
    taskQueue.queueTask(() async {
      // Logic to leave the household:
      // 1. Remove the user from the team.
      // 2. Delete or update the household document in the database.
      // 3. Update the preferences to remove householdId.
    });
    prefs.remove('householdId');
  }

  @override
  void put(HouseholdMember member, {List<String>? permissions}) {
    if (member.householdId.isEmpty || member.householdId != _householdId) {
      member = member.copyWith(householdId: _householdId);
    }

    if (member.userId.isEmpty && member.email.isNotEmpty) {
      member = member.copyWith(userId: hashEmail(member.email));
    }

    if (member.email.isEmpty) {
      throw Exception('Cannot put member without valid email.');
    }

    if (member.name.isEmpty) {
      throw Exception('Cannot put member without valid name.');
    }

    super.put(member, permissions: permissions);
  }

  Future<void> _createNewHousehold() async {
    _householdId = const Uuid().v4();
    _created = DateTime.now();
    await prefs.setString('household_id', _householdId);
    await prefs.setInt('household_created', _created.millisecondsSinceEpoch);

    try {
      await _teams.create(teamId: _householdId, name: _householdId);
    } on AppwriteException catch (e) {
      Log.e('Failed to create team: [AppwriteException]', e.message);
      rethrow;
    }
  }

  Future<bool> _createTeam() async {
    try {
      await _teams.create(teamId: _householdId, name: _householdId);
      return true;
    } on AppwriteException catch (e) {
      // Team already exists
      if (e.code == 409) {
        Log.w('Team already exists, not creating anything.', e.toString());
        return true;
      }
      // Another AppwriteException occurred
      Log.e('Error while creating team: [AppwriteException]', e.toString());
      return false;
    } on Exception catch (e) {
      Log.e('Error while creating team: [Exception]', e.toString());
      return false;
    }
  }

  Future<void> _initializeHousehold() async {
    if (!online) {
      throw Exception('Cannot initialize household while offline.');
    }

    final householdId = prefs.getString('household_id');
    final householdCreated = prefs.getInt('household_created');

    // Household is already initialized
    if (_householdId == householdId && _created.millisecondsSinceEpoch == householdCreated) {
      return;
    }
    // Missing household information, need to create a new household
    else if (householdId == null || householdCreated == null) {
      await _createNewHousehold();
    }
    // Household information exists, load the household
    else {
      _householdId = householdId;
      _created = DateTime.fromMillisecondsSinceEpoch(householdCreated);

      try {
        await _teams.get(teamId: _householdId);
      } on AppwriteException catch (e) {
        // Team does not exist, create it
        if (e.code == 404) {
          final success = await _createTeam();
          if (!success) {
            throw Exception('Failed to create Appwrite team for existing household');
          }
        }
        // Other errors
        else {
          Log.e('Failed to load team: [AppwriteException]', e.message);
          rethrow;
        }
      } on TypeError catch (e) {
        Log.e('[TypeError] Appwrite:', e.toString());
      }
    }
  }
}
