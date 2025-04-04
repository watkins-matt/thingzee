import 'package:dart_appwrite/models.dart' as models;
import 'package:dart_appwrite/dart_appwrite.dart';

/*
  'manage_invitations' - Manages permissions for invitations 
  
  This function runs on a schedule and ensures that invitation permissions 
  are correctly set so recipients can view invitations sent to their email.
*/
Future<dynamic> main(final context) async {
  try {
    // Get credentials from environment variables
    final String? apiKey = context.env['APPWRITE_API_KEY'];
    if (apiKey == null) {
      throw Exception('APPWRITE_API_KEY not set in environment variables');
    }
    
    context.log('Starting manage_invitations cloud function');

    // Initialize SDK with the updated structure for v14.0.0
    final client = Client()
      ..setEndpoint('https://cloud.appwrite.io/v1')
      ..setProject(context.env['APPWRITE_FUNCTION_PROJECT_ID'] as String)
      ..setKey(apiKey);

    // Initialize services
    final databases = Databases(client);
    final users = Users(client);
    
    // Get all pending invitations
    final invitationsResponse = await databases.listDocuments(
      databaseId: 'thingzee',  // Your database ID
      collectionId: 'invitation',  // Your collection ID
      queries: [Query.equal('status', 'pending')],
    );
    
    context.log('Found ${invitationsResponse.total} pending invitations');
    
    // Process each invitation to update permissions
    for (final document in invitationsResponse.documents) {
      final invitation = document.data;
      final recipientEmail = invitation['recipientEmail'];
      
      // Skip if no recipient email
      if (recipientEmail == null || recipientEmail.toString().isEmpty) {
        context.log('Skipping invitation ${document.$id}: No recipient email');
        continue;
      }
      
      try {
        // Try to find a user with this email
        final userList = await users.list(
          queries: [Query.equal('email', recipientEmail)],
        );
        
        // If we found a user with this email
        if (userList.total > 0) {
          final recipientUser = userList.users[0];
          
          // Check if user already has read permission
          bool hasRecipientReadPermission = false;
          final permissions = document.$permissions;
          
          for (final permission in permissions) {
            if (permission.contains('user:${recipientUser.$id}') && 
                permission.startsWith('read')) {
              hasRecipientReadPermission = true;
              break;
            }
          }
          
          if (!hasRecipientReadPermission) {
            context.log('Adding read permission for recipient ${recipientUser.$id} to invitation ${document.$id}');
            
            // Add read permission for recipient
            await databases.updateDocument(
              databaseId: 'thingzee',
              collectionId: 'invitation',
              documentId: document.$id,
              permissions: [
                ...permissions,
                Permission.read(Role.user(recipientUser.$id)),
              ],
            );
            
            context.log('Successfully added read permission for user ${recipientUser.$id}');
          } else {
            context.log('User ${recipientUser.$id} already has read permission for invitation ${document.$id}');
          }
        } else {
          context.log('No user found with email $recipientEmail, skipping permission update');
        }
      } catch (e) {
        context.log('Error processing invitation ${document.$id}: $e');
        continue;
      }
    }
    
    return context.res.json({
      'success': true, 
      'message': 'Invitation permissions updated successfully'
    });
    
  } catch (e) {
    context.log('Error in manage_invitations function: $e');
    return context.res.json({
      'success': false, 
      'message': e.toString()
    }, statusCode: 500);
  }
}
