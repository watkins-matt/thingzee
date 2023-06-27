import 'package:hooks_riverpod/hooks_riverpod.dart';

final userProfileProvider = StateNotifierProvider<UserProfile, UserProfileState>((ref) {
  return UserProfile();
});

class UserProfileState {
  final String? email;

  UserProfileState({this.email});
}

class UserProfile extends StateNotifier<UserProfileState> {
  UserProfile() : super(UserProfileState());

  String get email => state.email ?? 'Unknown';
  set email(value) => state = UserProfileState(email: value);
}
