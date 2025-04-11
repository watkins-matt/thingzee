import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:log/log.dart';
import 'package:repository/database/household_database.dart';
import 'package:repository/database/preferences.dart' as app_prefs;
import 'package:repository/model/household_member.dart';
import 'package:repository_appw/database/inventory_db.dart';
import 'package:repository_appw/database/item_db.dart';
import 'package:repository_appw/util/appwrite_database.dart';
import 'package:repository_appw/util/synchronizable.dart';
import 'package:uuid/uuid.dart';

class AppwriteHouseholdDatabase extends HouseholdDatabase
    with
        AppwriteSynchronizable<HouseholdMember>,
        AppwriteDatabase<HouseholdMember> {
  final Account _account;
  final Client client;
  late Databases _databases;
  final app_prefs.Preferences prefs;
  AppwriteInventoryDatabase? _inventoryDb;

  String _databaseId = 'test';
  final String _inventoryCollectionId = 'user_inventory';
  DateTime _created = DateTime.now();
  String _householdId = '';
  bool _initializing = false;
  bool _initialized = false;
  Completer<void>? _initCompleter;

  // Tag for logging
  String tag = 'AppwriteHouseholdDatabase';

  AppwriteHouseholdDatabase(this.prefs, this._account,
      {required String endpoint})
      : client = Client(),
        super() {
    client.setEndpoint(endpoint);
    client.setProject('thingzee');
    _databases = Databases(client);

    // Set database and collection IDs
    _databaseId = 'test';
    const String householdCollectionId = 'user_household';

    // Set specific tag for this database
    tag = 'AppwriteHouseholdDatabase';

    // Check for migration from preferences - TEMPORARY during transition
    // This will be removed in a future version once all users have migrated
    final prefsHouseholdId = prefs.getString('household_id');
    if (prefsHouseholdId != null && prefsHouseholdId.isNotEmpty) {
      Log.i(
          '$tag: Found legacy household ID in preferences: $prefsHouseholdId - will use for migration');
      _householdId = prefsHouseholdId;
    }

    // Initialize created timestamp (will be overwritten if we find a record)
    _created = DateTime.fromMillisecondsSinceEpoch(
        prefs.getInt('household_created') ??
            DateTime.now().millisecondsSinceEpoch);

    // Initialize AppwriteDatabase mixin
    constructDatabase(tag, _databases, _databaseId, householdCollectionId);

    // Initialize AppwriteSynchronizable mixin
    constructSynchronizable(tag, prefs,
        onConnectivityChange: connectivityChanged);
  }

  @override
  String get id => _householdId;

  @override
  DateTime get created => _created;

  @override
  List<HouseholdMember> get admins => super
      .all()
      .where(
          (element) => element.isAdmin && element.householdId == _householdId)
      .toList();

  @override
  HouseholdMember? deserialize(Map<String, dynamic> json) {
    try {
      return HouseholdMember.fromJson(json);
    } catch (e) {
      Log.e('$tag: Failed to deserialize household member', e);
      return null;
    }
  }

  @override
  List<HouseholdMember> all() {
    // Queue fetching team members if we're online
    if (online) {
      taskQueue.queueTask(() async {
        final members = await fetchTeamMembers();
        for (final member in members) {
          super.put(member);
        }
      });
    }
    return super.all();
  }

  Future<void> connectivityChanged(bool online) async {
    if (online) {
      await initialize();
      await taskQueue.runUntilComplete();
    }
  }

  /// Initializes household ID from the database
  ///
  /// This method should be called early in the app lifecycle to ensure
  /// the household ID is loaded from the database before it's needed.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    // If initialization is already in progress, wait for it to complete
    if (_initializing && _initCompleter != null) {
      try {
        return await _initCompleter!.future;
      } catch (e) {
        Log.e('$tag: Error waiting for initialization to complete', e);
      }
    }

    // Ensure we have a fresh completer
    _initializing = true;
    _initCompleter = Completer<void>();

    try {
      Log.i('$tag: Initializing household ID from database');

      if (!online) {
        // If offline, we'll use the current ID (or generate one if empty)
        if (_householdId.isEmpty) {
          _householdId = const Uuid().v4();
          Log.i(
              '$tag: Generated new household ID while offline: $_householdId');
        }
        _initialized = true;
        return;
      }

      // Try to get the user's record from the database
      try {
        final userDocs = await _databases.listDocuments(
          databaseId: _databaseId,
          collectionId: collectionId,
          queries: [Query.equal('userId', userId)],
        );

        if (userDocs.total > 0) {
          // User has a record in the database
          final userDoc = userDocs.documents[0];
          final dbHouseholdId = userDoc.data['householdId'] as String? ?? '';

          if (dbHouseholdId.isNotEmpty) {
            if (_householdId.isEmpty || _householdId != dbHouseholdId) {
              Log.i('$tag: Loaded household ID from database: $dbHouseholdId');
              _householdId = dbHouseholdId;
            }
          } else if (_householdId.isNotEmpty) {
            // Database record exists but has empty householdId, update it with our ID
            Log.i(
                '$tag: Updating empty household ID in database record with: $_householdId');
            await _databases.updateDocument(
              databaseId: _databaseId,
              collectionId: collectionId,
              documentId: userDoc.$id,
              data: {'householdId': _householdId},
            );
          }
        } else if (_householdId.isEmpty) {
          // No user record exists and we don't have an ID, create a new household
          await _createNewHousehold();
        } else {
          // No user record exists but we have an ID from preferences, create record
          Log.i(
              '$tag: Creating user_household record with ID from preferences: $_householdId');
          await _createUserHouseholdRecord();
        }
      } catch (e) {
        Log.e('$tag: Error loading household ID from database', e);
        if (_householdId.isEmpty) {
          // If we still don't have a household ID, generate one
          _householdId = const Uuid().v4();
          Log.i('$tag: Generated new household ID after error: $_householdId');
        }
      }

      // Remove from preferences since we no longer need it
      if (prefs.containsKey('household_id')) {
        await prefs.remove('household_id');
        Log.i('$tag: Removed household ID from preferences');
      }

      _initialized = true;
    } catch (e) {
      Log.e('$tag: Error during household initialization', e);
      // Make sure the completer completes with an error so clients can handle it
      if (!_initCompleter!.isCompleted) {
        _initCompleter!.completeError(e);
      }
      rethrow;
    } finally {
      _initializing = false;
      // Make sure we only complete if not already completed
      if (!_initCompleter!.isCompleted) {
        _initCompleter!.complete();
      }
    }
  }

  void setInventoryDatabase(AppwriteInventoryDatabase inventoryDb) {
    _inventoryDb = inventoryDb;
  }

  void setItemDatabase(AppwriteItemDatabase itemDb) {
    // Removed unused _itemDb field
  }

  /// Debug method to log the current household ID and team memberships
  Future<void> logHouseholdInfo() async {
    Log.i('$tag: ============ HOUSEHOLD DIAGNOSTICS ============');
    Log.i('$tag: Current household ID: $_householdId');
    Log.i('$tag: User ID: $userId');

    // Check if we have any legacy settings in preferences
    final prefsHouseholdId = prefs.getString('household_id') ?? '';
    if (prefs.containsKey('household_id')) {
      Log.i(
          '$tag: LEGACY: Household ID in preferences: $prefsHouseholdId (should be removed)');
    }

    try {
      // Log database records for debugging
      final allDocs = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: collectionId,
      );

      Log.i('$tag: Found ${allDocs.total} user_household records:');
      for (var i = 0; i < allDocs.documents.length; i++) {
        final doc = allDocs.documents[i];
        final data = doc.data;
        Log.i('$tag: Record $i - userId: ${data['userId']}, '
            'householdId: ${data['householdId']}, '
            'email: ${data['email']}');
      }
    } catch (e) {
      Log.e('$tag: Error in logHouseholdInfo', e);
    }
  }

  /// Get all household members from the database
  ///
  /// This method replaces the previous implementation that relied on Teams API.
  /// Now we only fetch from the database, which is the single source of truth.
  Future<List<HouseholdMember>> fetchTeamMembers() async {
    try {
      Log.i(
          '$tag: Fetching household members from database for household: $_householdId');

      if (_householdId.isEmpty) {
        Log.w('$tag: Cannot fetch members - no household ID set');
        return [];
      }

      // Only fetch from database, do not interact with Teams API directly
      final memberDocs = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: collectionId,
        queries: [Query.equal('householdId', _householdId)],
      );

      Log.i('$tag: Found ${memberDocs.total} members in household database');

      final members = <HouseholdMember>[];
      for (final doc in memberDocs.documents) {
        try {
          final member = deserialize(doc.data);
          if (member != null) {
            members.add(member);
            Log.i('$tag: Added member: ${member.name} (${member.email})');
          }
        } catch (e) {
          Log.e('$tag: Error deserializing member document ${doc.$id}', e);
        }
      }

      Log.i('$tag: Fetched ${members.length} household members');
      return members;
    } catch (e) {
      Log.e('$tag: Error fetching household members', e);
      return [];
    }
  }

  /// Join a household by updating the database record
  ///
  /// This method creates a self-invitation to join the household and sets the status to 'accepted'.
  /// The process_invitation function will handle team membership updates.
  @override
  Future<void> join(String householdId) async {
    Log.i('$tag: Joining household: $householdId');

    if (householdId == _householdId) {
      Log.i('$tag: Already a member of this household, nothing to do');
      return;
    }

    if (!online) {
      throw Exception('Cannot join a household while offline');
    }

    try {
      // Store the old household ID for potential data migration
      final oldHouseholdId = _householdId;

      // Update the household ID in memory
      _householdId = householdId;

      // Update the user record in the database with the new household ID
      await _updateUserHouseholdRecord();

      // Update all inventory items with the new household ID
      await updateInventoryHouseholdIds();

      // If we came from a different household, handle item copying
      if (oldHouseholdId.isNotEmpty && oldHouseholdId != householdId) {
        try {
          Log.i(
              '$tag: Copying inventory items from old household: $oldHouseholdId to new: $householdId');
          await _copyInventoryToNewHousehold(oldHouseholdId, householdId);
        } catch (e) {
          Log.e('$tag: Failed to copy inventory items from old household', e);
          // Don't throw here, just log the error and continue
        }
      }

      // Create a self-invitation with status 'accepted' to trigger the process_invitation function
      try {
        // Get user information
        final user = await _account.get();
        final email = user.email;
        String userName = email.contains('@') ? email.split('@').first : email;

        // Create the invitation document with accepted status
        await _databases.createDocument(
            databaseId: _databaseId,
            collectionId: 'invitation',
            documentId: ID.unique(),
            data: {
              'inviterEmail': email,
              'inviterName': userName,
              'recipientEmail': email, // Self-invitation
              'status': 1, // 1 = accepted
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'teamId': householdId // The household/team to join
            });

        Log.i(
            '$tag: Created self-invitation with accepted status to trigger team update');
      } catch (e) {
        Log.e('$tag: Failed to create invitation for team update', e);
        // Continue anyway, as the database is the source of truth
      }

      Log.i('$tag: Successfully joined household: $_householdId');
    } catch (e) {
      Log.e('$tag: Failed to join household', e);
      throw Exception('Failed to join household: $e');
    }
  }

  /// Leave the current household by updating the database
  ///
  /// This method creates a special invitation with 'leave' type to trigger
  /// the process_invitation function to remove the user from the team.
  @override
  void leave() {
    if (!online) {
      throw Exception('Cannot leave household while offline.');
    }

    try {
      Log.i('$tag: Leaving current household: $_householdId');
      final oldHouseholdId = _householdId;

      // Create a new household ID
      _householdId = const Uuid().v4();
      _created = DateTime.now();

      // Update database record with new household ID
      taskQueue.queueTask(() async {
        await _updateUserHouseholdRecord();
      });

      // Copy inventory items to the new household if needed
      taskQueue.queueTask(() async {
        if (oldHouseholdId.isNotEmpty) {
          try {
            await _copyInventoryToNewHousehold(oldHouseholdId, _householdId);
          } catch (e) {
            Log.e('$tag: Failed to copy inventory to new household', e);
          }
        }
      });

      // Update inventory items to have the new household ID
      taskQueue.queueTask(() async {
        await updateInventoryHouseholdIds();
      });

      // Create a 'leave' invitation to trigger the team membership update
      taskQueue.queueTask(() async {
        try {
          // Get user information
          final user = await _account.get();
          final email = user.email;

          // Create the invitation document with special 'leave' type
          await _databases.createDocument(
              databaseId: _databaseId,
              collectionId: 'invitation',
              documentId: ID.unique(),
              data: {
                'inviterEmail': email,
                'recipientEmail': email, // Self-invitation
                'status': 3, // 3 = leave (custom status)
                'timestamp': DateTime.now().millisecondsSinceEpoch,
                'teamId': oldHouseholdId, // The household/team to leave
                'action': 'leave' // Explicit action type
              });

          Log.i(
              '$tag: Created leave invitation to trigger team membership removal');
        } catch (e) {
          Log.e('$tag: Failed to create leave invitation', e);
        }
      });

      Log.i(
          '$tag: Successfully left household and created new household: $_householdId');
    } catch (e) {
      Log.e('$tag: Failed to leave household', e);
      throw Exception('Failed to leave household: $e');
    }
  }

  /// Creates a new user_household record for the current user
  Future<void> _createUserHouseholdRecord() async {
    if (!online || userId.isEmpty) {
      throw Exception(
          'Cannot create user record while offline or without userId');
    }

    try {
      // Get user info from the account
      final user = await _account.get();
      final email = user.email;

      // Create simple name from email
      String userName = email.contains('@') ? email.split('@').first : email;

      // Create a record in the user_household collection
      await _databases.createDocument(
          databaseId: _databaseId,
          collectionId: collectionId,
          documentId: userId,
          data: {
            'userId': userId,
            'name': userName,
            'email': email,
            'householdId': _householdId,
            'isAdmin': true, // First user is admin by default
            'timestamp': DateTime.now().millisecondsSinceEpoch
          });

      Log.i(
          '$tag: Created new user_household record with householdId $_householdId');
    } catch (e) {
      Log.e('$tag: Error creating user_household record', e);
      throw Exception('Failed to create user record: $e');
    }
  }

  /// Updates the current user's household record with the current household ID
  Future<void> _updateUserHouseholdRecord() async {
    if (!online || userId.isEmpty) {
      throw Exception(
          'Cannot update user record while offline or without userId');
    }

    try {
      // Check if the user has a record in the user_household collection
      final userDocs = await _databases.listDocuments(
          databaseId: _databaseId,
          collectionId: collectionId,
          queries: [Query.equal('userId', userId)]);

      if (userDocs.total > 0) {
        // Update existing record with current householdId
        final userDoc = userDocs.documents[0];
        await _databases.updateDocument(
            databaseId: _databaseId,
            collectionId: collectionId,
            documentId: userDoc.$id,
            data: {'householdId': _householdId});
        Log.i(
            '$tag: Updated existing user_household record with current householdId');
      } else {
        // Create a new record if none exists
        await _createUserHouseholdRecord();
      }
    } catch (e) {
      Log.e('$tag: Error updating user_household record', e);
      throw Exception('Failed to update user record: $e');
    }
  }

  @override
  Future<void> updateInventoryHouseholdIds() async {
    if (_inventoryDb == null) {
      Log.w(
          '$tag: Cannot update inventory household IDs - inventory database not set');
      return;
    }

    if (!online) {
      Log.w('$tag: Cannot update inventory household IDs while offline');
      return;
    }

    try {
      // Get all inventory items for the user
      final inventoryDocs = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _inventoryCollectionId,
        queries: [Query.equal('userId', userId)],
      );

      // Update all documents to have the current household ID
      for (final doc in inventoryDocs.documents) {
        await _databases.updateDocument(
          databaseId: _databaseId,
          collectionId: _inventoryCollectionId,
          documentId: doc.$id,
          data: {
            'householdId': _householdId,
          },
        );
      }

      Log.i(
          '$tag: Updated ${inventoryDocs.documents.length} inventory items with new household ID: $_householdId');
    } catch (e) {
      Log.e('$tag: Failed to update inventory household IDs', e);
      throw Exception('Failed to update inventory household IDs: $e');
    }
  }

  Future<void> _createNewHousehold() async {
    _householdId = const Uuid().v4();
    _created = DateTime.now();

    try {
      await _databases.createDocument(
          databaseId: _databaseId,
          collectionId: collectionId,
          documentId: userId,
          data: {
            'userId': userId,
            'householdId': _householdId,
            'timestamp': DateTime.now().millisecondsSinceEpoch
          });
      Log.i('$tag: Created new household record with ID: $_householdId');
    } catch (e) {
      Log.e('$tag: Failed to create new household', e);
      rethrow;
    }
  }

  Future<void> _copyInventoryToNewHousehold(
      String oldHouseholdId, String newHouseholdId) async {
    if (!online) {
      throw Exception('Cannot copy inventory while offline.');
    }

    if (oldHouseholdId == newHouseholdId) {
      Log.w(
          '$tag: Old and new household IDs are the same, not copying inventory.');
      return;
    }

    try {
      // Get all inventory items for the old household
      final oldInventoryDocs = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _inventoryCollectionId,
        queries: [
          Query.equal('householdId', oldHouseholdId),
          Query.notEqual('userId', userId),
        ],
      );

      // Copy each document to the new household
      for (final doc in oldInventoryDocs.documents) {
        final data = Map<String, dynamic>.from(doc.data);
        data['householdId'] = newHouseholdId;
        data['timestamp'] = DateTime.now().millisecondsSinceEpoch;

        // Create a new document with the same data but new household ID
        await _databases.createDocument(
          databaseId: _databaseId,
          collectionId: _inventoryCollectionId,
          documentId: ID.unique(),
          data: data,
        );
      }

      Log.i(
          '$tag: Copied ${oldInventoryDocs.documents.length} inventory items from old household to new household');
    } catch (e) {
      Log.e('$tag: Failed to copy inventory to new household', e);
      throw Exception('Failed to copy inventory: $e');
    }
  }

  /// Gets all household members from all households in the database
  /// This is useful for diagnostics and resolving synchronization issues
  Future<List<HouseholdMember>> getAllHouseholdMembers() async {
    try {
      Log.i('$tag: Fetching all household members from database');

      if (!online) {
        Log.w('$tag: Cannot fetch all household members while offline');
        return [];
      }

      final allDocs = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: collectionId,
      );

      final members = <HouseholdMember>[];
      for (final doc in allDocs.documents) {
        try {
          final member = deserialize(doc.data);
          if (member != null) {
            members.add(member);
          }
        } catch (e) {
          Log.e('$tag: Error deserializing member document ${doc.$id}', e);
        }
      }

      Log.i(
          '$tag: Fetched ${members.length} total household members from database');
      return members;
    } catch (e) {
      Log.e('$tag: Error fetching all household members', e);
      return [];
    }
  }
}
