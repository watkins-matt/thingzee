import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/login/register_page.dart';
import 'package:thingzee/pages/login/state/login_state.dart';
import 'package:thingzee/pages/login/state/user_profile.dart';

class LoginPage extends ConsumerWidget {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginState = ref.watch(loginStateProvider);

    return WillPopScope(
      onWillPop: () async {
        // Clear any error messages when we leave the page
        ref.read(loginStateProvider.notifier).clearErrorMessage();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.blue,
        body: AutofillGroup(
          child: Center(
            child: Card(
              color: Colors.white,
              shadowColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                            letterSpacing: .5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          autofillHints: const [AutofillHints.email],
                          onChanged: (value) {
                            ref.read(loginStateProvider.notifier).setEmail(value.trim());
                          },
                          validator: (val) {
                            if (val!.isEmpty) {
                              return 'Email cannot be empty.';
                            } else {
                              return null;
                            }
                          },
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.email_outlined),
                            labelText: 'Email',
                            filled: true,
                            fillColor: Colors.blue[75],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          autofillHints: const [AutofillHints.password],
                          obscureText: true,
                          onChanged: (value) {
                            ref.read(loginStateProvider.notifier).setPassword(value);
                          },
                          validator: (val) {
                            if (val!.isEmpty) {
                              return 'Password cannot be empty.';
                            } else {
                              return null;
                            }
                          },
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_outline),
                            labelText: 'Password',
                            filled: true,
                            fillColor: Colors.blue[75],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 5,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                          ),
                          child: ref.watch(loginStateProvider).loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                  backgroundColor: Colors.blue,
                                )
                              : const Text('Login'),
                          onPressed: () async {
                            if (!ref.read(loginStateProvider).loading &&
                                _formKey.currentState!.validate()) {
                              final scaffoldMessenger = ScaffoldMessenger.of(context);

                              bool success = await ref.read(loginStateProvider.notifier).login(ref);
                              if (success && context.mounted) {
                                final userProfile = ref.read(userProfileProvider.notifier);
                                userProfile.email = ref.read(loginStateProvider).email;

                                Navigator.pop(context);
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Logged in successfully.'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        Visibility(
                            visible: loginState.errorMessage.isNotEmpty,
                            child: Column(
                              children: [
                                const SizedBox(height: 20),
                                Text(
                                  loginState.errorMessage,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ],
                            )),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {
                                // Navigate to Forgot Password page
                              },
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                    context, NoAnimationRoute(child: const RegisterPage()));
                                ref.read(loginStateProvider.notifier).clearErrorMessage();
                              },
                              child: const Text(
                                'Register',
                                style: TextStyle(
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> push(BuildContext context, WidgetRef ref) async {
    // Reset any error messages
    ref.read(loginStateProvider.notifier).clearErrorMessage();

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }
}

class NoAnimationRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  NoAnimationRoute({required this.child})
      : super(
          pageBuilder: (BuildContext context, Animation<double> animation,
              Animation<double> secondaryAnimation) {
            return child;
          },
          transitionDuration: Duration.zero,
        );
}
