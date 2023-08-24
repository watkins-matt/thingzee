import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/model/location.dart';
import 'package:repository/repository.dart';
import 'package:thingzee/main.dart';

final locationViewProvider = StateNotifierProvider<LocationViewState, LocationState>((ref) {
  final repo = ref.watch(repositoryProvider);
  return LocationViewState(repo);
});

class LocationState {
  final String currentDirectory;
  final List<Location> contents;

  LocationState({required this.currentDirectory, required this.contents});

  LocationState copyWith({
    String? currentDirectory,
    List<Location>? contents,
  }) {
    return LocationState(
      currentDirectory: currentDirectory ?? this.currentDirectory,
      contents: contents ?? this.contents,
    );
  }
}

class LocationViewState extends StateNotifier<LocationState> {
  final Repository r;

  LocationViewState(this.r) : super(LocationState(currentDirectory: '', contents: [])) {
    refresh();
  }

  Future<void> changeDirectory(String newDirectory) async {
    final contents = r.location.getContents(newDirectory);
    state = state.copyWith(
      currentDirectory: newDirectory,
      contents: contents,
    );
  }

  Future<void> refresh() async {
    // Refresh current directory contents
    final contents = r.location.getContents(state.currentDirectory);
    if (state.currentDirectory.isEmpty) {
      state = state.copyWith(contents: r.location.all());
      return;
    }

    state = state.copyWith(contents: contents);
  }
}
