import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/login/register_page.dart';
import 'package:thingzee/pages/login/state/login_state.dart';
import 'package:thingzee/pages/login/state/user_profile.dart';
import 'package:thingzee/pages/settings/state/settings_state.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();

  static Future<void> push(BuildContext context, WidgetRef ref) async {
    // Reset any error messages
    ref.read(loginStateProvider.notifier).clearErrorMessage();

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }
}

class _LoginPageState extends ConsumerState<LoginPage> {
  // Create a single form key that persists across rebuilds
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginStateProvider);
    final isDarkMode = ref.watch(isDarkModeProvider(context));

    // Handle autofocus on initial load 
    if (!_isInitialized) {
      _isInitialized = true;
      // Use post-frame callback to focus after the UI is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(loginState.emailFocus);
      });
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (pop, result) async {
        // Clear any error messages when we leave the page
        ref.read(loginStateProvider.notifier).clearErrorMessage();
      },
      child: GestureDetector(
        // Unfocus when tapping outside of text fields
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: !isDarkMode ? Colors.blue : Theme.of(context).scaffoldBackgroundColor,
          body: AutofillGroup(
            child: Center(
              child: Card(
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
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                              letterSpacing: .5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            focusNode: loginState.emailFocus,
                            autofillHints: const [AutofillHints.email],
                            onChanged: (value) {
                              ref.read(loginStateProvider.notifier).setEmail(value.trim());
                            },
                            onFieldSubmitted: (_) {
                              // Move focus to password field when done
                              ref.read(loginStateProvider.notifier).moveFocusToPassword(context);
                            },
                            validator: (val) {
                              if (val!.isEmpty) {
                                return 'Email cannot be empty.';
                              } else {
                                return null;
                              }
                            },
                            decoration: InputDecoration(
                                hintText: 'Email',
                                prefixIcon: const Icon(Icons.email_outlined),
                                fillColor: Colors.grey[200]),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            focusNode: loginState.passwordFocus,
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
                                hintText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                fillColor: Colors.grey[200]),
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
                            child: loginState.loading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                    backgroundColor: Colors.blue,
                                  )
                                : const Text('Login'),
                            onPressed: () async {
                              if (!loginState.loading &&
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
      ),
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
