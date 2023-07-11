import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:log/log.dart';
import 'package:thingzee/pages/login/login_page.dart';
import 'package:thingzee/pages/login/state/user_profile.dart';
import 'package:thingzee/pages/login/state/user_session.dart';

final registerStateProvider = StateNotifierProvider<RegisterStateNotifier, RegisterState>((ref) {
  return RegisterStateNotifier();
});

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();

  static Future<void> push(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }
}

class RegisterState {
  String email = '';
  String username = '';
  String password = '';
  String confirmPassword = '';
  String errorText = '';

  RegisterState(
      {this.email = '',
      this.username = '',
      this.password = '',
      this.confirmPassword = '',
      this.errorText = ''});
}

class RegisterStateNotifier extends StateNotifier<RegisterState> {
  RegisterStateNotifier() : super(RegisterState());

  bool get passwordsMatch => state.password == state.confirmPassword;

  Future<void> register(WidgetRef ref) async {
    final userProfile = ref.read(userProfileProvider.notifier);
    final userSession = ref.read(userSessionProvider.notifier);

    try {
      await userSession.register(state.username, state.email, state.password);
    } catch (e) {
      state = RegisterState(
          email: state.email,
          username: state.username,
          password: state.password,
          confirmPassword: state.confirmPassword,
          errorText: e.toString());
      return;
    }

    if (ref.read(userSessionProvider).isAuthenticated) {
      userProfile.email = state.email;
    }
  }

  void setConfirmPassword(String value) {
    state = RegisterState(
        email: state.email,
        username: state.username,
        password: state.password,
        confirmPassword: value,
        errorText: state.errorText);
  }

  void setEmail(String value) {
    state = RegisterState(
        email: value,
        username: state.username,
        password: state.password,
        confirmPassword: state.confirmPassword,
        errorText: state.errorText);
  }

  void setPassword(String value) {
    state = RegisterState(
        email: state.email,
        username: state.username,
        password: value,
        confirmPassword: state.confirmPassword,
        errorText: state.errorText);
  }

  void setUsername(String value) {
    state = RegisterState(
        email: state.email,
        username: value,
        password: state.password,
        confirmPassword: state.confirmPassword);
  }
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;
  final _touchedFields = <String>{};

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerStateProvider);

    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
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
                    TextFormField(
                      onChanged: (value) {
                        _markFieldTouched('username');
                        ref.read(registerStateProvider.notifier).setUsername(value);
                        _formKey.currentState!.validate();
                      },
                      validator: (val) {
                        if (!_fieldTouched('username')) {
                          return null;
                        }
                        if (val!.isEmpty) {
                          return 'Username cannot be empty.';
                        } else {
                          return null;
                        }
                      },
                      decoration:
                          InputDecoration(hintText: 'Username', fillColor: Colors.grey[200]),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      onChanged: (value) {
                        _markFieldTouched('email');
                        ref.read(registerStateProvider.notifier).setEmail(value);
                        _formKey.currentState!.validate();
                      },
                      validator: (val) {
                        if (!_fieldTouched('email')) {
                          return null;
                        }
                        if (val!.isEmpty) {
                          return 'Email address cannot be empty.';
                        } else {
                          return null;
                        }
                      },
                      decoration: InputDecoration(hintText: 'Email', fillColor: Colors.grey[200]),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      obscureText: _isPasswordHidden,
                      onChanged: (value) {
                        _markFieldTouched('password');
                        ref.read(registerStateProvider.notifier).setPassword(value);
                        _formKey.currentState!.validate();
                      },
                      validator: (val) {
                        if (!_fieldTouched('password')) {
                          return null;
                        }
                        if (val!.length < 8) {
                          return 'Password must be at least 8 characters long.';
                        } else if (!ref.read(registerStateProvider.notifier).passwordsMatch) {
                          return 'Passwords do not match.';
                        } else {
                          return null;
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Password',
                        fillColor: Colors.grey[200],
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordHidden ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      obscureText: _isConfirmPasswordHidden,
                      onChanged: (value) {
                        _markFieldTouched('password_confirmation');
                        ref.read(registerStateProvider.notifier).setConfirmPassword(value);
                        _formKey.currentState!.validate();
                      },
                      validator: (val) {
                        if (!_fieldTouched('password_confirmation')) {
                          return null;
                        }
                        if (val!.length < 8) {
                          return 'Password must be at least 8 characters long.';
                        } else {
                          return null;
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Confirm Password',
                        fillColor: Colors.grey[200],
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordHidden ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: _toggleConfirmPasswordVisibility,
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
                      child: const Text('Register'),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          Log.d('Email: ${registerState.email}');
                          Log.d('Username: ${registerState.username}');
                          Log.d('Password: ${registerState.password}');

                          await ref.read(registerStateProvider.notifier).register(ref);
                        }
                      },
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(context, NoAnimationRoute(child: LoginPage()));
                      },
                      child: const Text(
                        'Already registered? Login instead.',
                        style: TextStyle(color: Colors.blue),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _fieldTouched(String fieldName) {
    return _touchedFields.contains(fieldName);
  }

  void _markFieldTouched(String fieldName) {
    _touchedFields.add(fieldName);
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordHidden = !_isConfirmPasswordHidden;
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordHidden = !_isPasswordHidden;
    });
  }
}
