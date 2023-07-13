import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:thingzee/pages/log/state/log_notifier.dart';

class LogViewerPage extends ConsumerStatefulWidget {
  const LogViewerPage({super.key});

  @override
  ConsumerState<LogViewerPage> createState() => _LogViewerPageState();

  static Future<void> push(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LogViewerPage()),
    );
  }
}

class _LogViewerPageState extends ConsumerState<LogViewerPage> {
  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(logsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Viewer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: SelectableText.rich(
          TextSpan(
            children: logs.map((log) {
              final timeString = DateFormat('yyyy-MM-dd hh:mm:ss a').format(log.origin.time);
              var message = _removeAnsiColorCodes(log.lines.join('\n'));
              message = message.replaceFirst(timeString, '').trim();

              return TextSpan(
                children: [
                  TextSpan(
                    text: '$timeString ',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  TextSpan(
                    text: message,
                    style: TextStyle(color: _getColor(log.origin.level)),
                  ),
                  const TextSpan(text: '\n'),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Color _getColor(Level level) {
    switch (level) {
      case Level.verbose:
        return Colors.blue;
      case Level.debug:
        return Colors.green;
      case Level.info:
        return Colors.lightBlue;
      case Level.warning:
        return Colors.orange;
      case Level.error:
        return Colors.red;
      case Level.wtf:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _removeAnsiColorCodes(String text) {
    final ansiColorCodeRegex = RegExp('\x1B\\[[0-?]*[ -/]*[@-~]');
    return text.replaceAll(ansiColorCodeRegex, '');
  }
}
