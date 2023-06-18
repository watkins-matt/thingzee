import 'package:flutter/material.dart';

class LabeledText extends StatelessWidget {
  final String labelText;
  final String value;
  final TextStyle labelTextStyle;
  final TextStyle valueTextStyle;
  final double textScaleFactor;
  final TextAlign valueTextAlign;

  const LabeledText({
    Key? key,
    required this.labelText,
    required this.value,
    this.labelTextStyle = const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    ),
    this.valueTextStyle = const TextStyle(fontStyle: FontStyle.italic, color: Colors.blue),
    this.textScaleFactor = 0.9,
    this.valueTextAlign = TextAlign.start,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                labelText,
                style: labelTextStyle,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              value,
              textScaleFactor: textScaleFactor,
              style: valueTextStyle,
              textAlign: valueTextAlign,
            ),
          ),
        ),
      ],
    );
  }
}
