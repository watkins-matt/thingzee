// ignore_for_file: avoid_renaming_method_parameters

import 'package:appwrite/appwrite.dart';
import 'package:log/log.dart';
import 'package:repository/database/household_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/model/household_member.dart';
import 'package:repository/util/hash.dart';
import 'package:repository_appw/database/inventory_db.dart';
import 'package:repository_appw/database/item_db.dart';
import 'package:repository_appw/util/appwrite_database.dart';
import 'package:repository_appw/util/synchronizable.dart';
import 'package:uuid/uuid.dart';

class AppwriteHouseholdDatabase extends HouseholdDatabase
    with AppwriteSynchronizable<HouseholdMember>, AppwriteDatabase<HouseholdMember> {
  static const String tag = 'AppwriteHouseholdDatabase';
  final Teams _teams;
  final Databases _databases;
  final Preferences prefs;
  String _householdId = '';
  DateTime _created = DateTime.now();

  // Database IDs for inventory and item collections
  final String _databaseId;
  final String _inventoryCollectionId;

  // References to other databases for updating when household changes
  AppwriteInventoryDatabase? _inventoryDb;
  AppwriteItemDatabase? _itemDb;

  AppwriteHouseholdDatabase(
    this._teams,
    Databases database,
    this.prefs,
    String databaseId,
    String collectionId, {
    String? inventoryCollectionId,
  })  : _databases = database,
        _databaseId = databaseId,
        _inventoryCollectionId = inventoryCollectionId ?? 'user_inventory',
        super() {
    constructDatabase(tag, database, databaseId, collectionId);
    constructSynchronizable(tag, prefs, onConnectivityChange: connectivityChanged);
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
  Future<void> join(String householdId) async {
    if (!online) {
      throw Exception('Cannot join household while offline.');
    }

    // Store the old household ID
    final oldHouseholdId = _householdId;

    try {
      // 1. Verify the household exists
      await _teams.get(teamId: householdId);

      // 2. Update the household ID
      _householdId = householdId;
      _created = DateTime.now(); // This might need to be fetched from the team

      // 3. Save to preferences
      await prefs.setString('household_id', _householdId);
      await prefs.setInt('household_created', _created.millisecondsSinceEpoch);

      // 4. Update all inventory items to have the new household ID
      await updateInventoryHouseholdIds();

      Log.i('$tag: User successfully joined household $householdId');
      return;
    } on AppwriteException catch (e) {
      // Revert to old household ID if there was an error
      _householdId = oldHouseholdId;
      Log.e('$tag: Failed to join household: [AppwriteException]', e.message);
      throw Exception('Failed to join household: ${e.message}');
    } catch (e) {
      // Revert to old household ID if there was an error
      _householdId = oldHouseholdId;
      Log.e('$tag: Failed to join household: [Exception]', e.toString());
      throw Exception('Failed to join household: $e');
    }
  }

  @override
  void leave() {
    // Store the old household ID before removing it
    final oldHouseholdId = _householdId;

    taskQueue.queueTask(() async {
      try {
        // 1. Get the user's membership in the team
        final memberships = await _teams.listMemberships(
          teamId: oldHouseholdId,
          queries: [Query.equal('userId', userId)],
        );

        if (memberships.total > 0) {
          // 2. Remove the user from the team
          final membershipId = memberships.memberships[0].$id;
          await _teams.deleteMembership(
            teamId: oldHouseholdId,
            membershipId: membershipId,
          );

          Log.i('$tag: User successfully removed from household team.');
        } else {
          Log.w('$tag: User not found in household team.');
        }

        // 3. Create a new household for the user
        await _createNewHousehold();

        // 4. Copy all inventory items to the new household
        await _copyInventoryToNewHousehold(oldHouseholdId, _householdId);

        Log.i('$tag: User successfully left household and inventory copied to new household.');
      } on AppwriteException catch (e) {
        Log.e('$tag: Failed to leave household: [AppwriteException]', e.message);
      } catch (e) {
        Log.e('$tag: Failed to leave household: [Exception]', e.toString());
      }
    });

    // Immediately remove from preferences for UI responsiveness
    prefs.remove('household_id');
    prefs.remove('household_created');
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

  /// Sets the inventory database reference
  void setInventoryDatabase(AppwriteInventoryDatabase db) {
    _inventoryDb = db;
  }

  /// Sets the item database reference
  void setItemDatabase(AppwriteItemDatabase db) {
    _itemDb = db;
  }

  @override
  Future<void> updateInventoryHouseholdIds() async {
    if (!online) {
      throw Exception('Cannot update inventory household IDs while offline.');
    }

    try {
      // 1. Get all inventory items for the current user
      final inventoryDocs = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _inventoryCollectionId,
        queries: [Query.equal('userId', userId)],
      );

      // 2. Update each inventory item with the new household ID
      for (final doc in inventoryDocs.documents) {
        final Map<String, dynamic> data = doc.data;

        // Skip if the household ID is already correct
        if (data['householdId'] == _householdId) continue;

        // Update the household ID
        data['householdId'] = _householdId;

        // Add household team permissions
        final teamPermissions = [
          Permission.read(Role.team(_householdId)),
          Permission.update(Role.team(_householdId)),
        ];

        // Update the document
        await _databases.updateDocument(
          databaseId: _databaseId,
          collectionId: _inventoryCollectionId,
          documentId: doc.$id,
          data: data,
          permissions: teamPermissions,
        );
      }

      // 3. Update the inventory database if available
      if (_inventoryDb != null) {
        await _inventoryDb!.updateHouseholdIds(_householdId);
        Log.i('$tag: Updated inventory database with new household ID');
      }

      // 4. Update the item database permissions if available
      if (_itemDb != null) {
        await _itemDb!.updateHouseholdPermissions();
        Log.i('$tag: Updated item database permissions for new household');
      }

      Log.i('$tag: Successfully updated inventory household IDs to $_householdId');
    } catch (e) {
      Log.e('$tag: Failed to update inventory household IDs: $e');
      throw Exception('Failed to update inventory household IDs: $e');
    }
  }

  /// Copies all inventory items from the old household to the new household
  Future<void> _copyInventoryToNewHousehold(String oldHouseholdId, String newHouseholdId) async {
    if (!online) {
      throw Exception('Cannot copy inventory while offline.');
    }

    try {
      // 1. Get all inventory items for the current user in the old household
      final inventoryDocs = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _inventoryCollectionId,
        queries: [
          Query.equal('userId', userId),
          Query.equal('householdId', oldHouseholdId),
        ],
      );

      // 2. Copy each inventory item to the new household
      for (final doc in inventoryDocs.documents) {
        final Map<String, dynamic> data = doc.data;

        // Update the household ID
        data['householdId'] = newHouseholdId;

        // Add household team permissions for the new household
        final teamPermissions = [
          Permission.read(Role.team(newHouseholdId)),
          Permission.update(Role.team(newHouseholdId)),
        ];

        // Create a new document with the updated data
        await _databases.createDocument(
          databaseId: _databaseId,
          collectionId: _inventoryCollectionId,
          documentId: 'unique()',
          data: data,
          permissions: teamPermissions,
        );
      }

      Log.i('$tag: Successfully copied inventory from $oldHouseholdId to $newHouseholdId');
    } catch (e) {
      Log.e('$tag: Failed to copy inventory to new household: $e');
      throw Exception('Failed to copy inventory to new household: $e');
    }
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
