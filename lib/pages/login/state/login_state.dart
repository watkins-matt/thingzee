import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/login/state/user_profile.dart';
import 'package:thingzee/pages/login/state/user_session.dart';

final loginStateProvider = StateNotifierProvider<LoginStateNotifier, LoginState>((ref) {
  return LoginStateNotifier();
});

/// Represents the state for the login page, including the content
/// of the email and password fields, any login errors, and whether
/// the login button is currently loading.
class LoginState {
  String email = '';
  String password = '';
  String errorMessage = '';
  bool loading = false;
  final FocusNode emailFocus;
  final FocusNode passwordFocus;

  LoginState({
    this.email = '', 
    this.password = '', 
    this.errorMessage = '', 
    this.loading = false,
    FocusNode? emailFocus,
    FocusNode? passwordFocus,
  }) : 
    emailFocus = emailFocus ?? FocusNode(),
    passwordFocus = passwordFocus ?? FocusNode();

  // Create a copy with updated values
  LoginState copyWith({
    String? email,
    String? password,
    String? errorMessage,
    bool? loading,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      errorMessage: errorMessage ?? this.errorMessage,
      loading: loading ?? this.loading,
      emailFocus: emailFocus,
      passwordFocus: passwordFocus,
    );
  }

  // Clean up resources
  void dispose() {
    emailFocus.dispose();
    passwordFocus.dispose();
  }
}

class LoginStateNotifier extends StateNotifier<LoginState> {
  LoginStateNotifier() : super(LoginState());

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  void clearErrorMessage() {
    if (state.errorMessage.isNotEmpty) {
      state = state.copyWith(errorMessage: '');
    }
  }

  Future<bool> login(WidgetRef ref) async {
    final userSession = ref.read(userSessionProvider.notifier);
    final sessionState = ref.read(userSessionProvider);
    bool loggedIn = false;

    state = state.copyWith(errorMessage: '', loading: true);

    try {
      loggedIn = await userSession.login(state.email, state.password);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), loading: false);
      return loggedIn;
    }

    if (sessionState.isAuthenticated) {
      final userProfile = ref.read(userProfileProvider.notifier);
      userProfile.email = state.email;
      state = state.copyWith(loading: false);
      return loggedIn;
    }

    state = state.copyWith(
      errorMessage: 'Unable to login. Your email or password may be incorrect.',
      loading: false
    );
    return loggedIn;
  }

  void setEmail(String value) {
    state = state.copyWith(email: value);
  }

  void setPassword(String value) {
    state = state.copyWith(password: value);
  }

  void moveFocusToPassword(BuildContext context) {
    FocusScope.of(context).requestFocus(state.passwordFocus);
  }
}
