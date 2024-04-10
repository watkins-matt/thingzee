import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:log/log.dart';
import 'package:repository/cloud_repository.dart';
import 'package:repository/database/mock/repository.dart';
import 'package:repository/util/hash.dart';
import 'package:thingzee/main.dart';

final userSessionProvider = StateNotifierProvider<UserSession, SessionState>((ref) {
  final repo = ref.watch(cloudRepoProvider);

  if (!repo.hasValue || repo.isLoading || repo.hasError) {
    return UserSession(MockRepository() as CloudRepository);
  }

  return UserSession(repo.requireValue);
});

class SessionState {
  final String? errorMessage;
  final bool isLoading;
  final bool isAuthenticated;

  SessionState({
    this.errorMessage,
    this.isLoading = false,
    this.isAuthenticated = false,
  });

  factory SessionState.authenticated() => SessionState(isAuthenticated: true);

  factory SessionState.error(String message) => SessionState(errorMessage: message);

  factory SessionState.initial() => SessionState();

  factory SessionState.loading() => SessionState(isLoading: true);
}

class UserSession extends StateNotifier<SessionState> {
  final CloudRepository repo;

  UserSession(this.repo) : super(SessionState.initial());

  Future<bool> login(String email, String password) async {
    if (!repo.isMultiUser) {
      Log.w(
          'Login not supported for this repository. Please ensure the cloud repository is connected and online.');
      return false;
    }

    bool loginSuccess = false;

    try {
      state = SessionState.loading();
      loginSuccess = await repo.loginUser(email, password);
      if (loginSuccess) {
        state = SessionState.authenticated();
      }
    } catch (e) {
      state = SessionState.error(e.toString());
      return loginSuccess;
    }

    return loginSuccess;
  }

  Future<void> logout() async {
    assert(repo.isMultiUser);
    state = SessionState.initial();
    await repo.logoutUser();
  }

  Future<bool> register(String username, String email, String password) async {
    if (!repo.isMultiUser) {
      Log.w('Registration not supported for this repository.');
      return false;
    }

    bool registerSuccess = false;

    try {
      state = SessionState.loading();
      final userId = hashEmail(email);
      registerSuccess = await repo.registerUser(userId, email, password);

      if (registerSuccess) {
        state = SessionState.authenticated();
      }
    } catch (e) {
      state = SessionState.error('Invalid registration data. Please try again.');
      return registerSuccess;
    }

    return registerSuccess;
  }
}
