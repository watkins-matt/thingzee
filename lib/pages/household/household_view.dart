import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/model/cloud/household.dart';
import 'package:thingzee/pages/detail/widget/title_header_widget.dart';
import 'package:thingzee/pages/household/widget/add_member_dialog.dart';

class HouseholdViewPage extends ConsumerStatefulWidget {
  final Household household;
  const HouseholdViewPage({super.key, required this.household});

  @override
  ConsumerState<HouseholdViewPage> createState() => _HouseholdViewPageState();
}

class _HouseholdViewPageState extends ConsumerState<HouseholdViewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Household View'),
        actions: [
          TextButton.icon(
              onPressed: _handleExitHousehold,
              icon: const Icon(Icons.exit_to_app),
              label: const Text(
                'Leave Household',
              ))
        ],
      ),
      body: Column(
        children: [
          Text('Household created on: ${widget.household.timestamp}'),
          TitleHeaderWidget(
            title: 'Members',
            actionButton: IconButton(
              onPressed: _showAddMemberDialog,
              icon: const Icon(Icons.add),
            ),
          ),
          ..._buildMembersList(),
          if (_isAdmin()) ...[
            const Text('You are an admin!'),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Promote to Admin'),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildMembersList() {
    return widget.household.names.map((name) => ListTile(title: Text(name))).toList();
  }

  void _handleExitHousehold() {
    if (widget.household.userIds.length > 1) {
      throw UnimplementedError();
    } else {
      throw UnimplementedError();
    }
  }

  bool _isAdmin() {
    return false;
  }

  Future<void> _showAddMemberDialog() async {
    final result = await AddMemberDialog.show(context);
    if (result != null) {
      final name = result['name'];
      final email = result['email'];
      throw UnimplementedError();
    }
  }
}
