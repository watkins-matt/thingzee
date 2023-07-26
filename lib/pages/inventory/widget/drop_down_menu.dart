import 'package:flutter/material.dart';

class BaseDropdownMenu extends StatelessWidget {
  final PopupMenuItemBuilder<String> itemBuilder;
  final Function(String) onSelected;
  final Widget child;

  const BaseDropdownMenu({
    super.key,
    required this.child,
    required this.itemBuilder,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: itemBuilder,
      position: PopupMenuPosition.under,
      offset: const Offset(-10, 0),
      elevation: 20,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: child,
    );
  }
}
