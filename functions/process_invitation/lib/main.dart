import 'dart:convert';
import 'dart:io' show Platform;
import 'package:dart_appwrite/dart_appwrite.dart';

// Type definitions for records
typedef InvitationParseResult = ({bool success, Map<String, dynamic>? data, String message, int statusCode, bool isInvitationDoc});
typedef AppwriteServices = ({bool success, String message, Client? client, Teams? teams, Users? users, Functions? functions, Databases? databases});
typedef UserInfo = ({bool success, String message, String userId, String displayName, int statusCode});
typedef InvitationData = ({String recipientEmail, String teamId, String action, String inviterEmail, String documentId});

// Main entry point for Appwrite function
Future<dynamic> main(final context) async {
  try {
    context.log('Processing invitation event');
    
    // Parse the invitation data from the request
    final invitationResult = await parseInvitationFromRequest(context);
    if (!invitationResult.success) {
      return context.res.json({
        'success': false,
        'message': invitationResult.message
      }, invitationResult.statusCode);
    }
    
    // Skip if not an invitation document
    if (!invitationResult.isInvitationDoc) {
      context.log('Not an invitation document');
      return context.res.json({
        'success': true,
        'message': 'Event ignored: not an invitation document'
      });
    }
    
    final invitation = invitationResult.data!;
    final status = determineInvitationStatus(invitation, context);
    
    // Initialize the Appwrite client and services
    final services = await initializeAppwriteServices(context);
    if (!services.success) {
      return context.res.json({
        'success': false,
        'message': services.message
      }, 500);
    }
    
    // Extract common fields from invitation
    final fields = extractInvitationFields(invitation, context);
    context.log('Processing invitation - Status: $status, Recipient: ${fields.recipientEmail}, Team: ${fields.teamId}');
    
    // Process the invitation based on its status
    if (status == 0) {
      // Handle pending invitation
      return await handlePendingInvitation(context, services, invitation, fields);
    } else if (status == 1) {
      // Handle accepted invitation
      return await handleAcceptedInvitation(context, services, invitation, fields);
    } else if (status == 2) {
      // Handle declined invitation
      return await handleDeclinedInvitation(context, fields);
    } else if (status == 3 || fields.action == 'leave') {
      // Handle leave request
      return await handleLeaveHousehold(context, services, invitation, fields);
    } else {
      // Unknown status
      context.log('Unknown invitation status: $status');
      return context.res.json({
        'success': false,
        'message': 'Unknown invitation status: $status'
      }, 400);
    }
  } catch (e) {
    context.log('Unhandled error in process_invitation: $e');
    return context.res.json({
      'success': false,
      'message': 'Unhandled error: $e'
    }, 500);
  }
}

// Parse the invitation from the request
Future<InvitationParseResult> parseInvitationFromRequest(context) async {
  // Parse the event data from the payload
  Map<String, dynamic> invitation;

  // Handle different payload formats
  if (context.req.body is String) {
    try {
      invitation = jsonDecode(context.req.body as String);
    } catch (e) {
      context.log('Error parsing payload as string: $e');
      context.log('Raw payload: ${context.req.body}');
      return (
        success: false,
        data: null,
        message: 'Error parsing payload: $e',
        statusCode: 400,
        isInvitationDoc: false
      );
    }
  } else if (context.req.body is Map<String, dynamic>) {
    // The payload might be the document itself rather than an event wrapper
    invitation = context.req.body as Map<String, dynamic>;
  } else {
    context.log('Invalid payload type: ${context.req.body.runtimeType}');
    return (
      success: false,
      data: null,
      message: 'Invalid payload type: ${context.req.body.runtimeType}',
      statusCode: 400,
      isInvitationDoc: false
    );
  }
  
  // Log the entire payload for debugging
  context.log('Event payload: $invitation');
  
  // Check if this appears to be an invitation document
  bool isInvitationDoc = false;
  
  // Check if this is directly an invitation document (no event wrapper)
  if (invitation['\$collectionId'] == 'invitation') {
    isInvitationDoc = true;
    context.log('Direct document payload detected');
  }
  // For backward compatibility with event-wrapped payloads
  else if (invitation['\$event'] != null) {
    context.log('Event name: ${invitation["\$event"]}');
    if (invitation['\$event'].toString().contains('invitation')) {
      isInvitationDoc = true;
      // Extract the data from the event
      if (invitation['\$data'] is Map<String, dynamic>) {
        invitation = invitation['\$data'] as Map<String, dynamic>;
      }
    }
  }
  
  return (
    success: true,
    data: invitation,
    message: 'Successfully parsed invitation',
    isInvitationDoc: isInvitationDoc,
    statusCode: 200
  );
}

// Determine the invitation status
int determineInvitationStatus(Map<String, dynamic> invitation, context) {
  int status;
  if (invitation['status'] is int) {
    status = invitation['status'];
  } else {
    status = int.tryParse(invitation['status']?.toString() ?? '') ?? -1;
  }
  
  context.log('Invitation status: $status');
  return status;
}

// Initialize Appwrite services
Future<AppwriteServices> initializeAppwriteServices(context) async {
  try {
    // Initialize SDK
    final client = Client()..setEndpoint('https://cloud.appwrite.io/v1');
    
    // Get credentials from environment variables
    final projectId = Platform.environment['APPWRITE_FUNCTION_PROJECT_ID'];
    final apiKey = context.req.headers['x-appwrite-key'];
    
    if (projectId == null) {
      return (
        success: false,
        message: 'Project ID not found in environment variables',
        client: null,
        teams: null,
        users: null,
        functions: null,
        databases: null
      );
    }
    
    if (apiKey == null) {
      return (
        success: false,
        message: 'API key not found in headers',
        client: null,
        teams: null,
        users: null,
        functions: null,
        databases: null
      );
    }

    // Set up the client
    client
      ..setProject(projectId)
      ..setKey(apiKey);
      
    context.log('Using project ID: $projectId');

    final teams = Teams(client);
    final users = Users(client);
    final functions = Functions(client);
    final databases = Databases(client);
    
    return (
      success: true,
      message: 'Services initialized successfully',
      client: client,
      teams: teams,
      users: users,
      functions: functions,
      databases: databases
    );
  } catch (e) {
    context.log('Error initializing Appwrite services: $e');
    return (
      success: false,
      message: 'Error initializing Appwrite services: $e',
      client: null,
      teams: null,
      users: null,
      functions: null,
      databases: null
    );
  }
}

// Extract fields from invitation
InvitationData extractInvitationFields(Map<String, dynamic> invitation, context) {
  final recipientEmail = invitation['recipientEmail']?.toString() ?? '';
  final teamId = invitation['teamId']?.toString() ?? '';
  final action = invitation['action']?.toString() ?? '';
  final inviterEmail = invitation['inviterEmail']?.toString() ?? 'unknown';
  final documentId = invitation['\$id']?.toString() ?? '';
  
  context.log('Extracted fields - Recipient: $recipientEmail, Team: $teamId, Action: $action');
  
  return (
    recipientEmail: recipientEmail,
    teamId: teamId,
    action: action,
    inviterEmail: inviterEmail,
    documentId: documentId
  );
}

// Handle pending invitation
Future<dynamic> handlePendingInvitation(
  context,
  AppwriteServices services,
  Map<String, dynamic> invitation,
  InvitationData fields
) async {
  // Add permission for the recipient to view this invitation
  try {
    // Find the recipient user ID
    final recipientUserList = await services.users!.list(
      queries: [Query.equal('email', fields.recipientEmail)]
    );
    
    if (recipientUserList.total > 0) {
      final recipientUserId = recipientUserList.users[0].$id;
      
      // Update the invitation document with permission for the recipient
      await services.databases!.updateDocument(
        databaseId: 'test',
        collectionId: 'invitation',
        documentId: fields.documentId,
        permissions: [
          // Add permission for the recipient to read this invitation
          Permission.read(Role.user(recipientUserId))
        ]
      );
      
      context.log('Added read permission for recipient: ${fields.recipientEmail} (ID: $recipientUserId)');
    } else {
      context.log('Recipient user not found, cannot add permissions: ${fields.recipientEmail}');
    }
  } catch (e) {
    context.log('Error adding permission to invitation: $e');
    // Continue processing - this is not critical
  }
  
  return context.res.json({
    'success': true,
    'message': 'Processed pending invitation'
  });
}

// Handle accepted invitation
Future<dynamic> handleAcceptedInvitation(
  context,
  AppwriteServices services,
  Map<String, dynamic> invitation,
  InvitationData fields
) async {
  context.log('Processing accepted invitation from ${fields.recipientEmail} for inviter ${fields.inviterEmail}');
  
  // First, find the recipient and inviter users
  final recipientResult = await findUserByEmail(context, services.users!, fields.recipientEmail);
  if (!recipientResult.success) {
    return context.res.json({
      'success': false,
      'message': 'Recipient user not found: ${recipientResult.message}'
    }, recipientResult.statusCode);
  }
  
  final inviterResult = await findUserByEmail(context, services.users!, fields.inviterEmail);
  if (!inviterResult.success) {
    return context.res.json({
      'success': false,
      'message': 'Inviter user not found: ${inviterResult.message}'
    }, inviterResult.statusCode);
  }
  
  // SECURITY: Find matching pending invitation to validate this acceptance
  // We look for an invitation where the roles are reversed (original inviter sent to recipient)
  try {
    context.log('Looking for matching pending invitation');
    final pendingInvitations = await services.databases!.listDocuments(
      databaseId: 'test',
      collectionId: 'invitation',
      queries: [
        // The inviterEmail in the pending invitation should match recipientEmail in the accepted one
        Query.equal('inviterEmail', fields.inviterEmail),
        // The recipientEmail in the pending invitation should match inviterEmail in the accepted one
        Query.equal('recipientEmail', fields.recipientEmail),
        // Must be pending status
        Query.equal('status', 0) // 0 = pending
      ]
    );
    
    // If no matching invitation found, reject the acceptance
    if (pendingInvitations.total == 0) {
      context.log('No matching pending invitation found - SECURITY VIOLATION ATTEMPT');
      return context.res.json({
        'success': false,
        'message': 'No matching pending invitation found. Cannot accept an invitation that was not sent.'
      }, 403); // Forbidden
    }
    
    final pendingInvitation = pendingInvitations.documents[0];
    context.log('Matching pending invitation found: ${pendingInvitation.$id}');
    
    // Get the household ID from the pending invitation
    final householdId = pendingInvitation.data['householdId'];
    if (householdId == null || householdId.isEmpty) {
      return context.res.json({
        'success': false,
        'message': 'Invalid household ID in pending invitation'
      }, 400);
    }
    
    // Now handle team membership
    try {
      // Check if the team exists
      bool teamExists = true;
      try {
        await services.teams!.get(teamId: householdId);
        context.log('Team exists: $householdId');
      } catch (e) {
        teamExists = false;
        context.log('Team does not exist, will create it: $householdId');
      }
      
      // If team doesn't exist, create it and add the inviter
      if (!teamExists) {
        // Create the team
        await services.teams!.create(
          teamId: householdId,
          name: 'Household ${householdId.substring(0, 8)}',
        );
        context.log('Created team: $householdId');
        
        // Add the inviter to the team
        await services.teams!.createMembership(
          teamId: householdId,
          roles: ['member', 'admin'],  // Original inviter gets admin role
          userId: inviterResult.userId
        );
        context.log('Added inviter to team: ${inviterResult.userId} to team: $householdId');
        
        // Update inviter's household record
        await updateUserHouseholdRecord(
          context, 
          services.databases!, 
          inviterResult.userId, 
          inviterResult.displayName, 
          fields.inviterEmail, 
          householdId,
          isAdmin: true
        );
      }
      
      // Now add the accepting user to the team
      await services.teams!.createMembership(
        teamId: householdId,
        roles: ['member'],  // Accepting user gets regular member role
        userId: recipientResult.userId
      );
      
      context.log('Added accepting user to team: ${recipientResult.userId} to team: $householdId');
      
      // Update accepting user's household record
      await updateUserHouseholdRecord(
        context, 
        services.databases!, 
        recipientResult.userId, 
        recipientResult.displayName, 
        fields.recipientEmail, 
        householdId
      );
      
      // Trigger permission sync
      try {
        await services.functions!.createExecution(
          functionId: 'sync_household_permissions',
          body: jsonEncode({
            'teamId': householdId
          })
        );
        
        context.log('Permission sync initiated');
      } catch (e) {
        context.log('Error triggering permission sync: $e');
      }
      
      return context.res.json({
        'success': true,
        'message': 'User added to household team successfully',
        'householdId': householdId
      });
      
    } catch (e) {
      context.log('Error managing team membership: $e');
      return context.res.json({
        'success': false,
        'message': 'Error managing team membership: ${e.toString()}'
      }, 500);
    }
    
  } catch (e) {
    context.log('Error validating pending invitation: $e');
    return context.res.json({
      'success': false,
      'message': 'Error validating pending invitation: ${e.toString()}'
    }, 500);
  }
}

// Find a user by email
Future<UserInfo> findUserByEmail(context, Users users, String email) async {
  try {
    final userList = await users.list(
      queries: [Query.equal('email', email)]
    );
    
    if (userList.total > 0) {
      return (
        success: true,
        message: 'User found',
        userId: userList.users[0].$id,
        displayName: userList.users[0].name,
        statusCode: 200
      );
    } else {
      context.log('User not found: $email');
      return (
        success: false,
        message: 'User not found',
        userId: '',
        displayName: '',
        statusCode: 404
      );
    }
  } catch (e) {
    context.log('Error finding user: $e');
    return (
      success: false,
      message: 'Error finding user: ${e.toString()}',
      userId: '',
      displayName: '',
      statusCode: 500
    );
  }
}

// Update or create a user_household record
Future<void> updateUserHouseholdRecord(
  context,
  Databases databases,
  String userId,
  String displayName,
  String email,
  String householdId,
  {bool isAdmin = false}
) async {
  try {
    // Check if user already has a household record
    final userDocs = await databases.listDocuments(
      databaseId: 'test',
      collectionId: 'user_household',
      queries: [Query.equal('userId', userId)],
    );
    
    if (userDocs.total > 0) {
      // Update existing record
      final documentId = userDocs.documents[0].$id;
      
      await databases.updateDocument(
        databaseId: 'test',
        collectionId: 'user_household',
        documentId: documentId,
        data: {
          'householdId': householdId,
          'isAdmin': isAdmin,
          'timestamp': DateTime.now().millisecondsSinceEpoch
        }
      );
      
      context.log('Updated user_household record');
    } else {
      // Create new record
      await databases.createDocument(
        databaseId: 'test',
        collectionId: 'user_household',
        documentId: userId,
        data: {
          'userId': userId,
          'name': displayName,
          'email': email,
          'householdId': householdId,
          'isAdmin': isAdmin,
          'timestamp': DateTime.now().millisecondsSinceEpoch
        }
      );
      
      context.log('Created user_household record');
    }
  } catch (e) {
    context.log('Error updating user_household record: $e');
  }
}

// Handle declined invitation
Future<dynamic> handleDeclinedInvitation(context, InvitationData fields) async {
  context.log('Invitation declined by: ${fields.recipientEmail}');
  
  return context.res.json({
    'success': true,
    'message': 'Invitation declined'
  });
}

// Handle leave household request
Future<dynamic> handleLeaveHousehold(
  context,
  AppwriteServices services,
  Map<String, dynamic> invitation,
  InvitationData fields
) async {
  if (fields.teamId.isEmpty) {
    return context.res.json({
      'success': false,
      'message': 'Team ID is required for leave operations'
    }, 400);
  }
  
  // Find the user by email
  final userResult = await findUserByEmail(context, services.users!, fields.recipientEmail);
  if (!userResult.success) {
    return context.res.json({
      'success': false,
      'message': userResult.message
    }, userResult.statusCode);
  }
  
  // Remove the user from the team
  try {
    // Get the membership to find the membership ID
    final memberships = await services.teams!.listMemberships(
      teamId: fields.teamId,
      queries: [Query.equal('userId', userResult.userId)]
    );
    
    if (memberships.total > 0) {
      final membershipId = memberships.memberships[0].$id;
      
      // Delete the membership
      await services.teams!.deleteMembership(
        teamId: fields.teamId,
        membershipId: membershipId
      );
      
      context.log('Removed user from team: ${userResult.userId} from team: ${fields.teamId}');
      
      // Update the user_household record to reflect the change
      try {
        final userDocs = await services.databases!.listDocuments(
          databaseId: 'test',
          collectionId: 'user_household',
          queries: [Query.equal('userId', userResult.userId)],
        );
        
        if (userDocs.total > 0) {
          final documentId = userDocs.documents[0].$id;
          
          // Update to clear the householdId
          await services.databases!.updateDocument(
            databaseId: 'test',
            collectionId: 'user_household',
            documentId: documentId,
            data: {
              'householdId': '',
              'timestamp': DateTime.now().millisecondsSinceEpoch
            }
          );
          
          context.log('Updated user_household record to clear householdId');
        }
      } catch (e) {
        context.log('Error updating user_household record: $e');
      }
      
      return context.res.json({
        'success': true,
        'message': 'User removed from household successfully'
      });
    } else {
      context.log('No membership found for user: ${userResult.userId} in team: ${fields.teamId}');
      return context.res.json({
        'success': true,
        'message': 'User was not a member of the household'
      });
    }
  } catch (e) {
    context.log('Error removing user from team: $e');
    return context.res.json({
      'success': false,
      'message': 'Error removing user from team: ${e.toString()}'
    }, 500);
  }
}
