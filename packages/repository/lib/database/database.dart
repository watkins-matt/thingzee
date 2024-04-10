import 'package:repository/model/abstract/model.dart';
import 'package:uuid/uuid.dart';

typedef OperationHook<T> = void Function(T? item, String type);

abstract class Database<T extends Model> {
  List<Database<T>> replicas = [];
  String? replicationId;
  List<OperationHook<T>> hooks = [];

  void addHook(OperationHook<T> hook) => hooks.add(hook);
  List<T> all();

  Future<void> callHooks(T? item, String type) async {
    // Convert each hook call to a future using Future.microtask
    var futures = hooks.map((hook) => Future.microtask(() => hook(item, type)));

    // Wait for all hook-invoked futures to complete
    await Future.wait(futures);
  }

  void delete(T item);
  void deleteAll();
  void deleteById(String id);
  T? get(String id);
  List<T> getAll(List<String> ids);
  List<T> getChanges(DateTime since);
  bool has(String id) => get(id) != null;
  Map<String, T> map();

  void put(T item);

  /// Replicates the given operation to all replicas, preventing circular replication.
  Future<void> replicateOperation(Future<void> Function(Database<T>) operation) async {
    if (replicas.isEmpty) return;

    // Initialize replicationId only if it's not set, indicating this is the originating call
    final isNewOperation = replicationId == null;
    replicationId ??= const Uuid().v4();

    // Perform the operation on all replicas, passing the replicationId to each
    List<Future<void>> tasks = replicas.map((replica) {
      // Avoid circular replication by not proceeding if the replica's replicationId matches
      if (replica.replicationId == replicationId) return Future.value();

      // Temporarily set the replica's replicationId to prevent potential loops from further replicas
      replica.replicationId = replicationId;

      // Perform the given operation
      return operation(replica);
    }).toList();

    // Wait for all tasks to complete
    await Future.wait(tasks);

    // Reset the replicationId if this call originated the operation
    if (isNewOperation) {
      replicationId = null;

      // Also clear the operation ID in replicas to allow future operations
      for (final replica in replicas) {
        replica.replicationId = null;
      }
    }
  }

  void replicateTo(Database<T> other) => replicas.add(other);
}

class DatabaseHookType {
  static const String put = 'update';
  static const String delete = 'delete';
  static const String deleteAll = 'deleteAll';
}
