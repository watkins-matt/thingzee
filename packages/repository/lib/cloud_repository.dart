import 'dart:async';

import 'package:repository/database/cloud/invitation_database.dart';
import 'package:repository/network/connectivity_service.dart';
import 'package:repository/repository.dart';

abstract class CloudRepository extends Repository {
  final ConnectivityService connectivity;
  late InvitationDatabase invitation;

  CloudRepository(this.connectivity) {
    connectivity.addListener(handleConnectivityChange);
  }

  @override
  bool get isMultiUser => true;
  bool get isOnline => connectivity.status == ConnectivityStatus.online;
  String get userEmail;
  String get userId;

  Future<bool> checkVerificationStatus();
  void handleConnectivityChange(ConnectivityStatus status);
  Future<bool> loginUser(String email, String password);
  Future<void> logoutUser();
  Future<bool> registerUser(String username, String email, String password);
  Future<void> sendVerificationEmail(String email);
  Future<bool> sync();
}