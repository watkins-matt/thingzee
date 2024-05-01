import 'package:hooks_riverpod/hooks_riverpod.dart';

final taskManagerProvider = StateNotifierProvider<TaskManager, List<Task>>((ref) {
  return TaskManager();
});

class Task {
  final String name;
  double quantity;
  bool isComplete;
  Task({required this.name, required this.quantity, this.isComplete = false});
}

class TaskManager extends StateNotifier<List<Task>> {
  TaskManager() : super([]);

  void completeTask(int index) {
    var updatedTasks = state;
    updatedTasks[index].isComplete = true;
    state = [...updatedTasks];
  }

  void loadTasks() {
    state = [
      // Task(name: 'Item 1', quantity: 10),
      // Task(name: 'Item 2', quantity: 20),
      // Task(name: 'Item 3', quantity: 30),
    ];
  }

  void updateTaskQuantity(int index, double newQuantity) {
    var updatedTasks = state;
    updatedTasks[index].quantity = newQuantity;
    state = [...updatedTasks];
  }
}
