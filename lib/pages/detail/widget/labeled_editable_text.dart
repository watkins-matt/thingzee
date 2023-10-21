import 'package:flutter/material.dart';
import 'package:thingzee/pages/detail/widget/help_icon_button.dart';

class LabeledEditableText extends StatelessWidget {
  static const int maxLines = 1;
  static const int minLines = 1;
  final String labelText;
  final TextInputType keyboardType;
  final TextEditingController controller;
  final void Function(String) onChanged;
  final String? helpTooltip;

  const LabeledEditableText({
    Key? key,
    required this.labelText,
    required this.keyboardType,
    required this.controller,
    required this.onChanged,
    this.helpTooltip,
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
          child: Row(
            children: [
              Expanded(
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
              if (helpTooltip != null)
                HelpIconButton(
                  message: helpTooltip!,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
