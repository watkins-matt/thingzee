import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TextFieldColumnWidget extends StatelessWidget {
  final String labelText;
  final TextEditingController controller;
  final bool readOnly;
  final String? inputFormat;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;

  const TextFieldColumnWidget({
    Key? key,
    required this.labelText,
    required this.controller,
    this.readOnly = false,
    this.inputFormat,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<TextInputFormatter>? formatters;
    if (inputFormat != null) {
      formatters = <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(inputFormat!)),
      ];
    }

    return SizedBox(
      width: 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            labelText,
          ),
          TextField(
            decoration: const InputDecoration(border: InputBorder.none),
            textAlign: TextAlign.center,
            controller: controller,
            readOnly: readOnly,
            keyboardType: keyboardType,
            inputFormatters: formatters,
            onChanged: onChanged,
            maxLines: null,
          ),
        ],
      ),
    );
  }
}
