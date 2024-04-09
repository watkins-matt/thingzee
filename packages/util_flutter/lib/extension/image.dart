import 'dart:convert';

import 'package:flutter/widgets.dart';

extension Import on Image {
  static Image fromBase64(String value) {
    return Image.memory(base64.decode(value));
  }
}
