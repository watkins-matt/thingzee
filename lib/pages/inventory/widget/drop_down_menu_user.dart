import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/repository.dart';
import 'package:thingzee/app.dart';
import 'package:thingzee/main.dart';
import 'package:thingzee/pages/inventory/widget/drop_down_menu.dart';
import 'package:thingzee/pages/login/login_page.dart';
import 'package:thingzee/pages/login/state/user_profile.dart';
import 'package:thingzee/pages/login/widget/verify_account_dialog.dart';
import 'package:thingzee/pages/settings/settings_page.dart';

class UserDropdownMenu extends BaseDropdownMenu {
  final WidgetRef ref;

  UserDropdownMenu({
    Key? key,
    required child,
    required this.ref,
  }) : super(
          key: key,
          child: child,
          onSelected: (value) => _onSelected(value, ref),
          itemBuilder: (context) => _itemBuilder(ref, context),
        );

  static List<PopupMenuEntry<String>> _itemBuilder(WidgetRef ref, BuildContext context) {
    final repo = ref.watch(repositoryProvider);
    final loggedIn = repo.loggedIn;
    final verified = repo.isUserVerified;

    // Change the login option based on the user's status
    var loginOption = 'Login or Register';
    if (loggedIn && verified) {
      loginOption = 'Logout';
    } else if (loggedIn && !verified) {
      loginOption = 'Verify Your Account';
    }

    final choices = {'Notifications', 'Settings', loginOption};

    return choices.map((String choice) {
      return PopupMenuItem<String>(
        value: choice,
        child: Text(choice),
      );
    }).toList();
  }

  static Future<void> _login(BuildContext context, WidgetRef ref) async {
    await LoginPage.push(context, ref);
  }

  static Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final repo = ref.watch(repositoryProvider);

    if (repo.isMultiUser && repo is CloudRepository) {
      CloudRepository repository = repo;
      final messenger = ScaffoldMessenger.of(context);
      await repository.logoutUser();
      messenger.showSnackBar(const SnackBar(
        content: Text('Logged out successfully.'),
      ));
    }
  }

  static Future<void> _onSelected(String value, WidgetRef ref) async {
    final BuildContext context = ref.read(navigatorKeyProvider).currentContext!;

    final actions = {
      'Login or Register': () async => _login(context, ref),
      'Logout': () async => _logout(context, ref),
      'Settings': () async => _settings(context, ref),
      'Verify Your Account': () async => _verifyAccount(context, ref),
    };

    if (actions.containsKey(value)) {
      await actions[value]!();
    }
  }

  static Future<void> _settings(BuildContext context, WidgetRef ref) async {
    await SettingsPage.push(context);
  }

  static Future<void> _verifyAccount(BuildContext context, WidgetRef ref) async {
    final repo = ref.watch(repositoryProvider);
    final messenger = ScaffoldMessenger.of(context);

    if (repo.isMultiUser && repo is CloudRepository) {
      bool verified = await repo.checkVerificationStatus();
      if (verified) {
        messenger.showSnackBar(const SnackBar(
          content: Text('Thank you for verifying your account.'),
        ));
        return;
      }
    }

    // Show the dialog if we are still unverified
    if (context.mounted) {
      await VerifyAccountDialog.show(context, () async {
        if (repo.isMultiUser && repo is CloudRepository) {
          final userProfile = ref.read(userProfileProvider.notifier);
          CloudRepository repository = repo;
          await repository.sendVerificationEmail(userProfile.email);
        }
      });
    }
  }
}
