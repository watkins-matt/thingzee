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

  LoginState({this.email = '', this.password = '', this.errorMessage = '', this.loading = false});
}

class LoginStateNotifier extends StateNotifier<LoginState> {
  LoginStateNotifier() : super(LoginState());

  Future<bool> login(WidgetRef ref) async {
    final userSession = ref.read(userSessionProvider.notifier);
    final sessionState = ref.read(userSessionProvider);

    state =
        LoginState(email: state.email, password: state.password, errorMessage: '', loading: true);

    try {
      await userSession.login(state.email, state.password);
    } catch (e) {
      state = LoginState(
          email: state.email, password: state.password, errorMessage: e.toString(), loading: false);
      return false;
    }

    if (sessionState.isAuthenticated) {
      final userProfile = ref.read(userProfileProvider.notifier);
      userProfile.email = state.email;
      state = LoginState(
          email: state.email, password: state.password, errorMessage: '', loading: false);
      return true;
    }

    state = LoginState(
        email: state.email,
        password: state.password,
        errorMessage: 'Unable to login. Username or password is incorrect or does not exist.',
        loading: false);
    return false;
  }

  void setEmail(String value) {
    state = LoginState(
        email: value,
        password: state.password,
        errorMessage: state.errorMessage,
        loading: state.loading);
  }

  void setPassword(String value) {
    state = LoginState(
        email: state.email,
        password: value,
        errorMessage: state.errorMessage,
        loading: state.loading);
  }
}
