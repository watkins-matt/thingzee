import 'package:flutter/material.dart';

class TextEntryDialog extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;

  const TextEntryDialog({
    super.key,
    required this.title,
    required this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: TextFormField(
        controller: controller,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
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
            if (validator == null || validator!(controller.text) == null) {
              Navigator.of(context).pop(controller.text);
            }
          },
        ),
      ],
    );
  }
}
