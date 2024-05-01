// ignore_for_file: undefined_identifier,undefined_class,undefined_getter,undefined_setter
List<String> get dbExpirationDates {
  List<String> dates = [];
  for (final exp in expirationDates) {
    dates.add(exp.millisecondsSinceEpoch.toString());
  }

  return dates;
}

set dbExpirationDates(List<String> dates) {
  expirationDates.clear();

  for (final date in dates) {
    int? timestamp = int.tryParse(date);

    if (timestamp != null) {
      expirationDates.add(DateTime.fromMillisecondsSinceEpoch(timestamp));
    }
  }
}

int get dbLastUpdate {
  return updated.millisecondsSinceEpoch;
}

set dbLastUpdate(int value) {
  updated = DateTime.fromMillisecondsSinceEpoch(value);
}
