abstract class ObjectBoxModel<T> {
  DateTime? get created;
  int get objectBoxId;
  set objectBoxId(int id);
  DateTime? get updated;
  T convert();
}
