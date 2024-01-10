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
  return lastUpdate != null ? lastUpdate!.millisecondsSinceEpoch : 0;
}

set dbLastUpdate(int value) {
  lastUpdate = value != 0 ? DateTime.fromMillisecondsSinceEpoch(value) : null;
}

String get upc => _upc;

set upc(String value) {
  _upc = value;
  history = history.copyWith(upc: value);
}
