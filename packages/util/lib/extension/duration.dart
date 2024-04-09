import 'package:duration/duration.dart';

extension DurationPrettyPrint on Duration {
  String toHumanReadableString() {
    return prettyDuration(this, tersity: DurationTersity.minute, delimiter: ', ');
  }
}
