import 'package:repository/database/database.dart';
import 'package:repository/model/receipt.dart';
import 'package:repository/model/receipt_item.dart';

abstract class ReceiptDatabase extends Database<Receipt> {}

abstract class ReceiptItemDatabase extends Database<ReceiptItem> {}
