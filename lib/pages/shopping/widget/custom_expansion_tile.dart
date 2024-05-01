import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final expansionStateProvider = StateProvider<Map<String, bool>>((ref) => {});

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
    // Retrieve the expansion state for this specific tile
    final expansionStateMap = ref.watch(expansionStateProvider);
    final isExpanded = useState(expansionStateMap[id] ?? false);

    final controller = useAnimationController(
      duration: const Duration(milliseconds: 200),
    );

    // Animation synchronization and controller setup
    useEffect(() {
      controller.value = isExpanded.value ? 1.0 : 0.0;
      if (isExpanded.value) {
        controller.forward();
      } else {
        controller.reverse();
      }
      return null;
    }, [isExpanded.value]);

    void handleTap() {
      isExpanded.value = !isExpanded.value; // Toggle local state

      // Update the global state map with the new expansion state
      ref.read(expansionStateProvider.notifier).update((state) => {
            ...state,
            id: isExpanded.value,
          });
    }

    final heightAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
    );
    final iconAnimation = Tween<double>(begin: 0, end: 0.25).animate(controller);

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
