import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/database/joined_item_database.dart';
import 'package:repository/model/location.dart';
import 'package:repository/repository.dart';
import 'package:thingzee/main.dart';

final locationViewProvider = StateNotifierProvider<LocationViewState, LocationState>((ref) {
  final repo = ref.watch(repositoryProvider);
  return LocationViewState(repo);
});

class LocationState {
  final String currentDirectory;
  final List<String> subPaths;
  final List<JoinedItem> currentItems;

  LocationState({
    required this.currentDirectory,
    required this.subPaths,
    required this.currentItems,
  });

  LocationState copyWith({
    String? currentDirectory,
    List<String>? subPaths,
    List<JoinedItem>? currentItems,
  }) {
    return LocationState(
      currentDirectory: currentDirectory ?? this.currentDirectory,
      subPaths: subPaths ?? this.subPaths,
      currentItems: currentItems ?? this.currentItems,
    );
  }
}

class LocationViewState extends StateNotifier<LocationState> {
  final Repository r;
  final JoinedItemDatabase items;
  final List<String> backStack = [];
  final List<String> forwardStack = [];
  final int maxStackSize = 50;

  LocationViewState(this.r)
      : items = JoinedItemDatabase(r.items, r.inv),
        super(LocationState(currentDirectory: '/', subPaths: [], currentItems: [])) {
    refresh();
  }

  void back() {
    if (backStack.isNotEmpty) {
      _addToStack(forwardStack, state.currentDirectory);
      String lastDir = backStack.removeLast();
      changeDirectory(lastDir, addToBackStack: false);
    }
  }

  void changeDirectory(String newDirectory, {bool addToBackStack = true}) {
    String currentDir = state.currentDirectory;

    // Treat empty current directory the same as root
    if (currentDir.isEmpty) {
      currentDir = '/';
    }

    // Handle relative paths by appending to the current directory
    if (!newDirectory.startsWith('/')) {
      if (currentDir.endsWith('/')) {
        currentDir += newDirectory;
      } else {
        currentDir += '/$newDirectory';
      }
    } else {
      currentDir = newDirectory;
    }

    // Normalize the resulting path
    currentDir = normalizeLocation(currentDir);

    // Add the current directory to the back stack
    if (addToBackStack) {
      _addToStack(backStack, state.currentDirectory);
    }

    final subPaths = r.location.getSubPaths(currentDir);
    final upcList = r.location.getUpcList(currentDir);
    final joinedItems = items.getAll(upcList);

    state = state.copyWith(
      currentDirectory: currentDir,
      subPaths: subPaths,
      currentItems: joinedItems,
    );
  }

  void forward() {
    if (forwardStack.isNotEmpty) {
      _addToStack(backStack, state.currentDirectory);
      String nextDir = forwardStack.removeLast();
      changeDirectory(nextDir, addToBackStack: false);
    }
  }

  void refresh() {
    final subPaths = r.location.getSubPaths(state.currentDirectory);
    final upcList = r.location.getUpcList(state.currentDirectory);
    final joinedItems = items.getAll(upcList);

    state = state.copyWith(
      subPaths: subPaths,
      currentItems: joinedItems,
    );
  }

  void _addToStack(List<String> stack, String item) {
    if (stack.length >= maxStackSize) {
      stack.removeAt(0);
    }
    stack.add(item);
  }
}
