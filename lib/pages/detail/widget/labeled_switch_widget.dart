import 'package:flutter/material.dart';

class LabeledSwitchWidget extends StatelessWidget {
  final String labelText;
  final bool value;
  final ValueChanged<bool> onChanged;

  const LabeledSwitchWidget({
    super.key,
    required this.labelText,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Switch(
                value: value,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
