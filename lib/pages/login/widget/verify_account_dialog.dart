import 'package:flutter/material.dart';

class VerifyAccountDialog extends StatelessWidget {
  final VoidCallback? onResendEmailPressed;
  const VerifyAccountDialog({
    super.key,
    this.onResendEmailPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Account Verification Required'),
      content: const Text('You need to verify your email address before you can use '
          'online features. Please click the link sent to your '
          'email in order to verify your address.'),
      actions: [
        TextButton(
          child: const Text('Resend Verification Email'),
          onPressed: () {
            if (onResendEmailPressed != null) {
              onResendEmailPressed!();
            }

            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('OK'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  static Future<bool> show(BuildContext context, [void Function()? function]) async {
    final result = await showDialog<bool>(
        context: context,
        builder: (context) => VerifyAccountDialog(onResendEmailPressed: function));
    return result ?? false;
  }
}
