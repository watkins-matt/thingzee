import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/main.dart';

class AsyncInitializer extends StatefulWidget {
  final Widget child;
  const AsyncInitializer({super.key, required this.child});

  @override
  State<AsyncInitializer> createState() => _AsyncInitializerState();
}

class _AsyncInitializerState extends State<AsyncInitializer> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final container = ProviderScope.containerOf(context);

      // Trigger the providers without waiting for them,
      // resulting in them loading eagerly instead of lazily
      container.read(connectivityProvider);
      container.read(cloudRepoProvider.future);
      container.read(syncServiceProvider);
    });
  }
}
