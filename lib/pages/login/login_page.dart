import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/home/home_page.dart';
import 'package:thingzee/pages/login/register_page.dart';
import 'package:thingzee/pages/login/state/user_profile.dart';
import 'package:thingzee/pages/login/state/user_session.dart';

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

class LoginState {
  String email = '';
  String password = '';
  String loginError = '';
  bool loading = false;

  LoginState({this.email = '', this.password = '', this.loginError = '', this.loading = false});
}

class LoginStateNotifier extends StateNotifier<LoginState> {
  LoginStateNotifier() : super(LoginState());

  void setEmail(String value) {
    state = LoginState(
        email: value,
        password: state.password,
        loginError: state.loginError,
        loading: state.loading);
  }

  void setPassword(String value) {
    state = LoginState(
        email: state.email, password: value, loginError: state.loginError, loading: state.loading);
  }

  Future<bool> login(WidgetRef ref) async {
    final userSession = ref.read(userSessionProvider.notifier);
    final sessionState = ref.read(userSessionProvider);

    state = LoginState(email: state.email, password: state.password, loginError: '', loading: true);

    try {
      await userSession.login(state.email, state.password);
    } catch (e) {
      state = LoginState(
          email: state.email, password: state.password, loginError: e.toString(), loading: false);
      return false;
    }

    if (sessionState.isAuthenticated) {
      final userProfile = ref.read(userProfileProvider.notifier);
      userProfile.email = state.email;
      state =
          LoginState(email: state.email, password: state.password, loginError: '', loading: false);
      return true;
    }

    state = LoginState(
        email: state.email,
        password: state.password,
        loginError: 'Unable to login. Username or password is incorrect or does not exist.',
        loading: false);
    return false;
  }
}

final loginStateProvider = StateNotifierProvider<LoginStateNotifier, LoginState>((ref) {
  return LoginStateNotifier();
});

class LoginPage extends ConsumerWidget {
  LoginPage({Key? key}) : super(key: key);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  static Future<void> push(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
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
                          ref.read(loginStateProvider.notifier).setEmail(value);
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
                            bool success = await ref.read(loginStateProvider.notifier).login(ref);
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Logged in successfully.'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                              await Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const HomePage()),
                              );
                            }
                          }
                        },
                      ),
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
    );
  }
}
