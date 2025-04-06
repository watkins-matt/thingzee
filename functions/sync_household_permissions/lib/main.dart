import 'dart:convert';
import 'dart:io';
import 'package:dart_appwrite/dart_appwrite.dart';

// This function syncs document permissions for all members of a household team
Future<dynamic> main(final context) async {
  try {
    // Log the event details
    context.log('Starting household permissions sync');
    
    // Initialize SDK
    final client = Client()..setEndpoint('https://cloud.appwrite.io/v1');
    
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
    client
      ..setProject(projectId)
      ..setKey(apiKey);
      
    context.log('Using project ID: $projectId');

    final teams = Teams(client);
    final databases = Databases(client);
    
    // Parse the teamId/householdId from the request payload
    Map<String, dynamic> payload;
    String teamId;
    
    if (context.req.body is String) {
      try {
        payload = jsonDecode(context.req.body as String);
        teamId = payload['teamId']?.toString() ?? '';
      } catch (e) {
        context.log('Error parsing payload: $e');
        return context.res.json({
          'success': false,
          'message': 'Error parsing payload: $e'
        }, 400);
      }
    } else if (context.req.body is Map<String, dynamic>) {
      payload = context.req.body as Map<String, dynamic>;
      teamId = payload['teamId']?.toString() ?? '';
    } else {
      // Try to get teamId from query parameters as fallback
      teamId = context.req.query['teamId'] ?? '';
      
      if (teamId.isEmpty) {
        return context.res.json({
          'success': false,
          'message': 'Missing required parameter: teamId'
        }, 400);
      }
    }
    
    context.log('Syncing permissions for team: $teamId');
    
    // Step 1: Get all team members
    final memberships = await teams.listMemberships(teamId: teamId);
    if (memberships.total == 0) {
      context.log('No members found in team: $teamId');
      return context.res.json({
        'success': false,
        'message': 'No members found in team'
      }, 404);
    }
    
    context.log('Found ${memberships.total} team members');
    
    // Extract all user IDs in this team
    final List<String> userIds = [];
    for (final membership in memberships.memberships) {
      userIds.add(membership.userId);
    }
    
    // Step 2: For each collection we care about, update document permissions
    final collectionsToSync = ['user_inventory', 'user_location', 'user_item', 'user_history'];
    // Database ID from environment or fallback to test
    final databaseId = Platform.environment['APPWRITE_DATABASE_ID'] ?? 'test';
    int totalDocuments = 0;
    
    for (final collectionName in collectionsToSync) {
      context.log('Processing collection: $collectionName');
      
      // Step 3: For each user, find their documents and update permissions
      for (final userId in userIds) {
        try {
          // Fetch documents belonging to this user - we can't query by permissions
          // so instead we'll use the userId field if available, or get all documents
          final documents = await databases.listDocuments(
            databaseId: databaseId,
            collectionId: collectionName,
            queries: [Query.equal('userId', userId)]
          );
          
          context.log('Found ${documents.total} $collectionName documents for user $userId');
          
          // For each document, update permissions to include team access
          for (final doc in documents.documents) {
            try {
              final docId = doc.$id;
              
              // Update the document with team permissions
              await databases.updateDocument(
                databaseId: databaseId,
                collectionId: collectionName,
                documentId: docId,
                permissions: [
                  Permission.read(Role.user(userId)),
                  Permission.update(Role.user(userId)),
                  Permission.delete(Role.user(userId)),
                  Permission.read(Role.team(teamId)),
                  Permission.update(Role.team(teamId))
                ]
              );
              totalDocuments++;
              context.log('Updated permissions for document $docId');
            } catch (docError) {
              context.log('Error updating document permissions: $docError');
              // Continue with next document
            }
          }
        } catch (userError) {
          context.log('Error processing user $userId: $userError');
          // Continue with next user
        }
      }
    }
    
    context.log('Completed syncing permissions for $totalDocuments documents in team $teamId');
    
    return context.res.json({
      'success': true,
      'message': 'Permissions synced for $totalDocuments documents in team $teamId',
      'totalDocuments': totalDocuments
    });
  } catch (e) {
    context.log('Error syncing household permissions: $e');
    return context.res.json({
      'success': false, 
      'message': e.toString()
    }, 500);
  }
}
