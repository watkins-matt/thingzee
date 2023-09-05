import 'package:uuid/uuid.dart';

String hashBarcode(String username, String barcode) {
  const namespace = '6d622152-e5b1-4e7c-af71-996588c3711c';
  final joinedString = '$username-$barcode';

  var uuid = const Uuid();
  return uuid.v5(namespace, joinedString);
}

String hashEmail(String email) {
  const namespace = '3c7fd503-ad66-4d00-80c6-01c87a9ff9a3';
  final reversedEmail = email.split('').reversed.join('');

  var uuid = const Uuid();
  return uuid.v5(namespace, reversedEmail);
}
