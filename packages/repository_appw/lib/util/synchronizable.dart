import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' hide Log, Preferences;
import 'package:log/log.dart';
import 'package:repository/database/preferences.dart';

mixin AppwriteSynchronizable<T> {
  bool _online = false;
  DateTime? lastFetch;
  late Preferences _prefs;
  String _userId = '';
  String _syncKey = '';
  String _tag = '';
  Future<void> Function(bool online)? onConnectivityChange;

  bool get online => _online;
  String get userId => _userId;

  void constructSynchronizable(String tag, Preferences prefs,
      {Future<void> Function(bool online)? onConnectivityChange}) {
    this._tag = tag;
    this._syncKey = '$tag.lastSync';
    this._prefs = prefs;
    this.onConnectivityChange = onConnectivityChange;

    int? lastSyncMillis = prefs.getInt(_syncKey);
    if (lastSyncMillis != null) {
      lastFetch = DateTime.fromMillisecondsSinceEpoch(lastSyncMillis);
    }
  }

  // Convert a document list to a list of <T>.
  List<T> documentsToList(DocumentList documents);

  Future<void> fetch() async {
    if (!_online) return;

    final timer = Log.timerStart();
    List<T> allItems = await _loadAllFromRemote();

    replaceState(allItems); // Replace the current state with the fetched items.

    Log.timerEnd(timer, '$_tag: Fetch completed in \$seconds seconds.');
    _updateSyncTime();
  }

  // Get all documents that match the given queries.
  Future<DocumentList> getDocuments(List<String> queries);

  // Get all documents that have been modified since the last fetch.
  Future<DocumentList> getModifiedDocuments(DateTime? lastSyncTime);

  Future<void> handleConnectionChange(bool online, Session? session) async {
    if (online && session != null) {
      _online = true;
      _userId = session.userId;

      if (onConnectivityChange != null) {
        await onConnectivityChange!(online);
      }

      await fetch();
    } else {
      _online = false;
      _userId = '';
    }
  }

  // Abstract method to merge a list of new items into the current state.
  void mergeState(List<T> newItems);

  // Abstract method to replace the current state with new items.
  void replaceState(List<T> allItems);

  Future<void> syncModified() async {
    if (!_online) return;
    final timer = Log.timerStart();

    try {
      // Get all items that have been modified since the last fetch.
      DocumentList response = await getModifiedDocuments(lastFetch);
      List<T> changedItems = documentsToList(response);

      // Merge all changed items into the current state.
      mergeState(changedItems);
    }

    // An error occurred while syncing. Log the error and continue.
    on AppwriteException catch (e) {
      Log.e('$_tag: Error while syncing modifications: $e');
    }

    Log.timerEnd(timer, '$_tag: Modified item fetch completed in \$seconds seconds.');
    _updateSyncTime();
  }

  Future<List<T>> _loadAllFromRemote() async {
    String? cursor;
    List<T> allItems = [];

    DocumentList response;

    do {
      List<String> queries = [Query.limit(100)];

      if (cursor != null) {
        queries.add(Query.cursorAfter(cursor));
      }

      response = await getDocuments(queries);

      final items = documentsToList(response);
      allItems.addAll(items);

      if (response.documents.isNotEmpty) {
        cursor = response.documents.last.$id;
      }
    } while (response.documents.isNotEmpty);

    return allItems;
  }

  void _updateSyncTime() {
    lastFetch = DateTime.now();
    _prefs.setInt(_syncKey, lastFetch!.millisecondsSinceEpoch);
  }
}
