import 'package:flutter/material.dart';

class TripCompletedConfirmationDialog extends StatefulWidget {
  const TripCompletedConfirmationDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
        context: context, builder: (context) => const TripCompletedConfirmationDialog());
    return result ?? false;
  }

  @override
  State<TripCompletedConfirmationDialog> createState() => _TripCompletedConfirmationDialogState();
}

class _TripCompletedConfirmationDialogState extends State<TripCompletedConfirmationDialog> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Shopping Trip Completed'),
      content: const Wrap(
        children: <Widget>[
          Text('Are you finished with your shopping trip?'
              '\n\nAll items in the shopping cart will be added to your inventory.')
        ],
      ),
      actions: <Widget>[
        TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
          child: const Text('OK'),
        )
      ],
    );
  }
}
