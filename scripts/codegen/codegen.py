#!/usr/bin/env python3

import argparse
import os
import re
from abc import ABC, abstractmethod
from collections import namedtuple
from pathlib import Path

import yaml

Attribute = namedtuple("Attribute", ["type", "name", "annotations"])


class ImportLookupTable:
    def __init__(self):
        self.lookup = {
            "ExpirationDate": "import 'package:repository/model/expiration_date.dart';",
            "History": "import 'package:repository/ml/history.dart';",
            "HouseholdMember": "import 'package:repository/model/household_member.dart';",
            "Inventory": "import 'package:repository/model/inventory.dart';",
            "Invitation": "import 'package:repository/model/invitation.dart';",
            "InvitationStatus": "import 'package:repository/model/invitation.dart';",
            "Item": "import 'package:repository/model/item.dart';",
            "ItemTranslation": "import 'package:repository/model/item_translation.dart';",
            "Location": "import 'package:repository/model/location.dart';",
            "Manufacturer": "import 'package:repository/model/manufacturer.dart';",
            "Product": "import 'package:repository/model/product.dart';",
            "ShoppingItem": "import 'package:repository/model/shopping_item.dart';",
            "Identifier": "import 'package:repository/model/identifier.dart';",
            "ReceiptItem": "import 'package:repository/model/receipt_item.dart';",
            "Receipt": "import 'package:repository/model/receipt.dart';",
            "AuditTask": "import 'package:repository/model/audit_task.dart';",
            "Place": "import 'package:repository/model/place.dart';",
        }

    def get_import(self, attribute_type: str) -> str:
        normalized_type = attribute_type.strip().rstrip("?").strip()
        return self.lookup.get(normalized_type, None)

    def add_import(self, attribute_type: str, import_statement: str) -> None:
        normalized_type = attribute_type.strip().rstrip("?").strip()
        self.lookup[normalized_type] = import_statement


class DartClass:
    def __init__(
        self,
        name: str,
        parent_class_name: str,
        attributes: list[Attribute],
        imports: set[str],
        class_body: str,
        use_default_constructor: bool = True,
    ):
        self.name = name
        self.parent_class_name = parent_class_name
        self.attributes = attributes
        self.imports = imports
        self.class_body = class_body
        self.use_default_constructor = use_default_constructor


class DartClassParser:
    def __init__(self):
        self.import_lookup = ImportLookupTable()

    @staticmethod
    def is_method_or_property(line: str) -> bool:
        return re.match(r"^\s*(\w+\s+)+(get|set\s+)?(\w+)\s*(\([^)]*\))?\s*{", line)

    @staticmethod
    def remove_methods_and_properties(content: str) -> str:
        lines = content.split("\n")
        clean_lines = []
        brace_count = 0
        inside_class = False
        inside_method_or_property = False

        for line in lines:
            stripped_line = line.strip()

            # Detect the start of the class
            if re.match(r"^(abstract\s+)?class \w+", stripped_line):
                inside_class = True
                clean_lines.append(line)
                continue

            # Once inside the class, start detecting methods and properties
            if inside_class:
                # Detect the start of a method or property block
                if DartClassParser.is_method_or_property(stripped_line):
                    inside_method_or_property = True
                    brace_count = 1
                    continue

                # Detect the end of a block
                if "}" in stripped_line and not inside_method_or_property:
                    brace_count -= 1
                    if brace_count == 0:
                        inside_method_or_property = False
                    continue

                # Skip the line if we're inside a method or property
                if inside_method_or_property:
                    continue

                # Add the line if it's not within a method or property block
                clean_lines.append(line)

        cleaned_content = "\n".join(clean_lines)

        # Remove getter lines using regex
        getter_pattern = r"^\s*\w+\s+get\s+\w+\s*;"
        cleaned_content = re.sub(
            getter_pattern, "", cleaned_content, flags=re.MULTILINE
        )

        return cleaned_content

    @staticmethod
    def use_default_constructor(class_body: str, class_name: str) -> bool:
        # Search for constructors with parameters
        constructor_pattern = r"\b{}\s*\(([^)]*)\)".format(class_name)
        matches = re.findall(constructor_pattern, class_body)

        for match in matches:
            if (
                match.strip()
            ):  # If there are parameters, don't use the default constructor
                return False
        return True

    def parse(self, file_path: str) -> list[DartClass]:
        content = DartClassParser.read_dart_file(file_path)
        dart_classes = []

        # Attempt to extract the relative import path from the file path
        try:
            self.find_package_import_path(file_path)
        except Exception:
            print(f"Could not find package import path for {file_path}.")

        class_pattern = re.compile(r"class (\w+)( extends (\w+))?")
        class_start = False
        brace_count = 0
        class_name = ""
        parent_class_name = ""
        class_body = ""

        # Iterate through each line of the file content
        for line in content.splitlines():
            if class_start:
                # Count the number of opening and closing braces
                brace_count += line.count("{") - line.count("}")

                if brace_count == 0:
                    # When brace_count returns to zero, the class definition ends
                    class_start = False

                    # Determine whether to use the default constructor
                    use_default = DartClassParser.use_default_constructor(
                        class_body, class_name
                    )

                    # Extract attributes from the class body
                    attributes = DartClassParser.extract_attributes(
                        class_body, file_path, parent_class_name
                    )

                    # Gather required imports for the class
                    required_imports = {
                        self.import_lookup.get_import(attr.type)
                        for attr in attributes
                        if self.import_lookup.get_import(attr.type)
                    }
                    class_import = self.import_lookup.get_import(class_name)
                    required_imports.add(class_import) if class_import else None

                    # Append the parsed class to the list of Dart classes
                    dart_classes.append(
                        DartClass(
                            class_name,
                            parent_class_name,
                            attributes,
                            required_imports,
                            class_body,
                            use_default,
                        )
                    )

                    # Reset class_body for the next class
                    class_body = ""
                else:
                    # Continue building the class body
                    class_body += line + "\n"
            else:
                # Check for the start of a new class
                match = class_pattern.search(line)
                if match:
                    class_name = match.group(1)
                    parent_class_name = (
                        match.group(3) or ""
                    )  # Parent class name or empty string
                    class_body = line + "\n"
                    class_start = True
                    brace_count = 1

        # Return the list of parsed Dart classes
        return dart_classes

    @staticmethod
    def find_package_import_path(file_path: str) -> str:
        current_dir = os.path.dirname(os.path.abspath(file_path))

        # Traverse up to find the package root containing pubspec.yaml
        while not os.path.exists(os.path.join(current_dir, "pubspec.yaml")):
            new_dir = os.path.dirname(current_dir)
            if new_dir == current_dir:  # Reached the root directory
                raise Exception("Could not find package root with pubspec.yaml")
            current_dir = new_dir

        # Get the package name from the directory name containing pubspec.yaml
        package_name = os.path.basename(current_dir)

        # Determine the relative path from the package root to the file
        relative_path = os.path.relpath(file_path, current_dir).replace("\\", "/")

        # Remove /lib from the relative path if present
        relative_path = relative_path.replace("lib/", "")

        return f"import 'package:{package_name}/{relative_path}';"

    @staticmethod
    def read_dart_file(file_path: str) -> str:
        with open(file_path, "r") as f:
            return f.read()

    @staticmethod
    def extract_class_names(content: str) -> list[str]:
        return re.findall(r"class (\w+)", content)

    @staticmethod
    def find_file_for_class(class_name: str, current_file_path: str) -> str:
        content = DartClassParser.read_dart_file(current_file_path)
        lower_class_name = class_name.lower()

        # Adjusted regex pattern to capture full relative path including subdirectories
        import_pattern = re.compile(r"import '(package:\w+)\/([\w\/]+\.dart)';")
        for line in content.splitlines():
            match = import_pattern.search(line)
            if match and line.strip().lower().endswith(f"{lower_class_name}.dart';"):
                # package_name = match.group(1)
                relative_path = match.group(2)

                # Find the root directory of the Dart project
                project_root = DartClassParser.find_project_root(current_file_path)

                # Construct the full path to the file
                full_path = os.path.join(project_root, "lib", relative_path)
                full_path = os.path.normpath(full_path)

                if os.path.exists(full_path):
                    return full_path

        raise FileNotFoundError(f"File for class {class_name} not found")

    @staticmethod
    def find_project_root(current_file_path: str) -> str:
        current_dir = os.path.dirname(current_file_path)
        while current_dir != os.path.dirname(
            current_dir
        ):  # Check if it's the root directory
            if os.path.exists(os.path.join(current_dir, "pubspec.yaml")):
                return current_dir
            current_dir = os.path.dirname(current_dir)
        raise FileNotFoundError("Dart project root not found")

    @staticmethod
    def extract_attributes(
        content: str, current_file_path: str, parent_class_name: str = ""
    ) -> list[Attribute]:
        attributes = []

        # First, include attributes from the parent class if it exists
        if parent_class_name:
            parent_class_file = DartClassParser.find_file_for_class(
                parent_class_name, current_file_path
            )
            if parent_class_file:
                parent_class_content = DartClassParser.read_dart_file(parent_class_file)
                parent_class_attributes = DartClassParser.extract_attributes(
                    parent_class_content, current_file_path
                )
                attributes.extend(parent_class_attributes)

        # Preprocess content to remove methods and properties
        cleaned_content = DartClassParser.remove_methods_and_properties(content)

        lines = cleaned_content.split("\n")

        leading_whitespace = r"\s*"
        exclude_control_structures = (
            r"(?!"  # Negative lookahead, start of group
            r".*("  # Match any character 0 or more times, start of inner group
            r"return\s+"  # Match 'return' followed by one or more spaces
            r"|if\s+"  # OR 'if' followed by one or more spaces
            r"|else\s+"  # OR 'else' followed by one or more spaces
            r"|switch\s+"  # OR 'switch' followed by one or more spaces
            r"|case\s+"  # OR 'case' followed by one or more spaces
            r"|for\s+"  # OR 'for' followed by one or more spaces
            r"|while\s+"  # OR 'while' followed by one or more spaces
            r"|do\s+"  # OR 'do' followed by one or more spaces
            r"|=>|"  # OR '=>'
            r"}).*\b)"  # End of inner group, any char 0 or more times, word boundary, end of group
        )

        optional_modifiers = r"(final|late|static)?"
        type_and_space = r"\s*([\w<>,? ]+)"
        variable_name = r"\s+(\w+)"
        optional_initialization = r"\s*(= [^;]+)?;"
        attribute_regex = (
            leading_whitespace
            + exclude_control_structures
            + optional_modifiers
            + type_and_space
            + variable_name
            + optional_initialization
        )

        for line in lines:
            modified_line = line.strip()

            # Check for generator annotations
            generator_regex = r"// generator:(\w+).+"
            generator_match = re.search(generator_regex, modified_line)

            # Find all annotations in the line
            annotations = []
            if generator_match:
                annotations = re.findall(r"generator:(\w+)", generator_match.group(0))
                # Remove empty items from annotations
                annotations = [annotation for annotation in annotations if annotation]

                # Remove the generator comment from the line
                modified_line = re.sub(generator_regex, "", modified_line).strip()

            # Apply the regex to each line
            match = re.match(attribute_regex, modified_line)
            if match:
                attr_type = match.group(3).strip()
                attr_name = match.group(4).strip()

                # Ensure both type and name are not empty
                if attr_type and attr_name:
                    # Remove the leading underscore from the attribute name
                    # if the property annotation is present
                    if (
                        "property" in annotations
                        and attr_name.startswith("_")
                        and len(attr_name) > 1
                    ):
                        attr_name = attr_name[1:]

                    attr = Attribute(
                        type=attr_type, name=attr_name, annotations=annotations
                    )

                    attributes.append(attr)

        return attributes


class DartClassGenerator(ABC):
    @abstractmethod
    def generate(self, dart_class: DartClass, custom_code: str = None) -> str:
        pass

    def generate_to_method(self, dart_class: DartClass) -> str:
        sorted_attributes = sorted(
            dart_class.attributes, key=lambda variable: variable.name
        )

        # Generate method for default constructor
        if dart_class.use_default_constructor:
            attribute_assignments = "\n".join(
                f"      ..{attribute.name} = {attribute.name}"
                for attribute in sorted_attributes
            ).rstrip()

            return (
                f"  {dart_class.name} convert() {{\n"
                f"    return {dart_class.name}()\n"
                f"{attribute_assignments};\n"
                f"  }}"
            )

        # Generate method for custom constructor with parameters on new lines
        else:
            parameters = ",\n        ".join(
                f"{attribute.name}: {attribute.name}" for attribute in sorted_attributes
            )
            return (
                f"  {dart_class.name} convert() {{\n"
                f"    return {dart_class.name}(\n"
                f"        {parameters});\n"
                f"  }}"
            )


class ObjectBoxGenerator(DartClassGenerator):
    def generate(self, dart_class: DartClass, custom_code: str = None) -> str:
        lines = []
        lines.append("@Entity()")
        lines.append(
            f"class ObjectBox{dart_class.name} extends ObjectBoxModel<{dart_class.name}> {{"
        )

        lines.append("  @Id()")
        lines.append("  int objectBoxId = 0;")

        dart_class.attributes = sorted(
            dart_class.attributes, key=lambda var: (var.type.lower(), var.name.lower())
        )

        for attribute in dart_class.attributes:
            if attribute.type.startswith("DateTime"):
                lines.append("  @Property(type: PropertyType.date)")
            if "transient" in attribute.annotations:
                lines.append("  @Transient()")
                default_value = (
                    "[]" if attribute.type.startswith("List<") else "{attribute.type}()"
                )
                lines.append(f"  {attribute.type} {attribute.name} = {default_value};")
                continue
            if "unique" in attribute.annotations:
                lines.append("  @Unique(onConflict: ConflictStrategy.replace)")
            # Check if the attribute type is a List
            if attribute.type.startswith("List<"):
                lines.append(f"  {attribute.type} {attribute.name} = [];")
            # Add the leading underscore back in for the member
            # shadowed by the property
            elif "property" in attribute.annotations:
                lines.append(f"  late {attribute.type} _{attribute.name};")
            else:
                lines.append(f"  late {attribute.type} {attribute.name};")

        lines.append(f"  ObjectBox{dart_class.name}();")
        lines.append(
            f"  ObjectBox{dart_class.name}.from({dart_class.name} original) {{",
        )

        dart_class.attributes = sorted(
            dart_class.attributes, key=lambda var: (var.name.lower())
        )

        for attribute in dart_class.attributes:
            lines.append(f"    {attribute.name} = original.{attribute.name};")

        lines.append("  }")

        to_method = self.generate_to_method(dart_class)
        lines.append(to_method)

        # Add custom code if present
        if custom_code:
            lines.append("\n" + custom_code)

        lines.append("}")

        return "\n".join(lines)


class HiveGenerator(DartClassGenerator):
    def __init__(self):
        self._type_id = 0

    @property
    def type_id(self) -> int:
        return self._type_id

    @type_id.setter
    def type_id(self, value: int):
        self._type_id = value

    def generate(self, dart_class: DartClass, custom_code: str = None) -> str:
        lines = []
        lines.append(f"@HiveType(typeId: {self.type_id})")
        lines.append(f"class Hive{dart_class.name} extends HiveObject {{")

        for idx, attribute in enumerate(dart_class.attributes):
            lines.append(f"  @HiveField({idx})")
            lines.append(f"  late {attribute.type} {attribute.name};")

        lines.append(f"  Hive{dart_class.name}();")
        lines.append(f"  Hive{dart_class.name}.from({dart_class.name} original) {{")

        for attribute in dart_class.attributes:
            lines.append(f"    {attribute.name} = original.{attribute.name};")

        lines.append("  }")

        to_method = self.generate_to_method(dart_class)
        lines.append(to_method)

        # Add custom code if present
        if custom_code:
            lines.append("\n" + custom_code)

        lines.append("}")

        return "\n".join(lines)


class DartOutputFileWriter:
    def __init__(self, db_type: str, output_ext: str, output_dir: str, input_file: str):
        self.db_type = db_type
        self.output_ext = output_ext
        self.output_dir = output_dir
        self.input_file = input_file
        self.dart_imports = set()
        self.package_imports = set()
        self.all_output_content = []
        self.package_imports.add(f"import 'package:{db_type}/{db_type}.dart';")

    def add_imports(self, dart_class: DartClass):
        for imp in dart_class.imports:
            if imp.startswith("import 'dart:"):
                self.dart_imports.add(imp)
            else:
                self.package_imports.add(imp)

    def add_class_content(self, class_content: str):
        self.all_output_content.append(class_content)

    def write_to_file(self):
        output_file_name = os.path.splitext(os.path.basename(self.input_file))[0]
        output_file_path = os.path.join(
            self.output_dir, f"{output_file_name}.{self.output_ext}.dart"
        )

        combined_imports = (
            "\n".join(sorted(self.dart_imports))
            + "\n\n"
            + "\n".join(sorted(self.package_imports))
        )

        if self.db_type == "hive":
            combined_imports += (
                f"\n\npart '{output_file_name}.{self.output_ext}.g.dart';"
            )

        if self.db_type == "objectbox":
            combined_imports += "\nimport 'package:repository_ob/objectbox_model.dart';"

        self.all_output_content.insert(0, combined_imports)

        combined_output = "\n\n".join(self.all_output_content)
        combined_output += "\n"  # Add trailing newline

        # Add // ignore_for_file: annotate_overrides to the start of the output
        combined_output = "// ignore_for_file: annotate_overrides\n" + combined_output

        self.write_dart_file(output_file_path, combined_output)

    def write_dart_file(self, file_path: str, content: str) -> None:
        # Create the directory if it doesn't exist
        directory = os.path.dirname(file_path)
        if not os.path.exists(directory):
            os.makedirs(directory, exist_ok=True)

        with open(file_path, "w") as f:
            f.write(content)


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate Database Dart classes.")
    parser.add_argument(
        "-i", "--input", type=str, help="Input Dart model file or directory"
    )
    parser.add_argument(
        "-o", "--output", type=str, default=".", help="Output directory"
    )
    parser.add_argument(
        "-d", "--db", type=str, choices=["objectbox", "hive"], help="Database type"
    )
    return parser.parse_args()


def load_config(script_path: str) -> list[dict]:
    # Determine the directory of the script
    script_dir = os.path.dirname(script_path)

    # Construct the path to the config file
    config_file = os.path.join(script_dir, "config.yaml")

    if os.path.exists(config_file):
        with open(config_file, "r") as f:
            return yaml.safe_load(f)
    return []


def determine_input_files(
    input_string: str, ignore_list: list[str], script_path: str
) -> list[str]:
    # Check if the input path is absolute. If not,
    # resolve it relative to the script's path.
    if not os.path.isabs(input_string):
        input_path = os.path.normpath(
            os.path.join(os.path.dirname(script_path), input_string)
        )
    else:
        input_path = input_string

    if os.path.isdir(input_path):
        return [
            os.path.join(input_path, f)
            for f in os.listdir(input_path)
            if f.endswith(".dart") and f not in ignore_list
        ]
    elif os.path.isfile(input_path) and os.path.basename(input_path) not in ignore_list:
        return [input_path]
    else:
        raise Exception(f"Invalid input: {input_string}")


def main():
    # Get the absolute path of the current script
    script_path = os.path.abspath(__file__)

    args = parse_arguments()
    configs = load_config(script_path)

    if not configs:
        if not args.input:
            raise Exception("No input file or directory specified.")
        configs = [
            {
                "input": determine_input_files(args.input, []),
                "output_dir": args.output,
                "db_type": args.db if args.db else "objectbox",
                "ignore": [],
            }
        ]

    for config in configs:
        input_files = [
            determine_input_files(inp, config.get("ignore", []), script_path)
            for inp in config["input"]
        ]
        # Flatten the list of lists into a single list
        input_files = [item for sublist in input_files for item in sublist]
        output_dir = config["output_dir"]
        db_type = config["db_type"]

        generate_classes(input_files, output_dir, db_type)


def read_custom_code(output_dir: str, class_name: str, output_ext: str) -> str:
    """Read custom code from a .include.dart file
    in the output directory and remove ignore_for_file comments."""
    include_file_path = Path(output_dir) / f"{class_name}.{output_ext}.include.dart"
    if include_file_path.exists():
        with open(include_file_path, "r") as f:
            content = f.read()
            # Use regex to remove 'ignore_for_file' comments
            cleaned_content = re.sub(r"// ignore_for_file:.*\n?", "", content)
            return cleaned_content.strip()
    return None


def indent_code(code: str, indent_level: int) -> str:
    """
    Indents all lines in the given custom code by the specified number of spaces.

    Parameters:
        code (str): The code to be indented.
        indent_level (int): The number of spaces for the indentation.

    Returns:
        str: The indented code.
    """
    indent = " " * indent_level
    indented_lines = [
        indent + line if line.strip() else line for line in code.split("\n")
    ]
    return "\n".join(indented_lines)


def generate_classes(input_files: list, output_dir: str, db_type: str) -> None:
    parser = DartClassParser()
    generator = ObjectBoxGenerator() if db_type == "objectbox" else HiveGenerator()
    output_ext = "ob" if db_type == "objectbox" else "hive"

    for input_file in input_files:
        dart_classes = parser.parse(input_file)
        writer = DartOutputFileWriter(db_type, output_ext, output_dir, input_file)

        class_content_length = 0

        for dart_class in dart_classes:
            writer.add_imports(dart_class)

            # Load custom code from a .include.dart file in the output directory
            # if present, otherwise None
            custom_code = read_custom_code(output_dir, dart_class.name, output_ext)

            # Indent the custom code by 2 spaces
            indented_custom_code = indent_code(custom_code, 2) if custom_code else None

            # Keep a running total of the class content for this file
            class_content = generator.generate(dart_class, indented_custom_code)
            class_content_length += len(class_content)

            writer.add_class_content(class_content)

        # Only write the file if it contains content
        if class_content_length > 0:
            writer.write_to_file()


if __name__ == "__main__":
    main()
