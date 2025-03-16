import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';

Builder mergeGeneratorBuilder(BuilderOptions options) => MergeGenerator();

class Mergeable {
  const Mergeable();
}

class MergeGenerator implements Builder {
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
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND\n');

    // Generate the part statement.
    var fileName = buildStep.inputId.pathSegments.last;
    buffer.writeln("part of '$fileName';\n");

    // Iterate over all the classes in the input library.
    for (final originalClass in library.definingCompilationUnit.classes) {
      if (originalClass.metadata
          .any((metadata) => metadata.element?.enclosingElement3?.name == 'Mergeable')) {
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
    var buffer = StringBuffer();

    // Write the merge method declaration.
    buffer.writeln(
        '${originalClass.name} _\$merge${originalClass.name}(${originalClass.name} first, ${originalClass.name} second) {');

    // Determine which item was updated more recently
    buffer.writeln(
        '  final newer = first.updated.newer(second.updated) == first.updated ? first : second;');

    // Create a new instance of the class with merged fields.
    buffer.writeln('  var merged = ${originalClass.name}(');

    // Merge each field individually.
    for (final field in originalClass.fields) {
      if (!field.isSynthetic) {
        String fieldType = field.type.getDisplayString();
        String fieldName = field.name.startsWith('_') ? field.name.substring(1) : field.name;

        if (fieldType == 'String') {
          buffer.writeln(
              '    $fieldName: newer.$fieldName.isNotEmpty ? newer.$fieldName : first.$fieldName,');
        } else if (fieldType.startsWith('List<')) {
          String elementType = fieldType.substring('List<'.length, fieldType.length - 1);
          buffer.writeln(
              '    $fieldName: <$elementType>{...first.$fieldName, ...second.$fieldName}.toList(),');
        } else {
          buffer.writeln('    $fieldName: newer.$fieldName,');
        }
      }
    }

    buffer.writeln('    created: first.created.older(second.created),');
    buffer.writeln('    updated: newer.updated,');
    buffer.writeln('  );');

    // Check if merged is different from newer and update the 'updated' timestamp
    buffer.writeln('  if (!merged.equalTo(newer)) {');
    buffer.writeln('    merged = merged.copyWith(updated: DateTime.now());');
    buffer.writeln('  }');
    buffer.writeln('  return merged;');
    buffer.writeln('}');

    return buffer.toString();
  }
}
