import 'package:flutter/material.dart';
import 'package:thingzee/pages/detail/widget/title_header_widget.dart';

class HouseholdLandingPage extends StatelessWidget {
  const HouseholdLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Household')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              style: ButtonStyle(
                padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 32)),
              ),
              onPressed: () {},
              child: const Text('Create New Household', style: TextStyle(fontSize: 20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const TitleHeaderWidget(title: 'Invitations'),
                ..._buildInvitationList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildInvitationList() {
    List<String> invitations = ['Example A', 'Example B'];

    return invitations.map((householdName) {
      return ListTile(
        title: Text(householdName),
        trailing: ElevatedButton(
          onPressed: () {},
          child: const Text('Join'),
        ),
      );
    }).toList();
  }

  static Future<void> push(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HouseholdLandingPage()),
    );
  }
}
