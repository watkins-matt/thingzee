import 'package:repository/database/audit_task_database.dart';
import 'package:repository/database/history_database.dart';
import 'package:repository/database/household_database.dart';
import 'package:repository/database/identifier_database.dart';
import 'package:repository/database/inventory_database.dart';
import 'package:repository/database/item_database.dart';
import 'package:repository/database/location_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/database/receipt_database.dart';
import 'package:repository/database/shopping_list_database.dart';

abstract class Repository {
  bool ready = false;
  late ItemDatabase items;
  late InventoryDatabase inv;
  late HistoryDatabase hist;
  late Preferences prefs;
  late Preferences securePrefs;
  late HouseholdDatabase household;
  late LocationDatabase location;
  late IdentifierDatabase identifiers;
  late ShoppingListDatabase shopping;
  late ReceiptItemDatabase receiptItems;
  late ReceiptDatabase receipts;
  late AuditTaskDatabase audits;

  bool get isMultiUser => false;
  bool get isUserVerified => false;
  bool get loggedIn => false;
}
