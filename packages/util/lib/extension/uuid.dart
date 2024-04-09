extension AbbreviatedUuidExtension on String {
  /// Extracts an abbreviated UUID (last 12 characters after the last hyphen).
  /// Returns the entire string if it doesn't contain a hyphen.
  /// Handles invalid input gracefully by returning the original string.
  String get abbreviatedUuid {
    // Check if the string contains a hyphen, indicating a potential UUID format
    if (contains('-')) {
      // Attempt to split the string by hyphens and return the last segment
      return split('-').last;
    }
    // If there's no hyphen or if the last segment is not the expected length, return the full string as a fallback
    return this;
  }
}
