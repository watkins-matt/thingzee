import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:log/platform/platform.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:stack_trace/stack_trace.dart';

class Log {
  static final StoredLogOutput _output = StoredLogOutput(printMethod: PrintMethod.debugPrint);
  static Logger _logger = Logger(printer: TimeDisplaySimplePrinter(), output: _output);
  static List<OutputEvent> get logs => _output.logs;
  Log._();

  static void addLogListener(LogCallback callback) {
    Logger.addLogListener(callback);
  }

  static void addOutputListener(OutputCallback callback) {
    Logger.addOutputListener(callback);
  }

  static void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  // Ensure that we are not trying to write files in unit tests
  static void enableTestMode() {
    _logger = Logger(printer: TimeDisplaySimplePrinter(), output: ConsoleOutput());
  }

  static void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  static void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  static bool removeLogListener(LogCallback callback) {
    return Logger.removeLogListener(callback);
  }

  static void removeOutputListener(OutputCallback callback) {
    Logger.removeOutputListener(callback);
  }

  static void t(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  static void timerEnd(Stopwatch stopwatch, String message) {
    stopwatch.stop();
    var seconds = stopwatch.elapsedMilliseconds / 1000;
    var finalMessage = message.replaceAll('\$seconds', seconds.toStringAsFixed(2));
    _logger.i(finalMessage);
  }

  static void timerShow(Stopwatch stopwatch, String message) {
    var seconds = stopwatch.elapsedMilliseconds / 1000;
    var finalMessage = message.replaceAll('\$seconds', seconds.toStringAsFixed(2));
    _logger.i(finalMessage);
  }

  static Stopwatch timerStart([String message = '']) {
    if (message.isNotEmpty) {
      _logger.i(message);
    }
    var stopwatch = Stopwatch()..start();
    return stopwatch;
  }

  static void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }
}

enum PrintMethod {
  console,
  debugPrint,
  developerLog,
}

class StoredLogOutput extends LogOutput {
  final Queue<OutputEvent> logsToWrite = Queue();
  final List<OutputEvent> logs = [];
  final PrintMethod printMethod;
  final Duration writeInterval;
  final int daysToKeepLogs;
  String? _currentDate;
  File? _logFile;

  StoredLogOutput({
    this.printMethod = PrintMethod.console,
    this.writeInterval = const Duration(minutes: 1),
    this.daysToKeepLogs = 14,
  }) {
    Timer.periodic(writeInterval, (timer) => _writeLogsToFile());
    _chooseLogFile();
  }

  @override
  void output(OutputEvent event) {
    logsToWrite.add(event);
    logs.add(event);
    switch (printMethod) {
      case PrintMethod.console:
        // ignore: avoid_print
        event.lines.forEach(print);
        break;
      case PrintMethod.debugPrint:
        event.lines.forEach(platformDebugPrint);
        break;
      case PrintMethod.developerLog:
        event.lines.forEach(developer.log);
        break;
    }
  }

  Future<void> _chooseLogFile() async {
    if (kIsWeb) return; // Can't write files on web

    // Get the log directory
    final logPath = await getLogDirectoryPath();

    // If the directory is null, we can't write logs
    if (logPath == null || logPath.isEmpty) {
      _logFile = null;
      return;
    }

    final logDirectoryPath = path.join(logPath, 'logs');
    final logDirectory = Directory(logDirectoryPath);

    // Create if it doesn't exist
    if (!logDirectory.existsSync()) {
      await logDirectory.create();
    }

    // Get the current date
    _currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final logFilePath = path.join(logDirectoryPath, '$_currentDate.txt');

    // Update the current log file
    _logFile = File(logFilePath);
  }

  Future<void> _deleteOldLogs() async {
    if (kIsWeb) return; // Can't write files on web

    // Find the default log directory
    final logPath = await getLogDirectoryPath();

    // If the directory is null, we can't write logs
    if (logPath == null || logPath.isEmpty) {
      return;
    }

    final logDirectoryPath = path.join(logPath, 'logs');
    final logDirectory = Directory(logDirectoryPath);

    // Find the expiration date
    final expiryDate = DateTime.now().subtract(Duration(days: daysToKeepLogs));
    final files = logDirectory.listSync();

    // Delete the old log files
    for (final file in files) {
      if (file is File) {
        // Get the name without extension
        final fileName = path.basenameWithoutExtension(file.path);
        try {
          // Parse the date from the file name
          final fileDate = DateFormat('yyyy-MM-dd').parse(fileName);

          // Delete the file if it's older than the expiration date
          if (fileDate.isBefore(expiryDate)) {
            await file.delete();
          }
        } catch (e) {
          if (e is FormatException) {
            // If the file name doesn't match the expected format, ignore this file
            continue;
          } else {
            rethrow;
          }
        }
      }
    }
  }

  Future<void> _writeLogsToFile() async {
    if (logsToWrite.isEmpty || kIsWeb) return;
    final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // If the log file is null or the date changed, update the log file
    if (_logFile == null || currentDate != _currentDate) {
      await _chooseLogFile();
      // Remove old logs only when the date changes or the first time
      await _deleteOldLogs();
    }

    // Append the logs to the file
    if (_logFile != null) {
      final logLines = logsToWrite.map((e) {
        final joinedLines = e.lines.join('\n');
        // Remove escape codes
        final cleanLines = joinedLines.replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '');
        return cleanLines;
      }).join('\n');
      await _logFile!.writeAsString(logLines, mode: FileMode.append);
      logsToWrite.clear();
    }
  }
}

class TimeDisplaySimplePrinter extends SimplePrinter {
  static final levelPrefixes = {
    Level.trace: '[TRA]',
    Level.debug: '[DEB]',
    Level.info: '[INF]',
    Level.warning: '[WRN]',
    Level.error: '[ERR]',
    Level.fatal: '[FATAL]',
  };

  @override
  List<String> log(LogEvent event) {
    final timeString = DateFormat('yyyy-MM-dd hh:mm:ss a').format(event.time);

    final color = SimplePrinter.levelColors[event.level]!;
    final prefix = levelPrefixes[event.level]!;

    final errorText = _errorText(event);
    final message = messageToString(event.message);
    final result = timeString + color(' $prefix $message $errorText'.trimRight());

    return [result];
  }

  String messageToString(dynamic message) {
    if (message is Function) {
      message = message();
    }

    if (message is Map || message is Iterable) {
      return JsonEncoder.withIndent('  ').convert(message);
    } else {
      return message.toString();
    }
  }

  String _errorText(LogEvent event, {int maxFrameCount = 5}) {
    if (event.error == null) return '';
    if (event.stackTrace == null) return event.error.toString();

    final chain = Chain.forTrace(event.stackTrace!);
    final terseChain = chain.terse;

    final frames = terseChain.traces.first.frames;
    final limitedFrames = frames.take(maxFrameCount);
    final limitedChain = Chain([Trace(limitedFrames)]);

    return '${event.error}\n$limitedChain';
  }
}
