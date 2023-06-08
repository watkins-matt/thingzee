class Product implements Comparable<Product> {
  String name = '';
  String puid = '';

  String manufacturer = '';
  String muid = '';
  String category = '';
  List<String> upcs = <String>[];

  @override
  int compareTo(Product other) {
    return name.compareTo(other.name);
  }
}
