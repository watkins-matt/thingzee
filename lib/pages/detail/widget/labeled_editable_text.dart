import 'package:flutter/material.dart';

class LabeledEditableText extends StatelessWidget {
  final String labelText;
  final TextInputType keyboardType;
  final TextEditingController controller;
  final void Function(String) onChanged;
  static const int maxLines = 1;
  static const int minLines = 1;

  const LabeledEditableText({
    Key? key,
    required this.labelText,
    required this.keyboardType,
    required this.controller,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                labelText,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: TextField(
              keyboardType: keyboardType,
              decoration: const InputDecoration(border: InputBorder.none, isCollapsed: true),
              textAlign: TextAlign.left,
              controller: controller,
              onChanged: onChanged,
              minLines: 1,
              maxLines: 1,
            ),
          ),
        ),
      ],
    );
  }
}
