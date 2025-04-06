import 'dart:convert';
import 'dart:io';
import 'package:dart_appwrite/dart_appwrite.dart';

// This function is triggered by database events when an invitation status changes
Future<dynamic> main(final context) async {
  try {
    // Log the event details
    context.log('Processing invitation event');
    
    // Parse the event data from the payload
    Map<String, dynamic> invitation;

    // Handle different payload formats
    if (context.req.body is String) {
      try {
        invitation = jsonDecode(context.req.body as String);
      } catch (e) {
        context.log('Error parsing payload as string: $e');
        context.log('Raw payload: ${context.req.body}');
        return context.res.json({
          'success': false,
          'message': 'Error parsing payload: $e'
        }, 400);
      }
    } else if (context.req.body is Map<String, dynamic>) {
      // The payload might be the document itself rather than an event wrapper
      invitation = context.req.body as Map<String, dynamic>;
    } else {
      context.log('Invalid payload type: ${context.req.body.runtimeType}');
      return context.res.json({
        'success': false,
        'message': 'Invalid payload type: ${context.req.body.runtimeType}'
      }, 400);
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
    
    if (!isInvitationDoc) {
      context.log('Not an invitation document');
      return context.res.json({
        'success': true,
        'message': 'Event ignored: not an invitation document'
      });
    }
    
    // Process the invitation status
    int status;
    if (invitation['status'] is int) {
      status = invitation['status'];
    } else {
      status = int.tryParse(invitation['status']?.toString() ?? '') ?? -1;
    }
    
    context.log('Invitation status: $status');
    
    // Only process if status is 'accepted' (status=1)
    // Status is integer type in the database: 0=pending, 1=accepted, 2=declined
    if (status != 1) {
      context.log('Status is not accepted (1), ignoring.');
      return context.res.json({
        'success': true,
        'message': 'Event ignored: status is not accepted'
      });
    }
    
    // Initialize SDK
    final client = Client()..setEndpoint('https://cloud.appwrite.io/v1');
    
    // Get credentials from environment variables - direct approach
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
    final users = Users(client);
    final functions = Functions(client);
    
    try {
      // Extract fields with null checks and type conversion for safety
      final recipientEmail = invitation['recipientEmail']?.toString() ?? '';
      final inviterEmail = invitation['inviterEmail']?.toString() ?? '';
      final inviterUserId = invitation['inviterUserId']?.toString() ?? '';
      
      // Log the invitation details for debugging
      context.log('Processing invitation: inviter=$inviterEmail, recipient=$recipientEmail, inviterUserId=$inviterUserId');
      
      // Validate required fields
      if (recipientEmail.isEmpty || inviterEmail.isEmpty) {
        throw Exception('Missing required fields: recipientEmail or inviterEmail');
      }
      
      // Step 1: Get user IDs from emails
      context.log('Looking up user IDs from emails');
      
      // Find recipient user
      final recipientList = await users.list(
        queries: [Query.equal('email', recipientEmail)]
      );
      
      if (recipientList.total == 0) {
        throw Exception('Recipient user not found: $recipientEmail');
      }
      final recipientUser = recipientList.users[0];
      context.log('Found recipient user with ID: ${recipientUser.$id}');
      
      // Find inviter user
      final inviterList = await users.list(
        queries: [Query.equal('email', inviterEmail)]
      );
      
      if (inviterList.total == 0) {
        throw Exception('Inviter user not found: $inviterEmail');
      }
      final inviterUser = inviterList.users[0];
      context.log('Found inviter user with ID: ${inviterUser.$id}');
      
      // Step 2: Try to find an existing team or create a new one
      context.log('Finding or creating team for users');
      String teamId = ''; // Initialize to empty string
      bool teamIdAssigned = false;
      
      try {
        // We'll need to list all teams and check if the inviter is a member of any
        final teamsList = await teams.list();
        
        // Flag to track if we found a team
        bool foundTeam = false;
        
        // Loop through teams to check memberships
        if (teamsList.total > 0) {
          context.log('Found ${teamsList.total} teams, checking memberships');
          
          // Check each team for the inviter's membership
          for (final team in teamsList.teams) {
            try {
              // Try to get membership of the inviter in this team
              final memberships = await teams.listMemberships(
                teamId: team.$id,
                queries: [Query.equal('userId', inviterUser.$id)]
              );
              
              if (memberships.total > 0) {
                // Found a team the inviter is a member of
                teamId = team.$id;
                foundTeam = true;
                teamIdAssigned = true;
                context.log('Found existing team for inviter: $teamId');
                break;
              }
            } catch (e) {
              context.log('Error checking team ${team.$id}: $e');
              // Continue to next team
            }
          }
        }
        
        if (!foundTeam) {
          // No team found, create a new one using the inviter's user ID
          context.log('No team found for inviter, creating new team');
          final newTeamId = inviterUserId.isNotEmpty ? inviterUserId : inviterUser.$id;
          
          final newTeam = await teams.create(
            teamId: newTeamId,
            name: 'Household $newTeamId',
          );
          teamId = newTeam.$id;
          teamIdAssigned = true;
          context.log('Created new team with ID: $teamId');
          
          // Make sure inviter is a member of the new team
          try {
            await teams.createMembership(
              teamId: teamId,
              email: inviterEmail,
              roles: ['owner', 'member'],
              url: 'https://cloud.appwrite.io/v1',
            );
            context.log('Added inviter to new team: $inviterEmail');
          } catch (membershipError) {
            if (membershipError is AppwriteException && membershipError.code == 409) {
              context.log('Inviter is already a member of the team');
            } else {
              context.log('Error adding inviter to team: $membershipError');
            }
          }
        }
      } catch (e) {
        // Error finding teams, check if it's because the team already exists
        context.log('Error finding teams: $e');
        bool teamCreated = false;
        
        // Check if this is a 'team already exists' error
        if (e is AppwriteException && e.code == 409) {
          final newTeamId = inviterUserId.isNotEmpty ? inviterUserId : inviterUser.$id;
          context.log('Team with ID $newTeamId already exists, trying to use it');
          
          try {
            // Try to get the existing team
            final team = await teams.get(teamId: newTeamId);
            teamId = team.$id;
            teamCreated = true;
            teamIdAssigned = true;
            context.log('Successfully retrieved existing team: $teamId');
            
            // Try to add inviter to this team if not already a member
            try {
              // Check if inviter is already a member
              final memberships = await teams.listMemberships(
                teamId: teamId,
                queries: [Query.equal('userId', inviterUser.$id)]
              );
              
              if (memberships.total == 0) {
                // Inviter not in team yet, add them
                await teams.createMembership(
                  teamId: teamId,
                  email: inviterEmail,
                  roles: ['owner', 'member'],
                  url: 'https://cloud.appwrite.io/v1',
                );
                context.log('Added inviter to existing team');
              } else {
                context.log('Inviter already member of team');
              }
            } catch (membershipError) {
              // Log but continue since we still want to add the recipient
              context.log('Error checking/adding inviter membership: $membershipError');
            }
          } catch (teamError) {
            context.log('Error retrieving existing team: $teamError');
            throw Exception('Failed to retrieve or create team: $teamError');
          }
        } else {
          // Different error - try generating a unique team ID instead
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final uniqueId = 'team-$timestamp';
          context.log('Creating team with unique ID: $uniqueId');
          
          try {
            final newTeam = await teams.create(
              teamId: uniqueId,
              name: 'Household $uniqueId',
            );
            teamId = newTeam.$id;
            teamCreated = true;
            teamIdAssigned = true;
            context.log('Created team with unique ID: $teamId');
            
            // Add inviter to this team
            await teams.createMembership(
              teamId: teamId,
              email: inviterEmail,
              roles: ['owner', 'member'],
              url: 'https://cloud.appwrite.io/v1',
            );
            context.log('Added inviter to new team with unique ID');
          } catch (createError) {
            context.log('Error creating team with unique ID: $createError');
            throw Exception('Failed to create team with unique ID: $createError');
          }
        }
        
        if (!teamIdAssigned && !teamCreated) {
          throw Exception('Team ID not assigned');
        }
        
        // Make sure we use the teamId from either the normal flow or the error handler
        if (!teamIdAssigned && teamCreated) {
          teamIdAssigned = true;
        }
      }
      
      // Debug log to verify team ID before adding recipient
      context.log('Team ID before adding recipient: $teamId');
      
      if (!teamIdAssigned) {
        throw Exception('Team ID not assigned, cannot add recipient');
      }
      
      // Step 3: Add recipient to the team
      try {
        context.log('Adding recipient to team: $teamId');
        await teams.createMembership(
          teamId: teamId,
          email: recipientEmail,
          roles: ['member'],
          url: 'https://cloud.appwrite.io/v1', // redirect URL after accepting
        );
        context.log('Successfully added recipient to team');
        
        // Step 4: Call the sync_household_permissions function to update document permissions
        context.log('Syncing household permissions for team: $teamId');
        try {
          // Call the sync_household_permissions function
          final syncResponse = await functions.createExecution(
            functionId: 'sync_household_permissions',
            body: jsonEncode({
              'teamId': teamId
            })
          );
          
          context.log('Permission sync initiated: ${syncResponse.status}');
        } catch (syncError) {
          // Log error but don't fail the overall process
          context.log('Error calling sync_household_permissions: $syncError');
          context.log('Household team membership was successful, but permission sync failed');
        }
        
        return context.res.json({
          'success': true,
          'message': 'User added to household team successfully',
          'householdId': teamId
        });
      } catch (e) {
        if (e is AppwriteException && e.code == 409) {
          context.log('Recipient is already a member of the team, continuing');
          
          // Still call the sync function for permissions
          try {
            await functions.createExecution(
              functionId: 'sync_household_permissions',
              body: jsonEncode({
                'teamId': teamId
              })
            );
            context.log('Permission sync initiated for existing team member');
          } catch (syncError) {
            context.log('Error calling sync_household_permissions: $syncError');
          }
          
          return context.res.json({
            'success': true,
            'message': 'User already member of household team',
            'householdId': teamId
          });
        } else {
          context.log('Error adding recipient to team: $e');
          throw e;
        }
      }
    } catch (e) {
      context.log('Error processing invitation event: $e');
      return context.res.json({
        'success': false, 
        'message': e.toString()
      }, 500);
    }
  } catch (e) {
    context.log('Error processing invitation event: $e');
    return context.res.json({
      'success': false, 
      'message': e.toString()
    }, 500);
  }
}
