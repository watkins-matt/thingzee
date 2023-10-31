class Product implements Comparable<Product> {
  String name = '';
  String uid = '';

  String manufacturer = '';
  String manufacturerUid = '';
  String category = '';
  List<String> upcs = <String>[];

  @override
  int compareTo(Product other) {
    return name.compareTo(other.name);
  }
}
