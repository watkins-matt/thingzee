import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:log/log.dart';
import 'package:repository/model/household_member.dart';
import 'package:repository/model/invitation.dart';
import 'package:repository_appw/database/household_db.dart';
import 'package:thingzee/main.dart';
import 'package:thingzee/pages/detail/widget/material_card_widget.dart';
import 'package:thingzee/pages/detail/widget/title_header_widget.dart';
import 'package:thingzee/pages/household/state/household_state.dart';
import 'package:thingzee/pages/household/state/invitation_state.dart';
import 'package:thingzee/pages/household/widget/add_member_dialog.dart';

class HouseholdPage extends ConsumerStatefulWidget {
  const HouseholdPage({super.key});

  @override
  ConsumerState<HouseholdPage> createState() => _HouseholdPageState();

  static Future<void> push(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const HouseholdPage(),
      ),
    );
  }
}

class _HouseholdPageState extends ConsumerState<HouseholdPage> {
  // Timer for refreshing invitations periodically
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    // Immediately refresh household members when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Log.i('HouseholdPage: Refreshing members on page load');
      ref.read(householdProvider.notifier).refreshMembers();
    });

    // Set up a timer to refresh invitations every 3 seconds
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _refreshInvitations(),
    );
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Method to refresh invitations data
  void _refreshInvitations() {
    ref.read(invitationsProvider.notifier).refreshInvitations();
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(householdProvider);
    final invitationsState = ref.watch(invitationsProvider);
    final cloudRepoState = ref.watch(cloudRepoProvider);

    if (invitationsState is! AsyncData<List<Invitation>>) {
      return Scaffold(
        appBar: AppBar(title: const Text('Household')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final invitations = invitationsState.value;

    // Determine current user email from cloudRepo
    String? currentUserEmail;
    if (cloudRepoState is AsyncData) {
      currentUserEmail = cloudRepoState.value?.userEmail;
    }

    // Split invitations into sent and received
    final sentInvitations = invitations
        .where((inv) => inv.inviterEmail == currentUserEmail)
        .toList();
    final receivedInvitations = invitations
        .where((inv) => inv.recipientEmail == currentUserEmail)
        .toList();

    // Determine if user can leave household (only if more than one member)
    final bool canLeaveHousehold = members.length > 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Household'),
        actions: [
          // Add a diagnostic button
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Diagnose Household Issues',
            onPressed: _runHouseholdDiagnostics,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Members section
            const TitleHeaderWidget(title: 'Members'),
            MaterialCardWidget(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'People who have access to this household.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
                ..._buildMembersList(members),
              ],
            ),
            const SizedBox(height: 16),

            // Invitations section
            const TitleHeaderWidget(title: 'Invitations'),
            MaterialCardWidget(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Invite new members to join your household.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: const Text('Invite New Member'),
                    onPressed: _showAddMemberDialog,
                  ),
                ),

                // Received invitations section
                if (receivedInvitations.isNotEmpty) ...[
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                    child: Text(
                      'Invitations Received',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ..._buildReceivedInvitationsList(receivedInvitations),
                ],

                // Sent invitations section
                if (sentInvitations.isNotEmpty) ...[
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                    child: Text(
                      'Invitations Sent',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ..._buildSentInvitationsList(sentInvitations),
                ],
              ],
            ),

            // Only show settings section if user can leave the household
            if (canLeaveHousehold) ...[
              const SizedBox(height: 16),
              const TitleHeaderWidget(title: 'Settings'),
              MaterialCardWidget(
                children: [
                  ListTile(
                    leading: const Icon(Icons.exit_to_app, color: Colors.red),
                    title: const Text('Leave Household'),
                    subtitle: const Text(
                        'Warning: You will lose access to all household data'),
                    onTap: _handleExitHousehold,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSentInvitationsList(List<Invitation> invitations) {
    if (invitations.isEmpty) {
      return [];
    }

    return invitations.map((invitation) {
      // Format the status to look nicer
      String statusText;
      Color statusColor;

      switch (invitation.status) {
        case InvitationStatus.pending:
          statusText = 'Pending';
          statusColor = Colors.orange;
          break;
        case InvitationStatus.accepted:
          statusText = 'Accepted';
          statusColor = Colors.green;
          break;
        case InvitationStatus.rejected:
          statusText = 'Rejected';
          statusColor = Colors.red;
          break;
      }

      return ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.email_outlined),
        ),
        title: Text(invitation.recipientEmail),
        subtitle: Text(
          'Status: $statusText',
          style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.cancel_outlined, color: Colors.red),
          tooltip: 'Cancel invitation',
          onPressed: () => _confirmCancelInvitation(invitation),
        ),
      );
    }).toList();
  }

  List<Widget> _buildReceivedInvitationsList(List<Invitation> invitations) {
    if (invitations.isEmpty) {
      return [];
    }

    return invitations.map((invitation) {
      // Check if invitation is in 'accepted' state but team membership still processing
      final bool isAccepted = invitation.status == InvitationStatus.accepted;

      return ListTile(
        leading: CircleAvatar(
          backgroundColor: isAccepted ? Colors.green.shade100 : null,
          child: Icon(
            isAccepted ? Icons.check : Icons.email,
            color: isAccepted ? Colors.green : null,
          ),
        ),
        title: Text(invitation.inviterEmail), // Show the inviter's email
        subtitle: isAccepted
            ? const Text(
                'Accepted - Processing membership',
                style:
                    TextStyle(color: Colors.green, fontStyle: FontStyle.italic),
              )
            : const Text(
                'Wants to add you to their household',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
        trailing: isAccepted
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline,
                        color: Colors.green),
                    tooltip: 'Accept invitation',
                    onPressed: () => _confirmAcceptInvitation(invitation),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    tooltip: 'Decline invitation',
                    onPressed: () => _confirmDeclineInvitation(invitation),
                  ),
                ],
              ),
      );
    }).toList();
  }

  List<Widget> _buildMembersList(List<HouseholdMember> members) {
    Log.i(
        'HouseholdPage: Building members list with ${members.length} members');

    // Debug log each member's details
    for (var i = 0; i < members.length; i++) {
      final member = members[i];
      Log.i(
          'HouseholdPage: Member $i - name: ${member.name}, email: ${member.email}, userId: ${member.userId}, householdId: ${member.householdId}');
    }

    if (members.isEmpty) {
      Log.w('HouseholdPage: No household members found');
      return [
        const ListTile(
          title: Text('No members in this household.'),
          subtitle: Text('Add members by sending invitations.'),
        ),
      ];
    }

    // Get the current user's email
    final currentUserEmail = ref.read(cloudRepoProvider).value?.userEmail;

    // Sort members: current user first, then alphabetically
    final sortedMembers = List<HouseholdMember>.from(members);
    sortedMembers.sort((a, b) {
      // Current user should always be first
      if (a.email == currentUserEmail) return -1;
      if (b.email == currentUserEmail) return 1;

      // Then alphabetically by name
      return a.name.compareTo(b.name);
    });

    return sortedMembers.map((member) {
      final isCurrentUser = member.email == currentUserEmail;

      return ListTile(
        leading: CircleAvatar(
          backgroundColor: isCurrentUser ? Colors.blue.shade100 : null,
          child: Icon(
            Icons.person,
            color: isCurrentUser ? Colors.blue : null,
          ),
        ),
        title: Text(
          member.name,
          style: TextStyle(
            fontWeight: member.isAdmin ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member.email),
            if (member.isAdmin)
              const Text(
                'Admin',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: isCurrentUser
            ? null // Don't show any button for the current user
            : IconButton(
                icon:
                    const Icon(Icons.person_remove_outlined, color: Colors.red),
                tooltip: 'Remove from household',
                onPressed: () => _confirmRemoveMember(member),
              ),
      );
    }).toList();
  }

  void _confirmCancelInvitation(Invitation invitation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Invitation'),
        content: Text(
            'Are you sure you want to cancel the invitation to ${invitation.recipientEmail}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(invitationsProvider.notifier)
                  .cancelInvitation(invitation);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _confirmAcceptInvitation(Invitation invitation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Invitation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Are you sure you want to join the household from ${invitation.inviterEmail}?'),
            const SizedBox(height: 16),
            const Text(
              'Note: This will update your household membership. It may take a moment for the changes to take effect.',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Close dialog first
              Navigator.of(context).pop();

              // Show a snackbar to indicate processing
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Processing invitation acceptance...'),
                  duration: Duration(seconds: 2),
                ),
              );

              // Process the invitation
              ref
                  .read(invitationsProvider.notifier)
                  .acceptInvite(invitation)
                  .catchError((error) {
                // Only show error if the widget is still mounted
                if (!mounted) return;

                // Show error if it occurs
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${error.toString()}'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  void _confirmDeclineInvitation(Invitation invitation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Invitation'),
        content: Text(
            'Are you sure you want to decline the invitation from ${invitation.inviterEmail}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(invitationsProvider.notifier).declineInvite(invitation);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveMember(HouseholdMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
            'Are you sure you want to remove ${member.name} from the household?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(householdProvider.notifier).removeMember(member);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _handleExitHousehold() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Household'),
        content: const Text(
            'Are you sure you want to leave this household? You will lose access to shared inventory items.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(householdProvider.notifier).leave();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddMemberDialog() async {
    final result = await AddMemberDialog.show(context);
    if (result != null &&
        result.containsKey('name') &&
        result.containsKey('email')) {
      // We only need the email for sending the invitation
      // The name will be used when they accept the invitation
      final email = result['email']!;

      // Only send the invitation - don't add the member to the household yet
      // They will be added when they accept the invitation through the cloud function
      await ref.read(invitationsProvider.notifier).sendInvite(email);
    }
  }

  // Diagnostic method to help identify and fix household ID issues
  Future<void> _runHouseholdDiagnostics() async {
    Log.i('HouseholdPage: Running household diagnostics');

    final householdDB = ref.read(repositoryProvider).household;
    if (householdDB is AppwriteHouseholdDatabase) {
      // Run the diagnostics method to log current state
      await householdDB.logHouseholdInfo();

      // Only proceed if widget is still mounted
      if (!mounted) return;

      // Show a dialog with diagnostic info and option to fix
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Household Diagnostics'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current household ID: ${householdDB.id}'),
              const SizedBox(height: 16),
              const Text('Check logs for complete diagnostics information.'),
              const SizedBox(height: 8),
              const Text(
                  'If you are missing household members, you can try to refresh the database.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Get the list of database records
                final allMembers = await householdDB.getAllHouseholdMembers();

                // Find a valid household ID from the database records
                // Try to use b2d7f5bc-b25c-4f30-bed9-2d924006df36 as the preferred ID
                String newHouseholdId = householdDB.id;

                // Check all members for the preferred ID
                for (final member in allMembers) {
                  if (member.householdId.isNotEmpty) {
                    if (member.householdId ==
                        'b2d7f5bc-b25c-4f30-bed9-2d924006df36') {
                      newHouseholdId = member.householdId;
                      Log.i(
                          'HouseholdPage: Found preferred household ID: $newHouseholdId');
                      break;
                    } else if (newHouseholdId.isEmpty) {
                      newHouseholdId = member.householdId;
                      Log.i(
                          'HouseholdPage: Found fallback household ID: $newHouseholdId');
                    }
                  }
                }

                // Update the database with the new household ID if different
                if (newHouseholdId != householdDB.id) {
                  Log.i(
                      'HouseholdPage: Switching to household ID: $newHouseholdId');
                  await householdDB.join(newHouseholdId);
                  Log.i(
                      'HouseholdPage: Successfully joined household: $newHouseholdId');
                }

                // Refresh the members list
                await ref.read(householdProvider.notifier).refreshMembers();

                // Check if widget is still mounted before accessing context
                if (!mounted) return;

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Household data refreshed')),
                );
              },
              child: const Text('Refresh Database'),
            ),
          ],
        ),
      );
    }
  }
}
