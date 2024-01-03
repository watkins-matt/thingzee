import 'package:flutter/material.dart';

class TextButtonWithDropdown<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final Map<T, String> menuItems;
  final Function(T) onSelected;
  final TextStyle? textStyle;
  final Color? iconColor;

  const TextButtonWithDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.menuItems,
    required this.onSelected,
    this.textStyle,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      onSelected: onSelected,
      itemBuilder: (BuildContext context) {
        return menuItems.entries.map((entry) {
          return PopupMenuItem<T>(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList();
      },
      child: TextButton.icon(
        icon: Icon(icon, color: iconColor ?? Colors.white),
        label: Text(label, style: textStyle ?? const TextStyle(color: Colors.white)),
        onPressed:
            null, // Disable the button's own action, it will be handled by the PopupMenuButton
      ),
    );
  }
}
