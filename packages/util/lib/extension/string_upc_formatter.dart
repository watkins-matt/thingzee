extension UPCFormatter on String {
  String formatAsBarcode() {
    if (length != 12) {
      return this;
    }

    String first = this[0];
    String left = substring(1, 5);
    String right = substring(6, 10);
    String last = substring(length - 1);
    String formatted = '$first $left $right $last';
    return formatted;
  }
}
