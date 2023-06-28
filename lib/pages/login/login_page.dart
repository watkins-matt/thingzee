import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/login/state/user_profile.dart';
import 'package:thingzee/pages/login/state/user_session.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  static Future<void> push(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Future<String?> _login(WidgetRef ref, LoginData data) async {
    debugPrint('Email: ${data.name}, Password: ${data.password}');
    final userSession = ref.read(userSessionProvider.notifier);
    final sessionState = ref.read(userSessionProvider);

    await userSession.login(data.name, data.password);

    if (sessionState.isAuthenticated) {
      final userProfile = ref.read(userProfileProvider.notifier);
      userProfile.email = data.name;
      return null;
    }

    return 'Unable to login. Username or password is incorrect or does not exist.';
  }

  Future<String?> _register(WidgetRef ref, SignupData data) async {
    debugPrint('Registration Email: ${data.name}, Password: ${data.password}');
    final userProfile = ref.read(userProfileProvider.notifier);
    final userSession = ref.read(userSessionProvider.notifier);

    if (data.name == null || data.name!.isEmpty) {
      return 'Email address is required.';
    }

    if (data.password == null || data.password!.isEmpty) {
      return 'Password is required.';
    }

    try {
      await userSession.register(data.name!, data.name!, data.password!);
    } catch (e) {
      return e.toString();
    }

    if (ref.read(userSessionProvider).isAuthenticated) {
      userProfile.email = data.name!;
      return null;
    }

    return 'Unable to register. Please choose an email address that is not already registered.';
  }

  Future<String> _recoverPassword(String name) async {
    debugPrint('Name: $name');

    return '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FlutterLogin(
        title: 'Thingzee',
        onLogin: (data) => _login(ref, data),
        onSignup: (data) => _register(ref, data),
        onSubmitAnimationCompleted: () async {
          if (context.mounted) {
            Navigator.pop(context);
          }
        },
        messages: LoginMessages(
            recoverPasswordDescription: 'We will send you an email to reset your password.'),
        onRecoverPassword: _recoverPassword);
  }
}
