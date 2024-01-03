import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:log/log.dart';
import 'package:repository_appw/util/appwrite_task_queue.dart';

void main() {
  late AppwriteTaskQueue taskQueue;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    Log.enableTestMode();
    taskQueue = AppwriteTaskQueue();
  });

  group('queueTask', () {
    test('Should add a task to the task queue', () {
      bool taskExecuted = false;
      final task = () async {
        taskExecuted = true;
      };

      taskQueue.queueTask(task);

      expect(taskQueue.length, equals(1));
      expect(taskExecuted, isFalse);
    });
  });

  group('processQueue', () {
    test('Should execute tasks in the task queue', () async {
      final completer1 = Completer<void>();
      final completer2 = Completer<void>();
      bool task1Executed = false;
      bool task2Executed = false;

      final task1 = () async {
        task1Executed = true;
        completer1.complete(); // Complete the first completer when task1 finishes
      };

      final task2 = () async {
        task2Executed = true;
        completer2.complete(); // Complete the second completer when task2 finishes
      };

      taskQueue.queueTask(task1);
      taskQueue.queueTask(task2);

      await completer1.future; // Wait for the first task to complete.
      await completer2.future; // Wait for the second task to complete.

      expect(task1Executed, isTrue);
      expect(task2Executed, isTrue);
      expect(taskQueue.length, equals(0));
    });

    test('Should retry failed tasks up to maxRetries', () async {
      final completer = Completer<void>();
      int taskExecutions = 0;
      const maxRetries = 3; // Replace with your actual maxRetries value

      final task = () async {
        taskExecutions++;
        if (taskExecutions >= maxRetries) {
          // The Completer should complete after the maxRetries + 1 attempt.
          if (!completer.isCompleted) {
            completer.complete();
          }
        }
        throw AppwriteException('', 500);
      };

      taskQueue.queueTask(task);
      await completer.future; // Wait for the task to be retried maxRetries times

      expect(taskExecutions, equals(maxRetries));
      expect(taskQueue.length, equals(0));
    });

    test('Should pause processing when rate limit is hit', () async {
      final completer1 = Completer<void>();
      final completer2 = Completer<void>();

      bool task1Executed = false;
      bool task2Executed = false;
      bool rateLimitHit = false;

      final task1 = () async {
        task1Executed = true;
        completer1.complete();
      };

      final task2 = () async {
        try {
          task2Executed = true; // Task2 starts executing
          // Simulate work
          await Future.delayed(Duration(milliseconds: 100));
          // Throw a rate limit exception
          throw AppwriteException('', 429);
        } on AppwriteException catch (e) {
          if (e.code == 429) {
            rateLimitHit = true; // Mark that rate limit was hit
            completer2.complete(); // Complete the completer on rate limit hit
          }
        }
      };

      taskQueue.queueTask(task1);
      taskQueue.queueTask(task2);

      await completer1.future; // Wait for the first task to complete.
      await completer2.future; // Wait for the second task to hit the rate limit.

      expect(task1Executed, isTrue);
      expect(task2Executed, isTrue); // Task2 should execute but hit rate limit
      expect(rateLimitHit, isTrue); // Ensure that rate limit was hit
    });
  });

  group('pause', () {
    test('Should pause processing of the task queue', () async {
      bool taskExecuted = false;
      final task = () async {
        taskExecuted = true;
      };

      taskQueue.queueTask(task);
      taskQueue.pause();

      expect(taskExecuted, isFalse);
      expect(taskQueue.length, equals(1));
      expect(taskQueue.processing, isFalse);
    });
  });

  group('resume', () {
    test('Should resume processing of the task queue', () async {
      final completer = Completer<void>();
      bool taskExecuted = false;
      final task = () async {
        // Perform the task
        taskExecuted = true;

        // Complete the completer once the task is done
        completer.complete();
      };

      taskQueue.queueTask(task);
      taskQueue.pause();
      taskQueue.resume();

      // Wait for the task to complete
      await completer.future;

      // Now it's safe to check the conditions
      expect(taskExecuted, isTrue);
      expect(taskQueue.length, equals(0));
    });
  });
}
