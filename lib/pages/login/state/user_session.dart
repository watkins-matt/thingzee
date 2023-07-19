import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:log/log.dart';
import 'package:repository/repository.dart';
import 'package:thingzee/main.dart';

final userSessionProvider = StateNotifierProvider<UserSession, SessionState>((ref) {
  final repo = ref.watch(repositoryProvider);
  return UserSession(repo);
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
  final Repository _repo;

  UserSession(this._repo) : super(SessionState.initial());

  Future<bool> login(String email, String password) async {
    if (!_repo.isMultiUser || _repo is! CloudRepository) {
      Log.w('Login not supported for this repository.');
      return false;
    }

    final repo = _repo as CloudRepository;

    try {
      state = SessionState.loading();
      await repo.loginUser(email, password);
      state = SessionState.authenticated();
    } catch (e) {
      state = SessionState.error(e.toString());
      return false;
    }

    return true;
  }

  Future<void> logout() async {
    assert(_repo.isMultiUser);
    state = SessionState.initial();
    await (_repo as CloudRepository).logoutUser();
  }

  Future<bool> register(String username, String email, String password) async {
    if (!_repo.isMultiUser || _repo is! CloudRepository) {
      Log.w('Registration not supported for this repository.');
      return false;
    }

    final repo = _repo as CloudRepository;

    try {
      state = SessionState.loading();
      await repo.registerUser(username, email, password);
      state = SessionState.authenticated();
    } catch (e) {
      state = SessionState.error(e.toString());
      return false;
    }

    return true;
  }
}
