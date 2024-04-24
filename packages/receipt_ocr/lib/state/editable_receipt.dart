import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:receipt_parser/model/receipt.dart';
import 'package:receipt_parser/model/receipt_item.dart';

final editableReceiptProvider = StateNotifierProvider<EditableReceipt, ParsedReceipt>(
  (ref) => EditableReceipt(ParsedReceipt(items: const [], date: DateTime.now())),
);

class EditableReceipt extends StateNotifier<ParsedReceipt> {
  EditableReceipt(super.state);

  void copyFrom(ParsedReceipt receipt) {
    state = receipt;
  }

  void deleteItem(int index) {
    List<ParsedReceiptItem> newItems = List<ParsedReceiptItem>.from(state.items);
    if (index >= 0 && index < newItems.length) {
      newItems.removeAt(index);
      state = state.copyWith(items: newItems);
    }
  }

  void insertItem(int index, ParsedReceiptItem newItem) {
    // Ensure the index is within the bounds of the list
    index = index.clamp(0, state.items.length);

    // Create a new list of items with the new item inserted
    List<ParsedReceiptItem> newItems = List<ParsedReceiptItem>.from(state.items)
      ..insert(index, newItem);

    // Update the state with the new list of items
    state = state.copyWith(items: newItems);
  }

  void updateDate(DateTime newDate) {
    state = state.copyWith(date: newDate);
  }

  void updateItem(int index, ParsedReceiptItem newItem) {
    state = state.copyAndReplaceItem(index, newItem);
  }

  void updateSubtotal(double newSubtotal) {
    state = state.copyWith(subtotal: newSubtotal);
  }
}
