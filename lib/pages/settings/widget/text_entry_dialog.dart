import 'package:flutter/material.dart';

class TextEntryDialog extends StatelessWidget {
  final String title;
  final TextEditingController controller;

  const TextEntryDialog({super.key, required this.title, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: TextField(controller: controller),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('OK'),
          onPressed: () {
            Navigator.of(context).pop(controller.text);
          },
        ),
      ],
    );
  }
}
