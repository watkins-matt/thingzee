import 'package:el_tooltip/el_tooltip.dart';
import 'package:flutter/material.dart';

class HelpIconButton extends StatelessWidget {
  final String message;

  const HelpIconButton({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElTooltip(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        position: ElTooltipPosition.topCenter,
        color: Colors.blue,
        distance: 10,
        padding: const EdgeInsets.all(14),
        radius: const Radius.circular(8),
        showModal: true,
        showArrow: true,
        showChildAboveOverlay: false,
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.help_outline),
        ));
  }
}
