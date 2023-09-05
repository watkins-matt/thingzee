import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/login/state/user_profile.dart';
import 'package:thingzee/pages/login/state/user_session.dart';

final registerStateProvider = StateNotifierProvider<RegisterStateNotifier, RegisterState>((ref) {
  return RegisterStateNotifier();
});

class RegisterState {
  String email = '';
  String name = '';
  String password = '';
  String confirmPassword = '';
  String errorMessage = '';

  RegisterState(
      {this.email = '',
      this.name = '',
      this.password = '',
      this.confirmPassword = '',
      this.errorMessage = ''});
}

class RegisterStateNotifier extends StateNotifier<RegisterState> {
  RegisterStateNotifier() : super(RegisterState());

  bool get passwordsMatch => state.password == state.confirmPassword;

  void clearErrorMessage() {
    if (state.errorMessage.isNotEmpty) {
      state = RegisterState(
          email: state.email,
          name: state.name,
          password: state.password,
          confirmPassword: state.confirmPassword);
    }
  }

  Future<bool> register(WidgetRef ref) async {
    final userProfile = ref.read(userProfileProvider.notifier);
    final userSession = ref.read(userSessionProvider.notifier);
    bool registerSuccess = false;

    try {
      registerSuccess = await userSession.register(state.name, state.email, state.password);
    } catch (e) {
      state = RegisterState(
          email: state.email,
          name: state.name,
          password: state.password,
          confirmPassword: state.confirmPassword,
          errorMessage: e.toString());
      return registerSuccess;
    }

    if (registerSuccess && ref.read(userSessionProvider).isAuthenticated) {
      userProfile.email = state.email;
    } else if (!registerSuccess) {
      state = RegisterState(
          email: state.email,
          name: state.name,
          password: state.password,
          confirmPassword: state.confirmPassword,
          errorMessage:
              'Unable to register. Please make sure your email is valid and that your username only contains letters and numbers.');
    }

    return registerSuccess;
  }

  void setConfirmPassword(String value) {
    state = RegisterState(
        email: state.email,
        name: state.name,
        password: state.password,
        confirmPassword: value,
        errorMessage: state.errorMessage);
  }

  void setEmail(String value) {
    state = RegisterState(
        email: value,
        name: state.name,
        password: state.password,
        confirmPassword: state.confirmPassword,
        errorMessage: state.errorMessage);
  }

  void setName(String value) {
    state = RegisterState(
        email: state.email,
        name: value,
        password: state.password,
        confirmPassword: state.confirmPassword);
  }

  void setPassword(String value) {
    state = RegisterState(
        email: state.email,
        name: state.name,
        password: value,
        confirmPassword: state.confirmPassword,
        errorMessage: state.errorMessage);
  }
}
