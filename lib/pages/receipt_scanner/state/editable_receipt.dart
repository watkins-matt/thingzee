import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/model/receipt.dart';

final editableReceiptProvider = StateNotifierProvider<EditableReceipt, Receipt>(
  (ref) => EditableReceipt(Receipt(items: const [], date: DateTime.now())),
);

class EditableReceipt extends StateNotifier<Receipt> {
  EditableReceipt(super.state);

  void copyFrom(Receipt receipt) {
    state = receipt;
  }

  void deleteItem(int index) {
    List<ReceiptItem> newItems = List<ReceiptItem>.from(state.items);
    if (index >= 0 && index < newItems.length) {
      newItems.removeAt(index);
      state = state.copyWith(items: newItems);
    }
  }

  void insertItem(int index, ReceiptItem newItem) {
    // Ensure the index is within the bounds of the list
    index = index.clamp(0, state.items.length);

    // Create a new list of items with the new item inserted
    List<ReceiptItem> newItems = List<ReceiptItem>.from(state.items)..insert(index, newItem);

    // Update the state with the new list of items
    state = state.copyWith(items: newItems);
  }

  void updateItem(int index, ReceiptItem newItem) {
    state = state.copyAndReplaceItem(index, newItem);
  }

  void updateSubtotal(double newSubtotal) {
    state = state.copyWith(subtotal: newSubtotal);
  }
}
