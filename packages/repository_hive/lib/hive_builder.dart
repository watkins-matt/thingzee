import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';

Builder hiveBuilder(BuilderOptions options) => HiveBuilder();

class HiveBuilder implements Builder {
  final Map<String, String> packageReplace = {'repository_hive': 'repository'};
  static int typeIdCounter = 0;

  @override
  final buildExtensions = const {
    '.dart': ['.hive.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    var library = await buildStep.inputLibrary;

    // This will hold the generated code.
    var buffer = StringBuffer();

    // Add necessary import statements.
    buffer.writeln("import 'package:hive/hive.dart';");

    // Get the relative path of the input file from the project root.
    final packageRelativePath = buildStep.inputId.path.replaceFirst('lib/', '');

    // Get the package name from the input ID.
    var packageName = buildStep.inputId.package;

    if (packageReplace.containsKey(packageName)) {
      packageName = packageReplace[packageName]!;
    }

    // Generate the package import statement using the packageName and packageRelativePath.
    buffer.writeln("import 'package:$packageName/$packageRelativePath';");

    // Copy over the import statements, converting any relative imports to package imports.
    for (final importElement in library.importedLibraries) {
      var uri = importElement.identifier;

      if (uri.contains('repository_hive')) {
        uri = uri.replaceFirst('repository_hive', 'repository');
      }

      if (uri.startsWith('package:') || uri.startsWith('dart:')) {
        // This is already a package import, so just copy it over.
        buffer.writeln("import '$uri';");
      } else {
        // This is a relative import, so convert it to a package import.
        var convertedUri = 'package:$packageName/$uri';
        buffer.writeln("import '$convertedUri';");
      }
    }

    // Generate the part statement
    var generatedFile = buildStep.inputId.path.split('/').last;
    generatedFile = generatedFile.replaceFirst('.dart', '.hive.g.dart');
    buffer.writeln("part '$generatedFile';");

    // Iterate over all the classes in the input library.
    for (final originalClass in library.definingCompilationUnit.classes) {
      buffer.write(_generateHiveClass(originalClass, typeIdCounter));
      typeIdCounter++;
    }

    // Write out the new asset.
    await buildStep.writeAsString(
        buildStep.inputId.changeExtension('.hive.dart'), buffer.toString());
  }

  String _generateHiveClass(ClassElement originalClass, int typeIdCounter) {
    // This will hold the generated code for a single class.
    var buffer = StringBuffer();

    // Write the Hive class declaration with the unique typeId.
    buffer.writeln('@HiveType(typeId: $typeIdCounter)');
    buffer.writeln('class Hive${originalClass.name} extends HiveObject {');

    // Write the Hive fields.
    var fieldIndex = 0;
    for (final field in originalClass.fields) {
      // Skip all properties
      if (field.setter == null) {
        continue;
      }

      buffer.writeln('  @HiveField($fieldIndex)');
      buffer
          .writeln('  late ${field.type.getDisplayString(withNullability: false)} ${field.name};');
      fieldIndex++;
    }

    // Write an unnamed constructor
    buffer.writeln('  Hive${originalClass.name}();');

    // Write a constructor that takes an instance of the original class.
    buffer.writeln('  Hive${originalClass.name}.from(${originalClass.name} original) {');
    for (final field in originalClass.fields) {
      if (field.setter != null) {
        buffer.writeln('    ${field.name} = original.${field.name};');
      }
    }
    buffer.writeln('  }');

    // Write the conversion methods.
    buffer.writeln('  ${originalClass.name} to${originalClass.name}() {');
    buffer.writeln('    return ${originalClass.name}()');
    for (final field in originalClass.fields) {
      if (field.setter != null) {
        buffer.writeln('      ..${field.name} = ${field.name}');
      }
    }
    buffer.writeln('    ;');
    buffer.writeln('  }');

    // Close the class declaration.
    buffer.writeln('}');

    return buffer.toString();
  }
}
