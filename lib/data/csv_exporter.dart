import 'package:repository/repository.dart';

abstract class CSVExporter {
  List<String> get headers;
  Future<String> export(Repository r);
}
