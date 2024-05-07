#!/usr/bin/env python3

import argparse
import os
import re
import time

import yaml

from dart import DartFile
from objectbox import ObjectBoxConverter
from parser.base import Parser
from parser.parsimonious import ParsimoniousParser


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
    # Replace all backslashes with forward slashes
    input_string = input_string.replace("\\", "/")
    input_string = input_string.strip()

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
        raise Exception(f"Path does not exist: {input_string}")


def main():
    start = time.time()

    # Load grammar
    # parser = LarkParser("./grammar/dart.lark")
    parser = ParsimoniousParser("./grammar/dart.ppeg")

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

        generate_classes(input_files, output_dir, db_type, parser)

    end = time.time()
    print(f"Time elapsed: {end - start:.2f}s")


def generate_classes(
    input_files: list, output_dir: str, db_type: str, parser: Parser
) -> None:

    for input_file in input_files:
        with open(input_file) as f:
            dart_code = f.read()

        # Ignore input files that don't end with .*.dart
        # Check a regex instead
        if re.search(r"\..+\.dart$", input_file):
            # print(f"Ignoring {input_file}...")
            continue

        dart_file = parser.parse(dart_code, input_file)

        # Capture parent classes and extend DartClass
        for dart_class in dart_file.classes:
            # Don't bother with classes that don't have a parent
            if dart_class.parent_class_name:
                parent_class_name = dart_class.parent_class_name.split("<")[0]
                parent_class_path = find_parent_class_path(
                    parent_class_name, dart_file, input_file
                )

                # We found a path
                if parent_class_path:
                    with open(parent_class_path) as f:
                        parent_dart_code = f.read()

                    # Parse the file and get the parent class if possible
                    parent_dart_file = parser.parse(parent_dart_code, parent_class_path)
                    parent_class = parent_dart_file.get_class_by_name(parent_class_name)

                    if parent_class:
                        dart_class.extend_variables(parent_class)

        # Create output dir if it doesn't exist
        os.makedirs(output_dir, exist_ok=True)

        db_short_name = "ob" if db_type == "objectbox" else "hive"
        output_file = os.path.join(
            output_dir,
            os.path.basename(input_file).replace(".dart", f".{db_short_name}.dart"),
        )

        converter = ObjectBoxConverter(dart_file)

        with open(output_file, "w") as f:
            result_file = converter.convert()
            f.write(str(result_file))


def find_parent_class_path(
    parent_class_name: str, dart_file: DartFile, file_path: str
) -> str | None:
    # First, try to find the import path based on the class name
    parent_class_import = dart_file.find_import_for_class(parent_class_name)
    if parent_class_import:
        return dart_file.get_import_path(parent_class_import, file_path)

    # If not found, perform a quick regex search for the class declaration in the imported files
    for import_path in dart_file.imports:
        imported_file_path = dart_file.get_import_path(import_path, file_path)
        if os.path.exists(imported_file_path):
            with open(imported_file_path) as f:
                imported_dart_code = f.read()
            if re.search(rf"class\s+{parent_class_name}\b", imported_dart_code):
                return imported_file_path


main()
