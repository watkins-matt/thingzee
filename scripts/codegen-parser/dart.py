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


class DartClass:
    def __init__(
        self,
        name: str,
        parent_class_name: str,
        member_variables: list[Variable],
        imports: set[str],
        class_body: str,
        use_default_constructor: bool = True,
        annotations: list[str] = None,
        member_functions: list[Function] = None,
        constructors: list[Constructor] = None,
    ):
        self.name = name
        self.parent_class_name = parent_class_name
        self.member_variables = member_variables
        self.imports = imports
        self.class_body = class_body
        self.use_default_constructor = use_default_constructor
        self.annotations = annotations if annotations else []
        self.functions = member_functions if member_functions else []
        self.constructors = constructors if constructors else []

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
            + "}"
        )

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
        for var in self.member_variables:
            if var.annotations:
                variables += "\n".join(
                    f"  {annotation}" for annotation in var.annotations
                )
                variables += "\n"

            if var.default_value:
                variables += f"  {var.type} {var.name} = {var.default_value};\n"
            else:
                variables += f"  {var.type} {var.name};\n"
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
            class_str = "\n".join(self.annotations)

        class_str = f"class {self.name}"
        if self.parent_class_name:
            class_str += f" extends {self.parent_class_name}"
        class_str += " {"
        return class_str


class DartFile:
    def __init__(self, classes: list[DartClass], imports: set[str]):
        self.classes = classes
        self.imports = imports

    @staticmethod
    def normalize_class_name(class_name: str) -> str:
        if "<T>" in class_name:
            class_name = class_name.replace("<T>", "")
        return class_name

    def get_class_by_name(self, name: str) -> DartClass | None:
        name = self.normalize_class_name(name)

        for dart_class in self.classes:
            dart_class_name = self.normalize_class_name(dart_class.name)

            if dart_class_name == name:
                return dart_class
        return None

    def find_import_for_class(self, class_name: str) -> str | None:
        for import_path in self.imports:
            file_name = os.path.basename(import_path)
            if class_name.lower() in file_name.lower():
                return import_path
        return None

    def get_import_path(self, import_path: str, file_path: str) -> str:
        # Extract the package name from the import path
        package_name = self.extract_package_name(import_path)

        # Find the root directory of the imported project
        project_root = self.find_project_root(package_name, file_path)

        relative_path = import_path.replace(f"package:{package_name}/", "")

        # Construct the full path to the imported file
        full_path = os.path.join(project_root, "lib", relative_path.strip("'"))
        full_path = os.path.normpath(full_path)

        if os.path.exists(full_path):
            return full_path

        raise FileNotFoundError(f"Imported file '{import_path}' not found")

    def extract_package_name(self, import_path: str) -> str:
        # Extract the package name from the import path
        package_name = import_path.split("/")[0].strip("'")
        package_name = package_name.split(":")[-1]

        return package_name

    def find_project_root(self, package_name: str, current_file_path: str) -> str:
        # Find the root directory of the imported project
        current_dir = os.path.dirname(current_file_path)

        while current_dir != os.path.dirname(current_dir):
            pubspec_path = os.path.join(current_dir, "pubspec.yaml")
            if os.path.exists(pubspec_path):
                # Go one level above the current directory
                parent_dir = os.path.dirname(current_dir)

                # Search for the project root in the subdirectories
                for subdir in os.listdir(parent_dir):
                    subdir_path = os.path.join(parent_dir, subdir)
                    if os.path.isdir(subdir_path):
                        pubspec_path = os.path.join(subdir_path, "pubspec.yaml")
                        if os.path.exists(pubspec_path):
                            dart_pubspec = DartPubspec(pubspec_path)
                            if dart_pubspec.get_package_name() == package_name:
                                return subdir_path

                # If the project root is not found in the subdirectories, continue searching
                current_dir = os.path.dirname(parent_dir)
            else:
                current_dir = os.path.dirname(current_dir)

        raise FileNotFoundError(f"Project root for package '{package_name}' not found")

    def __repr__(self):
        return f"DartFile with {len(self.classes)} class(es)"

    def __str__(self):
        # Sort the imports first
        self.imports = sorted(self.imports)

        imports = "\n".join(f"import '{import_path}';" for import_path in self.imports)
        classes = "\n\n".join(str(dart_class) for dart_class in self.classes)
        return f"{imports}\n\n{classes}"


class DartPubspec:
    def __init__(self, pubspec_path: str):
        self.pubspec_path = pubspec_path
        self.pubspec_data = self.load_pubspec()

    def load_pubspec(self) -> dict:
        with open(self.pubspec_path, "r") as file:
            pubspec_data = yaml.safe_load(file)
        return pubspec_data

    def get_package_name(self) -> str:
        return self.pubspec_data.get("name", "")
