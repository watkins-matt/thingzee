import 'package:uuid/uuid.dart';

String hashBarcode(String barcode) {
  const namespace = '98570464-0dcb-47ab-ad30-8b286bed69af';

  var uuid = const Uuid();
  return uuid.v5(namespace, barcode);
}

String hashEmail(String email) {
  const namespace = '3c7fd503-ad66-4d00-80c6-01c87a9ff9a3';
  final reversedEmail = email.split('').reversed.join('');

  var uuid = const Uuid();
  return uuid.v5(namespace, reversedEmail);
}

String hashUsernameBarcode(String username, String barcode) {
  const namespace = '6d622152-e5b1-4e7c-af71-996588c3711c';
  final joinedString = '$username-$barcode';

  var uuid = const Uuid();
  return uuid.v5(namespace, joinedString);
}
