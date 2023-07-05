import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';

class Mergeable {
  const Mergeable();
}

Builder mergeGeneratorBuilder(BuilderOptions options) => MergeGenerator();

class MergeGenerator implements Builder {
  final Map<String, dynamic> defaultValues = {'unitCount': 1};

  @override
  final buildExtensions = const {
    '.dart': ['.merge.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    var library = await buildStep.inputLibrary;
    var buffer = StringBuffer();
    bool hasMergeable = false;

    // Add the "do not modify" warning.
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');

    // Generate the part statement.
    var fileName = buildStep.inputId.pathSegments.last;
    buffer.writeln("part of '$fileName';");

    // Iterate over all the classes in the input library.
    for (final originalClass in library.definingCompilationUnit.classes) {
      // Check if the class has the @Mergeable annotation.
      if (originalClass.metadata
          .any((metadata) => metadata.element?.enclosingElement?.name == 'Mergeable')) {
        buffer.write(_generateMergeMethod(originalClass));
        hasMergeable = true;
      }
    }

    if (hasMergeable) {
      await buildStep.writeAsString(
          buildStep.inputId.changeExtension('.merge.dart'), buffer.toString());
    }
  }

  String _generateMergeMethod(ClassElement originalClass) {
    // This will hold the generated code for a single class.
    var buffer = StringBuffer();

    // Write the merge method declaration.
    buffer.writeln(
        '${originalClass.name} _\$merge${originalClass.name}(${originalClass.name} first, ${originalClass.name} second) {');

    // Determine which item was updated more recently
    buffer.writeln(
        '  final firstUpdate = first.lastUpdate ?? DateTime.fromMillisecondsSinceEpoch(0);');
    buffer.writeln(
        '  final secondUpdate = second.lastUpdate ?? DateTime.fromMillisecondsSinceEpoch(0);');
    buffer.writeln(
        '  final newer${originalClass.name} = secondUpdate.isAfter(firstUpdate) ? second : first;');

    // Return a new instance of the class with merged fields.
    buffer.writeln('  return ${originalClass.name}()');

    // Merge each field individually.
    for (final field in originalClass.fields) {
      if (!field.isSynthetic) {
        // Exclude getters and setters
        if (field.type.getDisplayString(withNullability: true) == 'DateTime?') {
          buffer.writeln(
              '    ..${field.name} = newer${originalClass.name}.${field.name} ?? first.${field.name}');
        } else if (field.type.getDisplayString(withNullability: true) == 'String') {
          buffer.writeln(
              '    ..${field.name} = newer${originalClass.name}.${field.name}.isNotEmpty ? newer${originalClass.name}.${field.name} : first.${field.name}');
        } else if (field.type.getDisplayString(withNullability: true) == 'int') {
          if (defaultValues.containsKey(field.name)) {
            String defaultValue = defaultValues[field.name].toString();
            buffer.writeln(
                '    ..${field.name} = newer${originalClass.name}.${field.name} != $defaultValue ? newer${originalClass.name}.${field.name} : first.${field.name}');
          } else {
            buffer.writeln(
                '    ..${field.name} = newer${originalClass.name}.${field.name} != 0 ? newer${originalClass.name}.${field.name} : first.${field.name}');
          }
        } else if (field.type.getDisplayString(withNullability: true).startsWith('List<')) {
          buffer.writeln(
              '    ..${field.name} = {...newer${originalClass.name}.${field.name}, ...first.${field.name}}.toList()');
        } else {
          buffer.writeln('    ..${field.name} = newer${originalClass.name}.${field.name}');
        }
      }
    }

    buffer.writeln('  ;');
    buffer.writeln('}');

    return buffer.toString();
  }
}
