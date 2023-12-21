import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/model/receipt.dart';

final editableReceiptProvider = StateNotifierProvider<EditableReceipt, Receipt>(
  (ref) => EditableReceipt(Receipt(items: const [], date: DateTime.now())),
);

class EditableReceipt extends StateNotifier<Receipt> {
  EditableReceipt(super.state);

  void updateItem(int index, ReceiptItem newItem) {
    state = state.replaceItem(index, newItem);
  }
}
