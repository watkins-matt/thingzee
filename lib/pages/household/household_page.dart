import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/model/household_member.dart';
import 'package:repository/model/invitation.dart';
import 'package:thingzee/pages/detail/widget/labeled_text.dart';
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
    final householdMembers = ref.watch(householdProvider);
    final householdCreatedDate = ref.watch(householdProvider.notifier).household.created;
    final householdId = ref.watch(householdProvider.notifier).household.id;
    final invitations = ref.watch(invitationsProvider);

    List<Widget> content = [];

    if (invitations.isNotEmpty) {
      content.add(MaterialCardWidget(children: [
        const TitleHeaderWidget(title: 'Invitations'),
        ..._buildInvitationsList(invitations),
      ]));
    }

    content.addAll([
      MaterialCardWidget(children: [
        const TitleHeaderWidget(title: 'Information'),
        LabeledText(labelText: 'ID', value: householdId),
        LabeledText(labelText: 'Created', value: householdCreatedDate.toIso8601String()),
      ]),
      const SizedBox(
        height: 8,
      ),
      MaterialCardWidget(children: [
        TitleHeaderWidget(
          title: 'Members',
          actionButton: IconButton(
            onPressed: _showAddMemberDialog,
            icon: const Icon(Icons.add),
          ),
        ),
        ..._buildMembersList(householdMembers),
      ])
    ]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Household'),
        actions: [
          TextButton.icon(
            onPressed: _handleExitHousehold,
            icon: const Icon(Icons.exit_to_app),
            label: const Text('Leave'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: content,
      ),
    );
  }

  void _acceptInvitation(Invitation invitation) {
    ref.read(invitationsProvider.notifier).acceptInvite(invitation);
    ref.read(householdProvider.notifier).refreshMembers();
  }

  List<Widget> _buildInvitationsList(List<Invitation> invitations) {
    return invitations.map((invitation) {
      return ListTile(
        title: Text(invitation.inviterEmail),
        trailing: ElevatedButton(
          onPressed: () => _acceptInvitation(invitation),
          child: const Text('Accept'),
        ),
      );
    }).toList();
  }

  List<Widget> _buildMembersList(List<HouseholdMember> members) {
    return members.map((member) {
      bool userInvited = ref.watch(invitationsProvider.notifier).isUserInvited(member.email);

      Widget? trailingWidget = userInvited
          ? ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
              ),
              child: const Text('Invite Sent'),
            )
          : null;

      return ListTile(
        title: Text(member.name),
        subtitle: Text(member.email),
        trailing: trailingWidget,
      );
    }).toList();
  }

  void _handleExitHousehold() {
    ref.read(householdProvider.notifier).leave();
  }

  Future<void> _showAddMemberDialog() async {
    final result = await AddMemberDialog.show(context);
    if (result != null && result.containsKey('name') && result.containsKey('email')) {
      final name = result['name']!;
      final email = result['email']!;
      ref.read(householdProvider.notifier).addMember(name, email);
      ref.read(invitationsProvider.notifier).sendInvite(email);
    }
  }
}
