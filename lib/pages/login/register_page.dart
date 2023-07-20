import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:log/log.dart';
import 'package:thingzee/pages/login/login_page.dart';
import 'package:thingzee/pages/login/state/register_state.dart';

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

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;
  final _touchedFields = <String>{};

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerStateProvider);

    return WillPopScope(
      onWillPop: () async {
        // Clear any error messages when we leave the page
        ref.read(registerStateProvider.notifier).clearErrorMessage();
        return true;
      },
      child: Scaffold(
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
                          // Mark all fields touched so we validate before submitting
                          _markFieldTouched('username');
                          _markFieldTouched('email');
                          _markFieldTouched('password');
                          _markFieldTouched('password_confirmation');

                          if (_formKey.currentState!.validate()) {
                            Log.d('Email: ${registerState.email}');
                            Log.d('Username: ${registerState.username}');
                            Log.d('Password: ${registerState.password}');

                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            bool success =
                                await ref.read(registerStateProvider.notifier).register(ref);

                            // Registration was successful
                            if (success && context.mounted) {
                              Navigator.pop(context);
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Registration successful.'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      Visibility(
                          visible: registerState.errorMessage.isNotEmpty,
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              Text(
                                registerState.errorMessage,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 20),
                            ],
                          )),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(context, NoAnimationRoute(child: LoginPage()));
                          ref.read(registerStateProvider.notifier).clearErrorMessage();
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
