import 'package:flutter/material.dart';

class UserProfileButton extends StatelessWidget {
  final Function(String) onSelected;
  final PopupMenuItemBuilder<String> itemBuilder;
  final String imagePath;

  const UserProfileButton(
      {super.key, required this.onSelected, required this.itemBuilder, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: itemBuilder,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 20),
      elevation: 20,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: CircleAvatar(
        backgroundImage: AssetImage(imagePath),
        backgroundColor: Colors.transparent,
        radius: 16,
      ),
    );
  }
}
