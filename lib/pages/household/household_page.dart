import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/model/household_member.dart';
import 'package:repository/model/invitation.dart';
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
  @override
  Widget build(BuildContext context) {
    final members = ref.watch(householdProvider);
    final invitationsState = ref.watch(invitationsProvider);

    if (invitationsState is! AsyncData<List<Invitation>>) {
      return Scaffold(
        appBar: AppBar(title: const Text('Household')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final invitations = invitationsState.value;

    // Determine if user can leave household (only if more than one member)
    final bool canLeaveHousehold = members.length > 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Household'),
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
                if (invitations.isNotEmpty) ...[
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 8),
                    child: Text(
                      'Pending Invitations',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ..._buildInvitationsList(invitations),
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

  List<Widget> _buildInvitationsList(List<Invitation> invitations) {
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
          child: Icon(Icons.email),
        ),
        title: Text(invitation.recipientEmail),
        subtitle: Text(
          'Status: $statusText',
          style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          tooltip: 'Cancel invitation',
          onPressed: () => _confirmCancelInvitation(invitation),
        ),
      );
    }).toList();
  }

  List<Widget> _buildMembersList(List<HouseholdMember> members) {
    if (members.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No members found.'),
        ),
      ];
    }

    // Get current user email
    final currentUserEmail =
        ref.watch(cloudRepoProvider).valueOrNull?.userEmail ?? '';

    return members.map((member) {
      bool isCurrentUser = member.email == currentUserEmail;

      return ListTile(
        leading: CircleAvatar(
          backgroundColor:
              member.isAdmin ? Colors.blue.shade100 : Colors.grey.shade200,
          child: Icon(
            Icons.person,
            color: member.isAdmin ? Colors.blue : Colors.grey,
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
}
