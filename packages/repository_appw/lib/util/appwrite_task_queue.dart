import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:log/log.dart';

class AppwriteTaskQueue {
  static const maxRetries = 3;
  final List<_QueueTask> _taskQueue = [];
  bool _processingQueue = false;
  DateTime? _lastRateLimitHit;
  bool _paused = false;

  int get length => _taskQueue.length;
  bool get paused => _paused;
  bool get processing => _processingQueue;

  void pause() {
    _paused = true;
  }

  void queueTask(Future<void> Function() operation) {
    _taskQueue.add(_QueueTask(operation));

    if (!_paused) {
      scheduleMicrotask(_processQueue);
    }
  }

  void resume() {
    if (_paused) {
      _paused = false;
      scheduleMicrotask(_processQueue);
    }
  }

  void run() {
    if (!_paused) {
      scheduleMicrotask(_processQueue);
    }
  }

  Future<void> runUntilComplete() async => await _processQueue();

  Future<void> _processQueue() async {
    if (_processingQueue || _paused) {
      return;
    }
    _processingQueue = true;

    try {
      while (!_paused && _taskQueue.isNotEmpty) {
        if (_lastRateLimitHit != null) {
          final difference = DateTime.now().difference(_lastRateLimitHit!);
          if (difference < const Duration(minutes: 1)) {
            final timeToWait = const Duration(minutes: 1) - difference;
            await Future.delayed(timeToWait);
            _lastRateLimitHit = null;
          }
        }

        _QueueTask task = _taskQueue.removeAt(0);

        if (task.retries >= maxRetries) {
          Log.e('Failed to execute task after $maxRetries attempts.');
          continue;
        }

        try {
          await task.operation();
        } on AppwriteException catch (e) {
          if (e.code == 429) {
            Log.e('Rate limit hit. Pausing queue processing.');
            _lastRateLimitHit = DateTime.now();
            _taskQueue.insert(0, task);
          } else {
            Log.e(
                'Failed to execute task (Retry attempt ${task.retries + 1}): [AppwriteException] ${e.message}');
            task.retries += 1;
            _taskQueue.insert(0, task);
          }
        }
      }
    } finally {
      _processingQueue = false;
    }
  }
}

class _QueueTask {
  final Future<void> Function() operation;
  int retries = 0;

  _QueueTask(this.operation);
}
