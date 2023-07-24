import 'package:flutter/material.dart';
import 'package:thingzee/pages/inventory/widget/pop_up_menu.dart';

class UserProfileButton extends StatelessWidget {
  final CustomDropdownMenu menu;
  final String imagePath;

  const UserProfileButton({
    super.key,
    required this.menu,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => menu.build(context),
      icon: CircleAvatar(
        backgroundImage: AssetImage(imagePath),
        backgroundColor: Colors.transparent,
        radius: 16,
      ),
    );
  }
}
