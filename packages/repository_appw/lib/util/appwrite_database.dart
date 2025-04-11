import 'dart:async';
import 'dart:collection';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' hide Log, Preferences, Model;
import 'package:log/log.dart';
import 'package:repository/database/database.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:repository/util/hash.dart';
import 'package:repository_appw/util/appwrite_task_queue.dart';
import 'package:util/extension/date_time.dart';

mixin AppwriteDatabase<T extends Model> on Database<T> {
  static final Set<String> _invalidTeamIds = {};
  AppwriteTaskQueue taskQueue = AppwriteTaskQueue();
  late final Databases _database;
  late final String collectionId;
  late final String databaseId;
  late final String _tag;
  final Map<String, T> _items = <String, T>{};
  String get userId;

  Iterable<T> get values => UnmodifiableListView(_items.values);

  @override
  List<T> all() => _items.values.toList();

  void constructDatabase(
      String tag, Databases database, String databaseId, String collectionId) {
    _database = database;
    _tag = tag;
    this.databaseId = databaseId;
    this.collectionId = collectionId;
  }

  @override
  void delete(T item) {
    String id = item.uniqueKey;
    _items.remove(id);
    taskQueue.queueTask(() async {
      await _database.deleteDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: uniqueDocumentId(id),
      );
    });

    replicateOperation((replica) async {
      replica.delete(item);
    });

    callHooks(item, DatabaseHookType.delete);
  }

  @override
  void deleteAll() {
    for (final id in _items.keys.toList()) {
      deleteById(id);
    }
    _items.clear();

    replicateOperation((replica) async {
      replica.deleteAll();
    });

    callHooks(null, DatabaseHookType.deleteAll);
  }

  @override
  void deleteById(String id) {
    final item = _items.remove(id);
    taskQueue.queueTask(() async {
      await _database.deleteDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: uniqueDocumentId(id),
      );
    });

    replicateOperation((replica) async {
      replica.deleteById(id);
    });

    if (item != null) {
      callHooks(item, DatabaseHookType.delete);
    }
  }

  T? deserialize(Map<String, dynamic> json);

  List<T> documentsToList(DocumentList documentList) {
    return documentList.documents
        .map((doc) {
          try {
            T? result = deserialize(doc.data);

            if (result != null) {
              final created = DateTime.parse(doc.data['\$createdAt']);
              final updated = DateTime.parse(doc.data['\$updatedAt']);

              // Note that we also use the oldest updated field because
              // one may have initialized to the default of DateTime.now()
              result = result.copyWith(
                  created: result.created.older(created),
                  updated: result.updated.older(updated));
            }

            return result;
          } catch (e) {
            Log.e('$_tag: Failed to deserialize: ${doc.data}', e.toString());
            return null;
          }
        })
        .where((item) => item != null)
        .cast<T>()
        .toList();
  }

  @override
  T? get(String id) => _items[id];

  @override
  List<T> getAll(List<String> ids) {
    return ids
        .map((id) => _items[id])
        .where((element) => element != null)
        .cast<T>()
        .toList();
  }

  @override
  List<T> getChanges(DateTime since) {
    return values.where((item) => item.updated.isAfter(since)).toList();
  }

  Future<DocumentList> getDocuments(List<String> queries) async {
    return await _database.listDocuments(
      databaseId: databaseId,
      collectionId: collectionId,
      queries: queries,
    );
  }

  Future<DocumentList> getModifiedDocuments(DateTime? lastSyncTime) async {
    return await _database.listDocuments(
      databaseId: databaseId,
      collectionId: collectionId,
      queries: [
        Query.greaterThan('updated', lastSyncTime?.millisecondsSinceEpoch ?? 0)
      ],
    );
  }

  bool isItemValid(T item) {
    String key = item.uniqueKey;
    return key.isNotEmpty;
  }

  @override
  Map<String, T> map() => Map.unmodifiable(_items);

  void mergeState(List<T> newItems) {
    for (final newItem in newItems) {
      String id = newItem.uniqueKey;
      final existingItem = _items[id];
      if (existingItem != null) {
        final mergedItem = existingItem.merge(newItem);
        _items[id] = mergedItem;
      } else {
        _items[id] = newItem;
      }
    }
  }

  @override
  void put(T item, {List<String>? permissions}) {
    String key = item.uniqueKey;

    // If the item is not valid, throw an exception
    if (!isItemValid(item)) {
      throw Exception('$_tag: Item $key is not valid.');
    }

    _items[key] = item;

    taskQueue.queueTask(() async {
      // Check if permissions contain team permissions for an invalid team ID
      // If so, strip them out and replace with user permissions
      List<String>? effectivePermissions = permissions;
      
      if (permissions != null && hasInvalidTeamPermissions(permissions)) {
        // Create user-only permissions as replacement
        effectivePermissions = [
          Permission.read(Role.user(userId)),
          Permission.update(Role.user(userId)),
          Permission.delete(Role.user(userId)),
        ];
        Log.i('$_tag: Proactively using user-only permissions for item $key (team is invalid).');
      }

      // Try to update or create the document with the effective permissions
      await _putDocumentWithPermissions(key, item, effectivePermissions)
          .catchError((error) async {
        if (error is AppwriteException &&
            error.message?.contains('Permissions must be one of') == true) {
          // Team likely doesn't exist anymore - extract team ID from permissions
          extractAndMarkInvalidTeams(permissions);
          
          // Log warning about team permissions error
          Log.w('$_tag: Team permissions error. Falling back to user-only permissions.');
          
          // Create user-only permissions as fallback
          final fallbackPermissions = [
            Permission.read(Role.user(userId)),
            Permission.update(Role.user(userId)),
            Permission.delete(Role.user(userId)),
          ];
          
          // Try again with user-only permissions
          await _putDocumentWithPermissions(key, item, fallbackPermissions);
          Log.i('$_tag: Successfully saved item $key with fallback permissions.');
        } else {
          // For other errors, rethrow
          throw error;
        }
      });
    });

    replicateOperation((replica) async {
      replica.put(item);
    });

    callHooks(item, DatabaseHookType.put);
  }

  // Helper method to put a document with specified permissions
  Future<void> _putDocumentWithPermissions(String key, T item, List<String>? permissions) async {
    try {
      await _database.updateDocument(
          databaseId: databaseId,
          collectionId: collectionId,
          documentId: uniqueDocumentId(key),
          data: serialize(item),
          permissions: permissions);
    } on AppwriteException catch (e) {
      if (e.code == 404) {
        try {
          await _database.createDocument(
              databaseId: databaseId,
              collectionId: collectionId,
              documentId: uniqueDocumentId(key),
              data: serialize(item),
              permissions: permissions);
        } on AppwriteException catch (createError) {
          // Handle schema mismatch errors with improved messages
          if (_isSchemaError(createError)) {
            final errorMessage =
                _getEnhancedSchemaErrorMessage(createError, item);
            Log.e('$_tag: Schema mismatch for item $key: $errorMessage');
            _items.remove(key);
            throw Exception(errorMessage);
          }
          rethrow;
        }
      } else if (e.code == 409) {
        try {
          await _database.updateDocument(
              databaseId: databaseId,
              collectionId: collectionId,
              documentId: uniqueDocumentId(key),
              data: serialize(item),
              permissions: permissions);
        } on AppwriteException catch (updateError) {
          // Handle schema mismatch errors with improved messages
          if (_isSchemaError(updateError)) {
            final errorMessage =
                _getEnhancedSchemaErrorMessage(updateError, item);
            Log.e('$_tag: Schema mismatch for item $key: $errorMessage');
            _items.remove(key);
            throw Exception(errorMessage);
          }
          rethrow;
        }
      } else {
        // Handle schema mismatch errors with improved messages
        if (_isSchemaError(e)) {
          final errorMessage = _getEnhancedSchemaErrorMessage(e, item);
          Log.e('$_tag: Schema mismatch for item $key: $errorMessage');
          _items.remove(key);
          throw Exception(errorMessage);
        } else {
          Log.e('$_tag: Failed to put item $key: [AppwriteException]',
              e.message);
          // Removing the item from local cache since we
          // failed to add it to the database
          _items.remove(key);
          rethrow;
        }
      }
    }
  }

  // Helper method to check if an Appwrite exception is related to schema validation
  bool _isSchemaError(AppwriteException e) {
    final message = e.message ?? '';
    return message.contains('Invalid document structure');
  }

  // Helper method to extract schema error information from the error message
  Map<String, String> _extractSchemaErrorInfo(String errorMessage) {
    final Map<String, String> result = {};
    
    // Check for missing required attribute
    final missingRegex = RegExp(r'Missing required attribute "([^"]+)"');
    final missingMatch = missingRegex.firstMatch(errorMessage);
    if (missingMatch != null) {
      result['type'] = 'missing';
      result['attribute'] = missingMatch.group(1) ?? '';
      return result;
    }
    
    // Check for unknown attribute
    final unknownRegex = RegExp(r'Unknown attribute: "([^"]+)"');
    final unknownMatch = unknownRegex.firstMatch(errorMessage);
    if (unknownMatch != null) {
      result['type'] = 'unknown';
      result['attribute'] = unknownMatch.group(1) ?? '';
      return result;
    }
    
    // Default
    result['type'] = 'other';
    result['attribute'] = '';
    return result;
  }

  // Helper method to generate enhanced error message for schema mismatches
  String _getEnhancedSchemaErrorMessage(AppwriteException e, T item) {
    final errorInfo = _extractSchemaErrorInfo(e.message ?? '');
    final modelType = item.runtimeType.toString();
    
    String errorTitle;
    String problemDescription;
    List<String> solutions = [];
    
    if (errorInfo['type'] == 'missing') {
      // Missing required attribute
      final missingAttribute = errorInfo['attribute'] ?? '';
      errorTitle = 'MISSING FIELD ERROR';
      problemDescription = 'The Appwrite database schema requires a field that doesn\'t exist in your Dart model.';
      solutions = [
        '1. Update the database schema in Appwrite to make "$missingAttribute" optional',
        '2. Add the missing "$missingAttribute" field to your $modelType class',
        '3. Map between your model and database schema in your serialize method for $modelType'
      ];
    } else if (errorInfo['type'] == 'unknown') {
      // Unknown attribute
      final unknownAttribute = errorInfo['attribute'] ?? '';
      errorTitle = 'UNKNOWN FIELD ERROR';
      problemDescription = 'Your Dart model contains a field that is not defined in the Appwrite database schema.';
      solutions = [
        '1. Update the Appwrite database schema to include the "$unknownAttribute" field',
        '2. Remove the "$unknownAttribute" field from your serialize method for $modelType',
        '3. Filter out unknown fields before sending to Appwrite in your serialize method'
      ];
    } else {
      // Other schema error
      errorTitle = 'SCHEMA MISMATCH ERROR';
      problemDescription = 'There is a mismatch between your Dart model and the Appwrite database schema.';
      solutions = [
        '1. Check that all fields in your model match the database schema',
        '2. Update either the database schema or your model to ensure compatibility',
        '3. Modify your serialize/deserialize methods to handle the differences'
      ];
    }

    final attribute = errorInfo['attribute'] ?? '';
    return '''DATABASE $errorTitle

Model: $modelType
Collection: $collectionId
Database: $databaseId
Field: "$attribute"

Problem: $problemDescription

Options to fix:
${solutions.join('\n')}

Check collection: $collectionId in database: $databaseId
''';
  }

  void replaceState(List<T> allItems) {
    _items.clear();
    for (final item in allItems) {
      String key = item.uniqueKey;
      _items[key] = item;
    }
  }

  Map<String, dynamic> serialize(T item) => item.toJson();

  String uniqueDocumentId(String id) {
    if (userId.isEmpty) {
      throw Exception(
          '$_tag: User ID is empty, cannot generate unique document ID.');
    }

    return hashUsernameBarcode(userId, id);
  }

  // Check if permissions contain references to invalid team IDs
  bool hasInvalidTeamPermissions(List<String> permissions) {
    for (final permission in permissions) {
      if (permission.contains('team:')) {
        // Extract team ID from the permission string
        final teamIdMatch = RegExp(r'team:([^/]+)').firstMatch(permission);
        if (teamIdMatch != null) {
          final teamId = teamIdMatch.group(1);
          if (teamId != null && _invalidTeamIds.contains(teamId)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  // Extract team IDs from permissions and mark them as invalid
  void extractAndMarkInvalidTeams(List<String>? permissions) {
    if (permissions == null) return;
    
    for (final permission in permissions) {
      if (permission.contains('team:')) {
        // Extract team ID from the permission string
        final teamIdMatch = RegExp(r'team:([^/]+)').firstMatch(permission);
        if (teamIdMatch != null) {
          final teamId = teamIdMatch.group(1);
          if (teamId != null && !_invalidTeamIds.contains(teamId)) {
            _invalidTeamIds.add(teamId);
            Log.w('$_tag: Marked team ID "$teamId" as invalid');
          }
        }
      }
    }
  }
}
