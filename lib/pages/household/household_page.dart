import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/model/household_member.dart';
import 'package:thingzee/pages/detail/widget/labeled_text.dart';
import 'package:thingzee/pages/detail/widget/material_card_widget.dart';
import 'package:thingzee/pages/detail/widget/title_header_widget.dart';
import 'package:thingzee/pages/household/state/household_state.dart';
import 'package:thingzee/pages/household/widget/add_member_dialog.dart';

class HouseholdPage extends ConsumerStatefulWidget {
  const HouseholdPage({Key? key}) : super(key: key);

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

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
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
        children: [
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
        ],
      ),
    );
  }

  List<Widget> _buildMembersList(List<HouseholdMember> members) {
    return members.map((member) {
      return ListTile(
        title: Text(member.name),
        subtitle: Text(member.email),
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
    }
  }
}