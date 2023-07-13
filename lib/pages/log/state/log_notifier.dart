import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:log/log.dart';
import 'package:logger/logger.dart';

final logsProvider =
    StateNotifierProvider.autoDispose<LogNotifier, List<OutputEvent>>((ref) => LogNotifier());

class LogNotifier extends StateNotifier<List<OutputEvent>> {
  LogNotifier() : super(Log.logs) {
    Log.addOutputListener(_updateLogs);
  }

  @override
  void dispose() {
    Log.removeOutputListener(_updateLogs);
    super.dispose();
  }

  void _updateLogs(OutputEvent event) {
    state = List.from(Log.logs);
  }
}
