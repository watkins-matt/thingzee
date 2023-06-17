import 'package:repository/repository.dart';

abstract class CsvExporter {
  List<String> get headers;
  Future<String> export(Repository r);
}
