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
            "DateTime": "import 'dart:core';",
            "ExpirationDate": "import 'package:repository/model/expiration_date.dart';",
            "History": "import 'package:repository/ml/history.dart';",
            "HouseholdMember": "import 'package:repository/model/household_member.dart';",
            "Inventory": "import 'package:repository/model/inventory.dart';",
            "Item": "import 'package:repository/model/item.dart';",
            "Location": "import 'package:repository/model/location.dart';",
            "Manufacturer": "import 'package:repository/model/manufacturer.dart';",
            "Product": "import 'package:repository/model/product.dart';",
            "ShoppingItem": "import 'package:repository/model/shopping_item.dart';",
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
        attributes: list[Attribute],
        imports: set[str],
        class_body: str,
        use_default_constructor: bool = True,
    ):
        self.name = name
        self.attributes = attributes
        self.imports = imports
        self.class_body = class_body
        self.use_default_constructor = use_default_constructor


class DartClassParser:
    def __init__(self):
        self.import_lookup = ImportLookupTable()

    @staticmethod
    def remove_methods_and_properties(content: str) -> str:
        lines = content.split("\n")
        clean_lines = []
        brace_count = 0
        skip_line = False
        inside_class = False

        for line in lines:
            stripped_line = line.strip()

            # Detect the start of the class
            if re.match(r"^class \w+", stripped_line):
                inside_class = True
                clean_lines.append(line)
                continue

            # Once inside the class, start detecting methods and properties
            if inside_class:
                # Detect the start of a method or getter block
                if re.match(r"^\w+.*\([^)]*\)\s*{|^get\s+\w+\s*{", stripped_line):
                    skip_line = True
                    brace_count = 1  # Start of a new block
                    continue

                # Detect the start of a multiline block (like a method or getter)
                if "{" in stripped_line and "}" not in stripped_line:
                    skip_line = True
                    brace_count += 1

                # Detect the end of a block
                if "}" in stripped_line and "{" not in stripped_line:
                    brace_count -= 1
                    if brace_count == 0:
                        skip_line = False
                    continue

            # If not within a method or getter block, add the line
            if not skip_line and inside_class:
                clean_lines.append(line)

        return "\n".join(clean_lines)

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
            pass

        class_pattern = re.compile(r"class (\w+)")
        class_start = False
        brace_count = 0
        class_name = ""
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
                    attributes = DartClassParser.extract_attributes(class_body)

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
    def extract_attributes(content: str) -> list[Attribute]:
        # Preprocess content to remove methods and properties
        cleaned_content = DartClassParser.remove_methods_and_properties(content)

        lines = cleaned_content.split("\n")
        attributes = []

        leading_whitespace = r"\s*"
        exclude_control_structures = r"(?!.*(return\s+|if\s+|else\s+|switch\s+|case\s+|for\s+|while\s+|do\s+|=>|}).*\b)"
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
        # Generate method for default constructor
        if dart_class.use_default_constructor:
            attribute_assignments = "\n".join(
                f"      ..{attribute.name} = {attribute.name}"
                for attribute in dart_class.attributes
            ).rstrip()

            return (
                f"  {dart_class.name} to{dart_class.name}() {{\n"
                f"    return {dart_class.name}()\n"
                f"{attribute_assignments};\n"
                f"  }}"
            )

        # Generate method for custom constructor with parameters on new lines
        else:
            parameters = ",\n        ".join(
                f"{attribute.name}: {attribute.name}"
                for attribute in dart_class.attributes
            )
            return (
                f"  {dart_class.name} to{dart_class.name}() {{\n"
                f"    return {dart_class.name}(\n"
                f"        {parameters});\n"
                f"  }}"
            )


class ObjectBoxGenerator(DartClassGenerator):
    def generate(self, dart_class: DartClass, custom_code: str = None) -> str:
        lines = []
        lines.append("@Entity()")
        lines.append(f"class ObjectBox{dart_class.name} {{")

        for attribute in dart_class.attributes:
            if "transient" in attribute.annotations:
                lines.append("  @Transient()")
                lines.append(
                    f"  {attribute.type} {attribute.name} = {attribute.type}();"
                )
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

        lines.append("  @Id()")
        lines.append("  int objectBoxId = 0;")
        lines.append(f"  ObjectBox{dart_class.name}();")
        lines.append(
            f"  ObjectBox{dart_class.name}.from({dart_class.name} original) {{",
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
    def __init__(self, type_id: int) -> None:
        self.type_id = type_id

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
        combined_imports = (
            "\n".join(sorted(self.dart_imports))
            + "\n\n"
            + "\n".join(sorted(self.package_imports))
        )

        self.all_output_content.insert(0, combined_imports)

        output_file_name = os.path.splitext(os.path.basename(self.input_file))[0]
        output_file_path = os.path.join(
            self.output_dir, f"{output_file_name}.{self.output_ext}.dart"
        )

        combined_output = "\n\n".join(self.all_output_content)
        combined_output += "\n"  # Add trailing newline

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
