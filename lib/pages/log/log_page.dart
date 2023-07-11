import 'package:flutter/material.dart';
import 'package:log/log.dart';
import 'package:logger/logger.dart';

class LogViewer extends StatefulWidget {
  const LogViewer({super.key});

  @override
  State<LogViewer> createState() => _LogViewerState();
}

class _LogViewerState extends State<LogViewer> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Viewer'),
      ),
      body: ListView.builder(
        itemCount: Log.logs.length,
        itemBuilder: (context, index) {
          final log = Log.logs[index];
          return Padding(
            padding: const EdgeInsets.all(8),
            child: SelectableText.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '[${log.origin.time}] ',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  TextSpan(
                    text: log.lines.join('\n'),
                    style: TextStyle(color: _getColor(log.origin.level)),
                  ),
                ],
              ),
            ),
          );
        },
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
}
