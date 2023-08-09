import 'dart:convert';

import 'package:crypto/crypto.dart';

String hashEmail(String email) {
  final reversedEmail = email.split('').reversed.join(''); // Reverse the email string
  final bytes = utf8.encode(reversedEmail); // Encode the reversed email to bytes
  final digest = sha256.convert(bytes); // Hash the bytes using SHA-256
  return digest.toString(); // Convert the digest to a hex string
}
