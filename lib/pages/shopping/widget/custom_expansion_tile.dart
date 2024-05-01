import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Assuming each tile can be uniquely identified by an `id`
final expansionStateProvider = StateProvider.family<bool, String>((ref, id) => false);

class CustomExpansionTile extends HookConsumerWidget {
  final String id; // Unique identifier for each tile
  final Widget title;
  final List<Widget> children;

  const CustomExpansionTile({
    super.key,
    required this.id,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = ref.watch(expansionStateProvider(id));
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 200),
    );

    // Define animations
    final heightAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
    );
    final iconAnimation = Tween<double>(begin: 0, end: 0.25).animate(controller);

    // Effect to sync controller state with isExpanded
    useEffect(() {
      if (isExpanded) {
        controller.forward();
      } else {
        controller.reverse();
      }
      return null;
    }, [isExpanded]);

    void handleTap() {
      ref.read(expansionStateProvider(id).notifier).state = !isExpanded;
    }

    return InkWell(
      onTap: handleTap,
      child: Column(
        children: [
          ListTile(
            leading: AnimatedRotation(
              turns: iconAnimation.value,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.chevron_right),
            ),
            title: title,
          ),
          ClipRect(
            child: Align(
              alignment: Alignment.center,
              heightFactor: heightAnimation.value,
              child: Column(
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
