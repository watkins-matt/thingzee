import 'package:dart_appwrite/dart_appwrite.dart';

// This function is triggered by database events when an invitation status changes
Future<dynamic> main(final context) async {
  try {
    // Log the event details
    context.log('Processing invitation event');
    
    // The function is triggered by database events
    // Parse the event data from the payload
    final Map<String, dynamic> payload = context.req.body;
    context.log('Event payload: $payload');
    
    // Check if this is a database event for invitation collection
    if (payload['\$event'] != 'databases.documents.update') {
      context.log('Not a document update event, ignoring');
      return context.res.json({
        'success': true,
        'message': 'Event ignored: not a document update'
      });
    }
    
    // Extract the invitation data from the event
    final invitation = payload['\$data'];
    if (invitation == null || invitation['collectionId'] != 'invitation') {
      context.log('Not an invitation document, ignoring');
      return context.res.json({
        'success': true,
        'message': 'Event ignored: not an invitation document'
      });
    }
    
    // Only process if status changed to 'accepted'
    if (invitation['status'] != 'accepted') {
      context.log('Status is not "accepted", ignoring');
      return context.res.json({
        'success': true,
        'message': 'Event ignored: status is not accepted'
      });
    }
    
    // Initialize SDK
    final client = Client()
      ..setEndpoint('https://cloud.appwrite.io/v1')
      ..setProject(context.env['APPWRITE_FUNCTION_PROJECT_ID'] as String)
      ..setKey(context.env['APPWRITE_API_KEY'] as String);

    final teams = Teams(client);
    
    try {
      // Add user to the team (household)
      await teams.createMembership(
        teamId: invitation['householdId'],
        email: invitation['recipientEmail'],
        roles: ['member'],
        url: 'https://thingzee.net', // redirect URL after accepting
      );
      
      context.log('Successfully added user to team ${invitation['householdId']}');
      
      return context.res.json({
        'success': true,
        'message': 'User added to household team successfully',
        'householdId': invitation['householdId']
      });
    } catch (e) {
      // Handle case where user is already a member of the team
      if (e is AppwriteException && e.code == 409) {
        context.log('User is already a member of the team, continuing');
        return context.res.json({
          'success': true,
          'message': 'User is already a member of this household',
          'householdId': invitation['householdId']
        });
      } else {
        // Rethrow other errors
        context.log('Error adding user to team: $e');
        rethrow;
      }
    }
  } catch (e) {
    context.log('Error processing invitation event: $e');
    return context.res.json({
      'success': false, 
      'message': e.toString()
    }, statusCode: 500);
  }
}
