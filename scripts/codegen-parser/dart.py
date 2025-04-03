import os
from collections import namedtuple

import yaml

Variable = namedtuple(
    "Variable",
    ["type", "name", "annotations", "default_value"],
    defaults=["", "", [], ""],
)

Type = namedtuple("Type", ["name"], defaults=[""])

Function = namedtuple(
    "Function",
    ["name", "return_type", "parameters", "body", "annotations"],
    defaults=["", "", "", "", []],
)

Constructor = namedtuple(
    "Constructor",
    ["name", "parameters", "initializer", "body"],
    defaults=["", "", "", ""],
)


class DartPubspec:
    def __init__(self, pubspec_path: str):
        self.pubspec_path = pubspec_path
        self.pubspec_data = self.load_pubspec()

    def load_pubspec(self) -> dict:
        with open(self.pubspec_path, "r") as file:
            pubspec_data = yaml.safe_load(file)
        return pubspec_data

    @property
    def package_name(self) -> str:
        return self.pubspec_data.get("name", "")

    @property
    def pubspec_directory(self) -> str:
        return os.path.dirname(self.pubspec_path)


class DartClass:

    def __init__(
        self,
        name: str,
        parent_class_name: str,
        member_variables: list[Variable],
        imports: set[str],
        class_body: str,
        use_default_constructor: bool = True,
        annotations: list[str] | None = None,
        member_functions: list[Function] | None = None,
        constructors: list[Constructor] | None = None,
    ):
        self.name = name
        self.parent_class_name = parent_class_name
        self.member_variables = member_variables
        self.imports = imports
        self.class_body = class_body
        self.use_default_constructor = use_default_constructor
        self.annotations: list[str] = annotations if annotations else []
        self.functions: list[Function] = member_functions if member_functions else []
        self.constructors: list[Constructor] = constructors if constructors else []
        self.include_file_contents = ""

    def __repr__(self):
        return f"class {self.name}"

    def __str__(self):
        return (
            self._write_class()
            + "\n"
            + self._write_variables()
            + self._write_constructor()
            + self._write_functions()
            + self.class_body
            + ("\n" if self.class_body and not self.class_body.endswith("\n") else "")
            + "}"
        )

    @property
    def pubspec(self) -> DartPubspec:
        project_root = self.find_project_root(self.original_file_path)
        pubspec_path = os.path.join(project_root, "pubspec.yaml")
        return DartPubspec(pubspec_path)

    @staticmethod
    def normalize_class_name(class_name: str) -> str:
        if "<T>" in class_name:
            class_name = class_name.replace("<T>", "")
        return class_name

    def extend_variables(self, other: "DartClass") -> None:
        self.member_variables.extend(other.member_variables)

    def _write_constructor(self):
        all_constructors = self.constructors
        if len(all_constructors) == 0:
            all_constructors.append(Constructor(self.name, "", "", ";"))

        constructors = ""
        for constructor in self.constructors:
            constructor_body = constructor.body
            initializer = constructor.initializer

            if constructor_body != ";":
                constructor_body = f"{{\n{constructor_body}\n  }}"

            if len(initializer) > 0:
                initializer = f" : {initializer} "

            line = (
                f"{constructor.name}({constructor.parameters})"
                + initializer
                + constructor_body
            ).strip()
            constructors += f"\n  {line}\n"

        return constructors

    def _write_variables(self):
        variables = ""

        # Sort the variables in two stages, first by type, then by name
        self.member_variables = sorted(
            self.member_variables, key=lambda var: (var.type.lower(), var.name.lower())
        )

        for var in self.member_variables:
            if var.annotations:
                variables += "\n".join(
                    f"  {annotation}" for annotation in var.annotations
                )
                variables += "\n"

            variable_type = var.type
            # Remove 'late' when there's a default value (for proper initialization)
            if var.default_value and variable_type.startswith("late "):
                variable_type = variable_type.replace("late ", "")

            if var.default_value:
                variables += f"  {variable_type} {var.name} = {var.default_value};\n"
            else:
                variables += f"  {variable_type} {var.name};\n"
        return variables

    def _write_functions(self):
        functions = ""
        for func in self.functions:
            line = (
                f"{func.return_type} {func.name}({func.parameters}) "
                + f"{{\n{func.body}\n  }}"
            ).strip()
            functions += f"\n  {line}\n"
        return functions

    def _write_class(self):
        class_str = ""

        if self.annotations and len(self.annotations) > 0:
            class_str = "\n".join(self.annotations) + "\n"

        class_str = f"{class_str}class {self.name}"
        if self.parent_class_name:
            class_str += f" extends {self.parent_class_name}"
        class_str += " {"
        return class_str


class DartFile:
    def __init__(
        self, classes: list[DartClass], imports: set[str], file_path: str = ""
    ):
        """
        Initialize a DartFile instance.

        :param classes: A list of DartClass instances representing the classes in the file.
        :param imports: A set of import paths used in the file.
        :param file_path: The path to the Dart file.
        """
        self.classes = classes
        self.imports = imports
        self._file_path = file_path
        self.comments = []
        self.ensure_final_newline = True

    @property
    def file_path(self):
        return self._file_path

    @file_path.setter
    def file_path(self, value):
        self._file_path = value

    @property
    def pubspec(self) -> DartPubspec | None:
        """
        Get the DartPubspec instance for the current DartFile.

        :return: The DartPubspec instance for the current DartFile, or None if not found.
        :raises ValueError: If the file path is not set.
        """
        if not self.file_path:
            raise ValueError("Cannot find pubspec, file path is not set.")

        project_root = self.find_project_root()
        if project_root:
            pubspec_path = os.path.join(project_root, "pubspec.yaml")
            return DartPubspec(pubspec_path)

        return None

    @property
    def relative_path(self) -> str:
        """
        Get the relative path of the current file to its project root, excluding "lib".

        :return: The relative path of the current file to its project root, excluding "lib".
        :raises ValueError: If the file path is not set.
        """
        if not self.file_path:
            raise ValueError("File path is not set.")

        project_root = self.find_project_root()
        if not project_root:
            raise FileNotFoundError("Project root not found.")

        lib_dir = os.path.join(project_root, "lib")
        relative_path = os.path.relpath(self.file_path, lib_dir)

        return relative_path

    @property
    def import_string(self) -> str:
        """
        Get the import string for the current Dart file.

        :return: The import string for the current Dart file.
        :raises ValueError: If the file path is not set.
        """
        if not self.file_path:
            raise ValueError("File path is not set")

        package_name = self.pubspec.package_name
        relative_path = self.relative_path

        # Ensure relative path uses forward slash
        relative_path = relative_path.replace("\\", "/")

        return f"package:{package_name}/{relative_path}"

    def add_comment(self, comment: str):
        self.comments.append(comment)

    def get_class_by_name(self, name: str) -> DartClass | None:
        """
        Get a DartClass instance contained within the DartFile by name.

        :param name: The name of the class to retrieve.
        :return: The DartClass instance with the specified name, or None if not found.
        """
        name = DartClass.normalize_class_name(name)

        for dart_class in self.classes:
            dart_class_name = DartClass.normalize_class_name(dart_class.name)

            if dart_class_name == name:
                return dart_class
        return None

    def find_import_for_class(self, class_name: str) -> str | None:
        """
        Find the import string for a given class name.

        :param class_name: The name of the class to find the import path for.
        :return: The import string for the class, or None if not found.
        """
        class_name = DartClass.normalize_class_name(class_name)

        for import_path in self.imports:
            file_name = os.path.basename(import_path)
            if class_name.lower() in file_name.lower():
                return import_path
        return None

    def get_import_path(self, import_str: str) -> str:
        """
        Convert an import string to a full file path.

        :param import_str: The import string to convert.
        :return: The full file path corresponding to the import string.
        :raises ValueError: If the file path is not set.
        :raises FileNotFoundError: If the imported file is not found.
        """
        if not self.file_path:
            raise ValueError("Cannot find import path, file path is not set.")

        # Extract the package name from the import path
        package_name = self.get_package_name_from_import_path(import_str)

        dart_pubspec = self.find_pubspec(package_name)
        if not dart_pubspec:
            raise FileNotFoundError(
                f"Pubspec.yaml not found for package {package_name}."
            )

        project_root = os.path.dirname(dart_pubspec.pubspec_path)

        relative_path = import_str.replace(f"package:{package_name}/", "")

        # Construct the full path to the imported file
        full_path = os.path.join(project_root, "lib", relative_path.strip("'"))
        full_path = os.path.normpath(full_path)

        if not os.path.exists(full_path):
            raise FileNotFoundError(f"Imported file '{import_str}' not found.")

        return full_path

    def get_package_name_from_import_path(self, import_path: str) -> str:
        """
        Get the package name from an import path.

        So for example, given the import path 'package:example_project/main.dart',
        this method would return 'example_project'.

        :param import_path: The import path to extract the package name from.
        :return: The package name extracted from the import path.
        """
        package_name = import_path.split("/")[0].strip("'")
        package_name = package_name.split(":")[-1]

        return package_name

    def find_project_root(self) -> str:
        """
        Find the root directory of the current project.

        :return: The root directory of the current project.
        :raises FileNotFoundError: If the project root is not found.
        :raises ValueError: If the file path is not set.
        """
        if not self.file_path:
            raise ValueError("Cannot find root directory, file path is not set.")

        # Find the root directory of the current project
        current_dir = os.path.dirname(self.file_path)

        while current_dir != os.path.dirname(current_dir):
            pubspec_path = os.path.join(current_dir, "pubspec.yaml")
            if os.path.exists(pubspec_path):
                return current_dir
            current_dir = os.path.dirname(current_dir)

        raise FileNotFoundError("Project root directory not found.")

    def find_pubspec(self, package_name: str) -> DartPubspec:
        """
        Find the pubspec.yaml file of the specified package.

        :param package_name: The name of the package to find the pubspec.yaml file for.
        :return: The DartPubspec instance representing the pubspec.yaml file.
        :raises FileNotFoundError: If the pubspec.yaml file is not found.
        :raises ValueError: If the file path is not set.
        """
        if not self.file_path:
            raise ValueError("Cannot find pubspec, file path is not set.")

        # Find the pubspec.yaml file of the imported project
        current_dir = os.path.dirname(self.file_path)

        while current_dir != os.path.dirname(current_dir):
            pubspec_path = os.path.join(current_dir, "pubspec.yaml")
            if os.path.exists(pubspec_path):
                # Go one level above the current directory
                parent_dir = os.path.dirname(current_dir)

                # Search for the pubspec.yaml file in the subdirectories
                for subdir in os.listdir(parent_dir):
                    subdir_path = os.path.join(parent_dir, subdir)
                    if os.path.isdir(subdir_path):
                        pubspec_path = os.path.join(subdir_path, "pubspec.yaml")
                        if os.path.exists(pubspec_path):
                            dart_pubspec = DartPubspec(pubspec_path)
                            if dart_pubspec.package_name == package_name:
                                return dart_pubspec

                # If the pubspec.yaml file is not found in the subdirectories, continue searching
                current_dir = os.path.dirname(parent_dir)
            else:
                current_dir = os.path.dirname(current_dir)

        raise FileNotFoundError(f"Pubspec.yaml not found for package {package_name}.")

    def __repr__(self):
        return f"DartFile with {len(self.classes)} class(es)"

    def __str__(self):
        # Sort the imports first
        self.imports = sorted(self.imports)

        comments = "\n".join(self.comments).strip()

        # Add two newlines if comments are present
        if comments:
            comments += "\n\n"

        imports = "\n".join(f"import '{import_path}';" for import_path in self.imports)
        classes = "\n\n".join(str(dart_class) for dart_class in self.classes)

        # Join everything together
        result = f"{comments}{imports}\n\n{classes}"
        
        # Add a final newline if requested
        if hasattr(self, 'ensure_final_newline') and self.ensure_final_newline:
            result += "\n"
            
        return result
