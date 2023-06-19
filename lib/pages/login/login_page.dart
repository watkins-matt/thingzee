import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  static Future<void> push(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Future<String?> _authenticate(LoginData data) async {
    debugPrint('Email: ${data.name}, Password: ${data.password}');
    return null;
  }

  Future<String?> _register(SignupData data) async {
    debugPrint('Registration Email: ${data.name}, Password: ${data.password}');
    return null;
  }

  Future<String> _recoverPassword(String name) async {
    debugPrint('Name: $name');

    return '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FlutterLogin(
        title: 'Thingzee',
        onLogin: _authenticate,
        onSignup: _register,
        onSubmitAnimationCompleted: () async {
          if (context.mounted) {
            Navigator.pop(context);
          }
        },
        onRecoverPassword: _recoverPassword);
  }
}
