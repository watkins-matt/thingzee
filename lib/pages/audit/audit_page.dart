import 'package:flutter/material.dart';
import 'package:flutter_rounded_progress_bar/flutter_rounded_progress_bar.dart';
import 'package:flutter_rounded_progress_bar/rounded_progress_bar_style.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/audit/state/task.dart';
import 'package:thingzee/pages/audit/widget/audit_list_view.dart';
import 'package:thingzee/pages/audit/widget/selection_widget.dart';

class AuditPage extends ConsumerWidget {
  const AuditPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskManagerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit'),
      ),
      body: Column(
        children: [
          const Expanded(child: AuditListView()),
          RoundedProgressBar(
            style: RoundedProgressBarStyle(colorBorder: Theme.of(context).cardColor),
            percent: (tasks.where((t) => t.isComplete).length / tasks.length) * 100,
          ),
          const SelectionWidget(),
        ],
      ),
    );
  }
}
