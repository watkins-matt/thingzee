import 'package:hooks_riverpod/hooks_riverpod.dart';

final inventoryDisplayProvider = StateNotifierProvider<InventoryDisplay, InventoryDisplayState>(
  (ref) => InventoryDisplay(),
);

class InventoryDisplay extends StateNotifier<InventoryDisplayState> {
  InventoryDisplay() : super(InventoryDisplayState());

  bool get displayImages => state.displayImages;
  set displayImages(bool value) {
    state = state.copyWith(displayImages: value);
  }
}

class InventoryDisplayState {
  final bool displayImages;

  InventoryDisplayState({this.displayImages = true});

  InventoryDisplayState copyWith({bool? displayImages}) {
    return InventoryDisplayState(
      displayImages: displayImages ?? this.displayImages,
    );
  }
}
