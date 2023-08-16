import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';

Builder hiveBuilder(BuilderOptions options) => HiveBuilder();

class HiveBuilder implements Builder {
  final Map<String, String> packageReplace = {'repository_hive': 'repository'};
  final Map<String, int> typeIds = {
    'Inventory': 0,
    'Item': 1,
    'ItemTranslation': 2,
    'Manufacturer': 3,
    'Product': 4,
    'HouseholdMember': 5,
    'Location': 6,
    'ExpirationDate': 7,
    'History': 223
  };

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
      buffer.write(_generateHiveClass(originalClass));
    }

    // Write out the new asset.
    await buildStep.writeAsString(
        buildStep.inputId.changeExtension('.hive.dart'), buffer.toString());
  }

  String _generateHiveClass(ClassElement originalClass) {
    bool isImmutable = originalClass.fields.every((field) => field.isFinal);

    // This will hold the generated code for a single class.
    var buffer = StringBuffer();

    // Don't generate code for classes that don't have a typeId.
    if (!typeIds.containsKey(originalClass.name)) {
      print('No typeId for ${originalClass.name}, not generating code...');
      return '';
    }

    int typeId = typeIds[originalClass.name]!;

    // Write the Hive class declaration with the unique typeId.
    buffer.writeln('@HiveType(typeId: $typeId)');
    buffer.writeln('class Hive${originalClass.name} extends HiveObject {');

    // Write the Hive fields.
    var fieldIndex = 0;
    for (final field in originalClass.fields) {
      // Skip all properties
      if (field.setter == null && !field.isFinal) {
        continue;
      }

      buffer.writeln('  @HiveField($fieldIndex)');
      buffer.writeln('  late ${field.type.getDisplayString(withNullability: true)} ${field.name};');
      fieldIndex++;
    }

    // Write an unnamed constructor
    buffer.writeln('  Hive${originalClass.name}();');

    // Write a constructor that takes an instance of the original class.
    buffer.writeln('  Hive${originalClass.name}.from(${originalClass.name} original) {');
    for (final field in originalClass.fields) {
      if (field.isFinal || field.setter != null) {
        buffer.writeln('    ${field.name} = original.${field.name};');
      }
    }
    buffer.writeln('  }');

    // Write the conversion method
    buffer.writeln('  ${originalClass.name} to${originalClass.name}() {');

    // DO NOT REMOVE THE FOLLOWING. This code is necessary to ensure
    // that the history is in a consistent state.
    if (originalClass.name == 'Inventory') {
      buffer.writeln('    // Ensure history is in a consistent state');
      buffer.writeln('    history.upc = upc;');
    }

    if (isImmutable) {
      buffer.writeln('    return ${originalClass.name}(');
      for (final field in originalClass.fields) {
        if (field.isFinal) {
          buffer.write('      ${field.name}: ${field.name}');
          if (field != originalClass.fields.last) {
            buffer.write(',');
          }
          buffer.writeln();
        }
      }
      buffer.writeln('    );');
    } else {
      buffer.writeln('    return ${originalClass.name}()');
      for (final field in originalClass.fields) {
        if (field.setter != null) {
          buffer.writeln('      ..${field.name} = ${field.name}');
        }
      }
      buffer.writeln('    ;');
    }
    buffer.writeln('  }');

    // Close the class declaration.
    buffer.writeln('}');

    return buffer.toString();
  }
}
