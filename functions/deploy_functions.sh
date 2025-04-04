#!/bin/bash

# Exit on error
set -e

# Configuration
PROJECT_ID="thingzee"

API_KEY="${APPWRITE_KEY}"
if [ -z "${API_KEY}" ]; then
  echo "APPWRITE_KEY environment variable is empty or does not exist. Please set it with your Appwrite API key with Teams permission."
  exit 1
fi

echo "==== Deploying Thingzee Appwrite Functions ===="

# Deploy process_invitation function
echo "\n--- Deploying process_invitation function ---"
cd process_invitation

echo "Installing dependencies..."
npm i -g appwrite-cli
dart pub get

echo "Creating function..."
appwrite functions create \
  --functionId=process_invitation \
  --name="Process Invitation" \
  --runtime="dart-2.17" \
  --execute=["users"] \
  --events=["databases.*.collections.invitation.documents.update"] \
  || echo "Function already exists"

echo "Setting API key..."
appwrite functions createVariable \
  --functionId=process_invitation \
  --key=APPWRITE_API_KEY \
  --value="$API_KEY" \
  || echo "Variable might already exist"

echo "Deploying function..."
appwrite functions createDeployment \
  --functionId=process_invitation \
  --entrypoint="lib/main.dart" \
  --activate=true

echo "\n✅ Deployment complete!"
echo "Remember to update the API key in this script with your actual Appwrite API key."
echo "The API key requires Teams permission to manage team memberships."

cd ..

# Deploy manage_invitations function
echo "\n--- Deploying manage_invitations function ---"
cd manage_invitations

echo "Installing dependencies..."
dart pub get

echo "Creating function..."
appwrite functions create \
  --functionId=manage_invitations \
  --name="Manage Invitations" \
  --runtime="dart-2.17" \
  --execute=["users"] \
  --schedule="*/30 * * * *" \
  || echo "Function already exists"

echo "Setting API key..."
appwrite functions createVariable \
  --functionId=manage_invitations \
  --key=APPWRITE_API_KEY \
  --value="$API_KEY" \
  || echo "Variable might already exist"

echo "Deploying function..."
appwrite functions createDeployment \
  --functionId=manage_invitations \
  --entrypoint="lib/main.dart" \
  --activate=true

echo "\n✅ Deployment complete!"

cd ..

echo "\nAll functions deployed successfully."
