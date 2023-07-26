import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/inventory/widget/drop_down_menu_user.dart';

class UserProfileButton extends ConsumerWidget {
  final String imagePath;

  const UserProfileButton({
    super.key,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return UserDropdownMenu(
        ref: ref,
        child: CircleAvatar(
          backgroundImage: AssetImage(imagePath),
          backgroundColor: Colors.transparent,
          radius: 16,
        ));
  }
}
