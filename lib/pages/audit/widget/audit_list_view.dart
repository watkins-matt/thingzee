import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/audit/state/task.dart';

class AuditListView extends ConsumerWidget {
  const AuditListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskManagerProvider);
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(tasks[index].name),
          subtitle: Text('Quantity: ${tasks[index].quantity}'),
          trailing: tasks[index].isComplete ? const Icon(Icons.check, color: Colors.green) : null,
          onTap: () => ref.read(taskManagerProvider.notifier).completeTask(index),
        );
      },
    );
  }
}
