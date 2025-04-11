# Household Architecture

The household system in Thingzee enables users to share inventory items and collaborate with family members or roommates. This document explains the architecture, components, and workflows of the household system.

## Table of Contents

- [Overview](#overview)
- [Core Components](#core-components)
  - [Data Models](#data-models)
  - [Database Layer](#database-layer)
  - [State Management](#state-management)
  - [Cloud Functions](#cloud-functions)
- [Implementation Details](#implementation-details)
  - [Household Initialization](#household-initialization)
  - [Joining a Household](#joining-a-household)
  - [Leaving a Household](#leaving-a-household)
  - [Team Membership Management](#team-membership-management)
  - [Household Permissions](#household-permissions)
- [Synchronization](#synchronization)
- [Diagnostics](#diagnostics)

## Overview

The household system uses Appwrite Teams as its foundation, where each household is represented as a Team. The system manages membership, permissions, and ensures that inventory items can be shared across household members. It maintains a single source of truth for household IDs in the database, with careful management of the relationship between users and households.

## Core Components

### Data Models

#### HouseholdMember

The `HouseholdMember` class represents a user who belongs to a household. Key properties include:

- `userId`: Unique identifier for the user
- `householdId`: Identifier linking the user to a household (matches Appwrite Team ID)
- `name`: User's display name
- `email`: User's email address
- `isAdmin`: Boolean indicating if the user has administrative privileges

The model uses the `@Mergeable` annotation, allowing it to be synchronized between local storage and the cloud database.

### Database Layer

#### HouseholdDatabase (Abstract)

The base abstract class that defines the contract for household data operations:

```dart
abstract class HouseholdDatabase extends Database<HouseholdMember> {
  List<HouseholdMember> get admins;
  DateTime get created;
  String get id;

  Future<void> join(String householdId);
  void leave();
  Future<void> updateInventoryHouseholdIds();
}
```

#### AppwriteHouseholdDatabase

The concrete implementation of `HouseholdDatabase` that interfaces with Appwrite's backend services. This class manages:

1. **Household ID Management**: Maintains the household ID as a single source of truth in the database
2. **Team Membership**: Handles Appwrite Teams API for managing household memberships
3. **Synchronization**: Manages online/offline synchronization of household data
4. **Inventory Consistency**: Ensures inventory items maintain the correct household ID

The class combines two mixins:
- `AppwriteSynchronizable`: Provides synchronization capabilities
- `AppwriteDatabase`: Provides database operations for Appwrite

### State Management

#### HouseholdState

Manages the application state for household data using Riverpod, providing methods to:

1. Add members to a household
2. Remove members from a household
3. Leave a household
4. Refresh the member list from both Teams API and database records

A Riverpod provider makes this state available throughout the application:

```dart
final householdProvider =
    StateNotifierProvider<HouseholdState, List<HouseholdMember>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return HouseholdState(repo);
});
```

### Cloud Functions

The system uses several Appwrite Cloud Functions to handle backend operations:

#### process_invitation

Triggered when an invitation status changes. It handles:
- Processing accepted invitations
- Adding users to household teams
- Creating user_household records
- Triggering permission synchronization

#### sync_household_permissions

Synchronizes document permissions across all household members to ensure:
- Team members can access each other's inventory items
- Permissions are properly set on all relevant collections
- Documents have the correct read/write permissions for the team

## Implementation Details

### Household Initialization

The household ID initialization follows these steps:

1. Check if a household ID exists in memory
2. If empty, look for a household ID in the database record for the current user
3. If still empty, generate a new unique ID
4. Update the user's record in the database with the current household ID
5. Create a corresponding Team in Appwrite if needed

Code flow for initialization:

```dart
Future<void> initialize() async {
  // Check if already initialized
  if (_initialized || _initializing) { return; }
  
  _initializing = true;
  
  // Try to get household ID from database
  final userDocs = await _databases.listDocuments(
    databaseId: _databaseId,
    collectionId: collectionId,
    queries: [Query.equal('userId', userId)],
  );
  
  if (userDocs.total > 0) {
    // User has a record in the database
    _householdId = userDoc.data['householdId'] as String? ?? '';
  }
  
  // Generate a new ID if needed
  if (_householdId.isEmpty) {
    _householdId = const Uuid().v4();
  }
  
  // Update or create user record in database
  await _updateUserHouseholdRecord();
  
  _initialized = true;
}
```

### Joining a Household

When a user joins a household:

1. The application updates the user's household ID
2. The user is added to the corresponding Appwrite Team
3. A user_household record is created or updated
4. Inventory items are updated to match the new household ID
5. Permission synchronization is triggered

### Leaving a Household

When a user leaves a household:

1. A new household ID is generated for the user
2. Inventory items are copied to the new household
3. The user is removed from the old household's Team
4. A new Team is created for the user's new household
5. The user's database record is updated with the new household ID

### Team Membership Management

The system manages Appwrite Team memberships through cloud functions:

1. **Team Creation**: Automatically creates a new Team when a new household is created
2. **Member Addition**: Adds users to Teams when they join a household
3. **Member Removal**: Removes users from Teams when they leave a household
4. **Invitation Processing**: Handles invitation acceptance and adds users to Teams

### Household Permissions

Document permissions are synchronized to ensure household members can access shared resources:

1. Each inventory item has permissions for both the individual user and the household team
2. When a user joins a household, permissions are synchronized for all members
3. The `sync_household_permissions` cloud function ensures consistency across documents

Collections with synchronized permissions include:
- `user_inventory`
- `user_location`
- `user_item`
- `user_history`

## Synchronization

The household system implements synchronization to handle offline and online operations:

1. **Offline Support**: Users can view household data while offline through local caching
2. **Connectivity Detection**: Automatically syncs when connection is restored
3. **Task Queue**: Operations are queued when offline and processed when online

The `AppwriteSynchronizable` mixin provides:
- Connection state tracking
- Task queue management
- Seamless online/offline transitions

## Diagnostics

The system includes diagnostic tools to help troubleshoot household synchronization issues:

1. **Household Information Logging**: `logHouseholdInfo()` method provides detailed diagnostic information
2. **Consistency Checks**: Methods to verify database and team membership consistency
3. **UI Diagnostics**: The household page includes a diagnostic button for user-triggered diagnostics

Example diagnostic output:

```
Household ID: b2d7f5bc-b25c-4f30-bed9-2d924006df36
User ID: 6e8b74fc-7a35-4841-9c7a-d3f0b43292e5
Team Members: [user1@example.com, user2@example.com]
Database Members: [user1@example.com, user2@example.com, user3@example.com]
```

This information is valuable for diagnosing issues with household membership synchronization and permission problems.
