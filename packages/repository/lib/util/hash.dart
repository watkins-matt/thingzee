import 'package:uuid/uuid.dart';

String hashEmail(String email) {
  const namespace = '3c7fd503-ad66-4d00-80c6-01c87a9ff9a3';
  final reversedEmail = email.split('').reversed.join('');

  var uuid = const Uuid();
  return uuid.v5(namespace, reversedEmail);
}
