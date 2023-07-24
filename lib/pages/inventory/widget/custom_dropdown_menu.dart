import 'package:flutter/material.dart';

class CustomDropdownMenu extends StatelessWidget {
  final PopupMenuItemBuilder<String> itemBuilder;
  final Function(String) onSelected;

  const CustomDropdownMenu({
    super.key,
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
    );
  }
}
