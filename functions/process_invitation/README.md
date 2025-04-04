# Process Invitation Function

This Appwrite function handles invitation acceptance and declining for the Thingzee household system. It securely processes team membership through the Appwrite backend rather than in the mobile app.

## Deployment Instructions

### Prerequisites
- Appwrite CLI installed (`npm install -g appwrite-cli`)
- Appwrite account with a project set up

### Steps

1. **Login to Appwrite CLI**
   ```
   appwrite login
   ```

2. **Initialize the function (if not already done)**
   ```
   cd functions/process_invitation
   appwrite init function
   ```

3. **Configure the function**
   When prompted:
   - Runtime: Dart (2.17 or higher)
   - Name: Process Invitation
   - Permissions: Add "any" for all authenticated users to execute
   - Activate: Yes

4. **Set environment variables**
   ```
   appwrite functions createVariable \
     --functionId=[YOUR_FUNCTION_ID] \
     --key=APPWRITE_API_KEY \
     --value=[YOUR_API_KEY_WITH_TEAMS_PERMISSION]
   ```

5. **Deploy the function**
   ```
   appwrite functions createDeployment \
     --functionId=[YOUR_FUNCTION_ID] \
     --activate=true
   ```

## Function Details

### Input Payload
```json
{
  "invitationId": "[INVITATION_DOCUMENT_ID]",
  "action": "accept" | "decline"
}
```

### Response
```json
{
  "success": true,
  "message": "Invitation accepted successfully",
  "householdId": "[HOUSEHOLD_ID]" // Only for accept action
}
```

### Error Response
```json
{
  "success": false,
  "message": "[ERROR_MESSAGE]"
}
```

## Implementation Notes
- The function securely handles team membership on the backend
- Handles edge cases like users already being team members
- Updates invitation status in the database
