import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as path;

Builder objectBoxBuilder(BuilderOptions options) => ObjectBoxBuilder();

class ObjectBoxBuilder implements Builder {
  final Set<String> uniqueFields = const {'upc'};
  final Set<String> transientFields = const {'history'};
  final Map<String, String> packageReplace = {'repository_ob': 'repository'};

  @override
  final buildExtensions = const {
    '.dart': ['.ob.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    var library = await buildStep.inputLibrary;

    // This will hold the generated code.
    var buffer = StringBuffer();

    // Add necessary import statements.
    buffer.writeln("import 'package:objectbox/objectbox.dart';");
    buffer.writeln("import 'dart:convert';"); // Dart fix will remove if unnecessary

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

      if (uri.contains('repository_ob')) {
        uri = uri.replaceFirst('repository_ob', 'repository');
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

    // Initialize the typeId counter.
    var typeIdCounter = 0;

    // Iterate over all the classes in the input library.
    for (final originalClass in library.definingCompilationUnit.classes) {
      buffer.write(_generateObjectBoxClass(originalClass, typeIdCounter));
      typeIdCounter++;
    }

    // Write out the new asset.
    await buildStep.writeAsString(buildStep.inputId.changeExtension('.ob.dart'), buffer.toString());
  }

  String _generateObjectBoxClass(ClassElement originalClass, int typeIdCounter) {
    // This will hold the generated code for a single class.
    var buffer = StringBuffer();

    // Write the ObjectBox class declaration with the unique typeId.
    buffer.writeln('@Entity()');
    buffer.writeln('class ObjectBox${originalClass.name} {');

    for (final field in originalClass.fields) {
      // Skip all properties
      if (field.setter == null) {
        continue;
      }

      // This field should be transient
      if (transientFields.contains(field.name)) {
        buffer.writeln('  @Transient()');
      }

      if (uniqueFields.contains(field.name)) {
        buffer.writeln('  @Unique()');
      }

      final type = field.type.getDisplayString(withNullability: true);
      // Must initialize empty lists
      if (type.contains('List<')) {
        buffer.writeln('  $type ${field.name} = [];');
      }
      // Optional values must be initialized
      else if (type.contains('Optional<')) {
        buffer.writeln('  $type ${field.name} = const Optional.absent();');
      }

      // Check for null suffix
      // else if (field.type.nullabilitySuffix == NullabilitySuffix.question) {
      //   buffer.writeln('  $type ${field.name}?;');
      // }

      // Initialize transient fields
      else if (transientFields.contains(field.name)) {
        buffer.writeln('  $type ${field.name} = $type();');
      } else {
        buffer.writeln('  late $type ${field.name};');
      }
    }

    buffer.writeln('  @Id()');
    buffer.writeln('  int id = 0;');

    // Write an unnamed constructor
    buffer.writeln('  ObjectBox${originalClass.name}();');

    // Write a constructor that takes an instance of the original class.
    buffer.writeln('  ObjectBox${originalClass.name}.from(${originalClass.name} original) {');
    for (final field in originalClass.fields) {
      if (field.setter != null) {
        buffer.writeln('    ${field.name} = original.${field.name};');
      }
    }
    buffer.writeln('  }');

    // Write the conversion methods.
    buffer.writeln('  ${originalClass.name} to${originalClass.name}() {');

    if (originalClass.name == 'Inventory') {
      buffer.writeln('      // Ensure history is in a consistent state');
      buffer.writeln('      history.upc = upc;');
    }

    buffer.writeln('    return ${originalClass.name}()');
    for (final field in originalClass.fields) {
      if (field.setter != null) {
        buffer.writeln('      ..${field.name} = ${field.name}');
      }
    }
    buffer.writeln('    ;');
    buffer.writeln('  }');

    // Include template file if it exists
    final lowerCaseName = originalClass.name.toLowerCase();
    var templateFilePath = path.join('lib/model/$lowerCaseName.dart.template');
    var templateFile = File(templateFilePath);
    print('Reading $templateFilePath');

    if (templateFile.existsSync()) {
      var templateContent = templateFile.readAsStringSync();
      buffer.writeln(templateContent);
    }

    // Close the class declaration.
    buffer.writeln('}');

    return buffer.toString();
  }
}
