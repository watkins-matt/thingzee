import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/login/state/user_profile.dart';
import 'package:thingzee/pages/login/state/user_session.dart';

final registerStateProvider = StateNotifierProvider<RegisterStateNotifier, RegisterState>((ref) {
  return RegisterStateNotifier();
});

class RegisterState {
  String email = '';
  String username = '';
  String password = '';
  String confirmPassword = '';
  String errorMessage = '';

  RegisterState(
      {this.email = '',
      this.username = '',
      this.password = '',
      this.confirmPassword = '',
      this.errorMessage = ''});
}

class RegisterStateNotifier extends StateNotifier<RegisterState> {
  RegisterStateNotifier() : super(RegisterState());

  bool get passwordsMatch => state.password == state.confirmPassword;

  Future<bool> register(WidgetRef ref) async {
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
          errorMessage: e.toString());
      return false;
    }

    if (ref.read(userSessionProvider).isAuthenticated) {
      userProfile.email = state.email;
    }

    return true;
  }

  void setConfirmPassword(String value) {
    state = RegisterState(
        email: state.email,
        username: state.username,
        password: state.password,
        confirmPassword: value,
        errorMessage: state.errorMessage);
  }

  void setEmail(String value) {
    state = RegisterState(
        email: value,
        username: state.username,
        password: state.password,
        confirmPassword: state.confirmPassword,
        errorMessage: state.errorMessage);
  }

  void setPassword(String value) {
    state = RegisterState(
        email: state.email,
        username: state.username,
        password: value,
        confirmPassword: state.confirmPassword,
        errorMessage: state.errorMessage);
  }

  void setUsername(String value) {
    state = RegisterState(
        email: state.email,
        username: value,
        password: state.password,
        confirmPassword: state.confirmPassword);
  }
}
