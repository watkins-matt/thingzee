import 'dart:convert';
import 'dart:typed_data';

extension Sanitize on String {
  String sanitize() {
    return replaceAll('"', '""').replaceAll("'", "''");
  }
}

extension Substring on String {
  String substringBeforeLast(String substring) {
    return substringBefore(indexOfLast(substring));
  }

  String substringBeforeFirst(String substring) {
    return substringBefore(indexOf(substring));
  }

  String ensureStartsAndEndsWith(String substring) {
    return ensureStartsWith(substring).ensureEndsWith(substring);
  }

  String ensureStartsWith(String substring) {
    return startsWith(substring) ? this : substring + this;
  }

  String ensureEndsWith(String substring) {
    return endsWith(substring) ? this : this + substring;
  }

  String removeFirst(String character) {
    return isNotEmpty && this[0] == character ? substring(1) : this;
  }

  String removeLast(String character) {
    return isNotEmpty && this[lastIndex()] == character ? substringBefore(lastIndex()) : this;
  }

  String trimFirstAndLast(String character) {
    return removeFirst(character).removeLast(character);
  }

  String substringBefore(int index) {
    return substring(0, index);
  }

  int lastIndex() {
    return isNotEmpty ? length - 1 : 0;
  }

  int indexOfLast(String character) {
    assert(character.length == 1);
    var lastIndex = this.lastIndex();

    if (isEmpty) return 0;

    while (this[lastIndex] != character && lastIndex > 0) {
      lastIndex--;
    }

    return lastIndex;
  }

  String get titleCase => isEmpty
      ? this
      : split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');

  Uint8List get bytes {
    return Uint8List.fromList(utf8.encode(this));
  }
}
