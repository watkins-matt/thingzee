import 'dart:convert';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'dart:io' show Platform;

// Main entry point for Appwrite function
Future<dynamic> main(final context) async {
  try {
    context.log('Starting household permissions sync');
    
    // Initialize services
    final client = initializeClient(context);
    final teams = Teams(client);
    final databases = Databases(client);
    
    // Get the teamId from the request
    final teamId = await getTeamIdFromRequest(context);
    if (teamId.isEmpty) {
      return context.res.json({
        'success': false,
        'message': 'Missing required parameter: teamId'
      }, 400);
    }
    
    context.log('Syncing permissions for team: $teamId');
    
    // Get all team members
    final userIds = await getTeamMembers(context, teams, teamId);
    if (userIds.isEmpty) {
      return context.res.json({
        'success': false,
        'message': 'No members found in team'
      }, 404);
    }
    
    // Sync permissions across collections
    final result = await syncPermissionsForCollections(
      context,
      databases,
      userIds,
      teamId
    );
    
    return context.res.json({
      'success': true,
      'message': 'Permissions synced for ${result.totalDocuments} documents in team $teamId',
      'totalDocuments': result.totalDocuments
    });
  } catch (e) {
    context.log('Error syncing household permissions: $e');
    return context.res.json({
      'success': false, 
      'message': e.toString()
    }, 500);
  }
}

// Initialize the Appwrite client
Client initializeClient(context) {
  // Get credentials from environment variables
  final projectId = Platform.environment['APPWRITE_FUNCTION_PROJECT_ID'];
  final apiKey = context.req.headers['x-appwrite-key'];
  
  if (projectId == null) {
    throw Exception('Project ID not found in environment variables');
  }
  
  if (apiKey == null) {
    throw Exception('API key not found in headers');
  }

  // Set up the client
  final client = Client()
    ..setEndpoint('https://cloud.appwrite.io/v1')
    ..setProject(projectId)
    ..setKey(apiKey);
    
  context.log('Using project ID: $projectId');
  return client;
}

// Extract the teamId from the request
Future<String> getTeamIdFromRequest(context) async {
  String teamId = '';
  
  if (context.req.body is String) {
    try {
      final payload = jsonDecode(context.req.body as String);
      teamId = payload['teamId']?.toString() ?? '';
    } catch (e) {
      context.log('Error parsing payload: $e');
      throw Exception('Error parsing payload: $e');
    }
  } else if (context.req.body is Map<String, dynamic>) {
    final payload = context.req.body as Map<String, dynamic>;
    teamId = payload['teamId']?.toString() ?? '';
  } else {
    // Try to get teamId from query parameters as fallback
    teamId = context.req.query['teamId'] ?? '';
  }
  
  return teamId;
}

// Get all team members
Future<List<String>> getTeamMembers(context, Teams teams, String teamId) async {
  final List<String> userIds = [];
  
  try {
    final memberships = await teams.listMemberships(teamId: teamId);
    
    if (memberships.total == 0) {
      context.log('No members found in team: $teamId');
      return [];
    }
    
    context.log('Found ${memberships.total} team members');
    
    for (final membership in memberships.memberships) {
      userIds.add(membership.userId);
    }
    
    return userIds;
  } catch (e) {
    context.log('Error fetching team members: $e');
    throw e;
  }
}

// Data class to hold result information
class SyncResult {
  final int totalDocuments;
  
  SyncResult(this.totalDocuments);
}

// Sync permissions across all relevant collections
Future<SyncResult> syncPermissionsForCollections(
  context,
  Databases databases,
  List<String> userIds,
  String teamId
) async {
  final collectionsToSync = ['user_inventory', 'user_location', 'user_item', 'user_history'];
  final databaseId = Platform.environment['APPWRITE_DATABASE_ID'] ?? 'test';
  int totalDocuments = 0;
  
  for (final collectionName in collectionsToSync) {
    context.log('Processing collection: $collectionName');
    
    for (final userId in userIds) {
      final docsUpdated = await syncUserDocuments(
        context,
        databases,
        databaseId,
        collectionName,
        userId,
        teamId
      );
      
      totalDocuments += docsUpdated;
    }
  }
  
  context.log('Completed syncing permissions for $totalDocuments documents in team $teamId');
  return SyncResult(totalDocuments);
}

// Sync permissions for a single user's documents in a collection
Future<int> syncUserDocuments(
  context,
  Databases databases,
  String databaseId,
  String collectionName,
  String userId,
  String teamId
) async {
  int updatedCount = 0;
  
  try {
    // Fetch documents belonging to this user
    final documents = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: collectionName,
      queries: [Query.equal('userId', userId)]
    );
    
    context.log('Found ${documents.total} $collectionName documents for user $userId');
    
    // Update permissions for each document
    for (final doc in documents.documents) {
      try {
        final docId = doc.$id;
        await updateDocumentPermissions(
          context,
          databases,
          databaseId,
          collectionName,
          docId,
          userId,
          teamId
        );
        
        updatedCount++;
      } catch (docError) {
        context.log('Error updating document permissions: $docError');
        // Continue with next document
      }
    }
    
    return updatedCount;
  } catch (userError) {
    context.log('Error processing user $userId: $userError');
    return 0; // Continue with next user
  }
}

// Update permissions for a single document
Future<void> updateDocumentPermissions(
  context,
  Databases databases,
  String databaseId,
  String collectionName,
  String documentId,
  String userId,
  String teamId
) async {
  await databases.updateDocument(
    databaseId: databaseId,
    collectionId: collectionName,
    documentId: documentId,
    permissions: [
      Permission.read(Role.user(userId)),
      Permission.update(Role.user(userId)),
      Permission.delete(Role.user(userId)),
      Permission.read(Role.team(teamId)),
      Permission.update(Role.team(teamId))
    ]
  );
  
  context.log('Updated permissions for document $documentId');
}
