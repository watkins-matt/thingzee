T enumFromIndex<T>(List<T> values, int? index, T defaultValue) {
  if (index != null && index >= 0 && index < values.length) {
    return values[index];
  }
  return defaultValue;
}
