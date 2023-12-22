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

  void updateItem(int index, ReceiptItem newItem) {
    state = state.copyAndReplaceItem(index, newItem);
  }

  void updateSubtotal(double newSubtotal) {
    state = state.copyWith(subtotal: newSubtotal);
  }
}
