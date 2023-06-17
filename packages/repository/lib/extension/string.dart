extension NormalizeUPC on String {
  String normalizeUPC() {
    String result = this;
    if (result.length == 11) {
      result = '0$this';
    }

    return result;
  }
}
