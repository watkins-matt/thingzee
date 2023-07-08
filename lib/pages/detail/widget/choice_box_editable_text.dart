import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ChoiceBoxEditableText extends ConsumerStatefulWidget {
  final List<String> choices;
  final TextInputType keyboardType;
  final TextEditingController controller;
  final void Function(String) onChanged;

  const ChoiceBoxEditableText({
    Key? key,
    required this.choices,
    required this.keyboardType,
    required this.controller,
    required this.onChanged,
  }) : super(key: key);

  @override
  ConsumerState<ChoiceBoxEditableText> createState() => _ChoiceBoxEditableTextState();
}

class _ChoiceBoxEditableTextState extends ConsumerState<ChoiceBoxEditableText> {
  String? selectedChoice;

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
              child: DropdownButton<String>(
                value: selectedChoice,
                onChanged: (String? value) {
                  setState(() {
                    selectedChoice = value;
                  });
                  widget.onChanged(value ?? '');
                },
                items: widget.choices.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: TextField(
              keyboardType: widget.keyboardType,
              decoration: const InputDecoration(border: InputBorder.none, isCollapsed: true),
              textAlign: TextAlign.left,
              controller: widget.controller,
              onChanged: widget.onChanged,
              minLines: 1,
              maxLines: 1,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    selectedChoice = widget.choices.first;
  }
}
