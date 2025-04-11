import 'dart:convert';
import 'dart:io' show Platform;
import 'package:dart_appwrite/dart_appwrite.dart';

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

// Result class for invitation parsing
class InvitationParseResult {
  final bool success;
  final Map<String, dynamic>? data;
  final String message;
  final int statusCode;
  final bool isInvitationDoc;
  
  InvitationParseResult({
    required this.success,
    this.data,
    required this.message,
    this.statusCode = 200,
    this.isInvitationDoc = false,
  });
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
      return InvitationParseResult(
        success: false,
        message: 'Error parsing payload: $e',
        statusCode: 400,
      );
    }
  } else if (context.req.body is Map<String, dynamic>) {
    // The payload might be the document itself rather than an event wrapper
    invitation = context.req.body as Map<String, dynamic>;
  } else {
    context.log('Invalid payload type: ${context.req.body.runtimeType}');
    return InvitationParseResult(
      success: false,
      message: 'Invalid payload type: ${context.req.body.runtimeType}',
      statusCode: 400,
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
  
  return InvitationParseResult(
    success: true,
    data: invitation,
    message: 'Successfully parsed invitation',
    isInvitationDoc: isInvitationDoc,
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

// Services result class
class AppwriteServicesResult {
  final bool success;
  final String message;
  final Client? client;
  final Teams? teams;
  final Users? users;
  final Functions? functions;
  final Databases? databases;
  
  AppwriteServicesResult({
    required this.success,
    required this.message,
    this.client,
    this.teams,
    this.users,
    this.functions,
    this.databases,
  });
}

// Initialize Appwrite services
Future<AppwriteServicesResult> initializeAppwriteServices(context) async {
  try {
    // Initialize SDK
    final client = Client()..setEndpoint('https://cloud.appwrite.io/v1');
    
    // Get credentials from environment variables
    final projectId = Platform.environment['APPWRITE_FUNCTION_PROJECT_ID'];
    final apiKey = context.req.headers['x-appwrite-key'];
    
    if (projectId == null) {
      return AppwriteServicesResult(
        success: false,
        message: 'Project ID not found in environment variables',
      );
    }
    
    if (apiKey == null) {
      return AppwriteServicesResult(
        success: false,
        message: 'API key not found in headers',
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
    
    return AppwriteServicesResult(
      success: true,
      message: 'Services initialized successfully',
      client: client,
      teams: teams,
      users: users,
      functions: functions,
      databases: databases,
    );
  } catch (e) {
    context.log('Error initializing Appwrite services: $e');
    return AppwriteServicesResult(
      success: false,
      message: 'Error initializing Appwrite services: $e',
    );
  }
}

// Invitation fields class
class InvitationFields {
  final String recipientEmail;
  final String teamId;
  final String action;
  final String inviterEmail;
  final String documentId;
  
  InvitationFields({
    required this.recipientEmail,
    required this.teamId,
    required this.action,
    required this.inviterEmail,
    required this.documentId,
  });
}

// Extract fields from invitation
InvitationFields extractInvitationFields(Map<String, dynamic> invitation, context) {
  final recipientEmail = invitation['recipientEmail']?.toString() ?? '';
  final teamId = invitation['teamId']?.toString() ?? '';
  final action = invitation['action']?.toString() ?? '';
  final inviterEmail = invitation['inviterEmail']?.toString() ?? 'unknown';
  final documentId = invitation['\$id']?.toString() ?? '';
  
  context.log('Extracted fields - Recipient: $recipientEmail, Team: $teamId, Action: $action');
  
  return InvitationFields(
    recipientEmail: recipientEmail,
    teamId: teamId,
    action: action,
    inviterEmail: inviterEmail,
    documentId: documentId,
  );
}

// Handle pending invitation
Future<dynamic> handlePendingInvitation(
  context,
  AppwriteServicesResult services,
  Map<String, dynamic> invitation,
  InvitationFields fields
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
  AppwriteServicesResult services,
  Map<String, dynamic> invitation,
  InvitationFields fields
) async {
  // Validation
  if (fields.teamId.isEmpty) {
    return context.res.json({
      'success': false,
      'message': 'Team ID is required for accepted invitations'
    }, 400);
  }
  
  // Find the recipient user
  final userResult = await findUserByEmail(context, services.users!, fields.recipientEmail);
  if (!userResult.success) {
    return context.res.json({
      'success': false,
      'message': userResult.message
    }, userResult.statusCode);
  }
  
  // Add the user to the team
  try {
    await services.teams!.createMembership(
      teamId: fields.teamId,
      roles: ['member'],
      userId: userResult.userId
    );
    
    context.log('Added user to team: ${userResult.userId} to team: ${fields.teamId}');
    
    // Update or create user_household record
    await updateUserHouseholdRecord(
      context, 
      services.databases!, 
      userResult.userId, 
      userResult.displayName, 
      fields.recipientEmail, 
      fields.teamId
    );
    
  } catch (e) {
    context.log('Error adding user to team: $e');
    return context.res.json({
      'success': false,
      'message': 'Error adding user to team: ${e.toString()}'
    }, 500);
  }
  
  // Trigger permission sync
  try {
    await services.functions!.createExecution(
      functionId: 'sync_household_permissions',
      body: jsonEncode({
        'teamId': fields.teamId
      })
    );
    
    context.log('Permission sync initiated');
  } catch (e) {
    context.log('Error triggering permission sync: $e');
  }
  
  return context.res.json({
    'success': true,
    'message': 'User added to household team successfully',
    'householdId': fields.teamId
  });
}

// User result class
class UserResult {
  final bool success;
  final String message;
  final String userId;
  final String displayName;
  final int statusCode;
  
  UserResult({
    required this.success,
    required this.message,
    this.userId = '',
    this.displayName = '',
    this.statusCode = 200,
  });
}

// Find a user by email
Future<UserResult> findUserByEmail(context, Users users, String email) async {
  try {
    final userList = await users.list(
      queries: [Query.equal('email', email)]
    );
    
    if (userList.total > 0) {
      return UserResult(
        success: true,
        message: 'User found',
        userId: userList.users[0].$id,
        displayName: userList.users[0].name,
      );
    } else {
      context.log('User not found: $email');
      return UserResult(
        success: false,
        message: 'User not found',
        statusCode: 404,
      );
    }
  } catch (e) {
    context.log('Error finding user: $e');
    return UserResult(
      success: false,
      message: 'Error finding user: ${e.toString()}',
      statusCode: 500,
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
  String householdId
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
          'isAdmin': false,
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
Future<dynamic> handleDeclinedInvitation(context, InvitationFields fields) async {
  context.log('Invitation declined by: ${fields.recipientEmail}');
  
  return context.res.json({
    'success': true,
    'message': 'Invitation declined'
  });
}

// Handle leave household request
Future<dynamic> handleLeaveHousehold(
  context,
  AppwriteServicesResult services,
  Map<String, dynamic> invitation,
  InvitationFields fields
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
