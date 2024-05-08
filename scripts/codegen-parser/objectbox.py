from dart import DartClass, DartFile, Function, Variable


class ObjectBoxConverter:
    def __init__(self, file: DartFile, original_file_path: str):
        self.file = file
        self.original_file_path = original_file_path

    def convert(self) -> DartFile:
        self.file.add_comment("// GENERATED FILE: DO NOT MODIFY")
        self.file.add_comment("// ignore_for_file: annotate_overrides")

        self._convert_imports()

        for dart_class in self.file.classes:
            self._convert_class(dart_class)

        return self.file

    def _convert_imports(self):
        new_imports = set()
        new_imports.add("package:objectbox/objectbox.dart")
        new_imports.add("package:repository_ob/objectbox_model.dart")
        new_imports.add(self.file.import_string)

        self.file.imports = new_imports

    def _convert_class(self, dart_class: DartClass):
        original_class_name = dart_class.name

        if "@immutable" in dart_class.annotations:
            dart_class.use_default_constructor = False

        # Make sure we have @Entity added and other annotations removed
        dart_class.annotations = ["@Entity()"]

        if not dart_class.name.startswith("ObjectBox"):
            dart_class.name = f"ObjectBox{original_class_name}"

        if dart_class.parent_class_name != "ObjectBoxModel":
            dart_class.parent_class_name = f"ObjectBoxModel<{original_class_name}>"

        dart_class.functions = []
        dart_class.functions.append(self._generate_from_constructor(dart_class))
        dart_class.functions.append(self._generate_convert_method(dart_class))

        # Convert all member variables
        dart_class.member_variables = [
            self._convert_variable(variable) for variable in dart_class.member_variables
        ]

        # Add objectBoxId as the first member variable
        object_box_id = Variable("int", "objectBoxId", ["@Id()"], "0")
        dart_class.member_variables.insert(0, object_box_id)

    def _convert_variable(self, variable: Variable):
        annotations = []
        default_value = variable.default_value

        # Remove final from the variable type if present
        variable_type = variable.type.replace("final ", "")

        if variable_type == "DateTime" or variable_type == "DateTime?":
            variable_type = f"late {variable_type}"
            annotations.append("@Property(type: PropertyType.date)")
        elif variable_type.startswith("List<"):
            variable_type = f"late {variable_type}"
            default_value = "[]"
        else:
            variable_type = f"late {variable_type}"
            default_value = variable.default_value

        updated_variable = Variable(
            type=variable_type,
            name=variable.name,
            annotations=annotations,
            default_value=default_value,
        )

        return updated_variable

    def _generate_convert_method(self, dart_class: DartClass):
        original_name = dart_class.name.replace("ObjectBox", "")
        sorted_member_variables = sorted(
            dart_class.member_variables, key=lambda variable: variable.name
        )

        # Generate method for default constructor
        if dart_class.use_default_constructor:
            variable_assignments = "\n".join(
                f"      ..{variable.name} = {variable.name}"
                for variable in sorted_member_variables
            ).rstrip()

            body = f"    return {dart_class.name}()\n{variable_assignments};\n"

            return Function(
                "convert",
                f"{original_name}",
                "",
                body.rstrip(),
            )

        # Generate method for custom constructor with parameters on new lines
        else:
            parameters = ",\n        ".join(
                f"{variable.name}: {variable.name}"
                for variable in sorted_member_variables
            )
            body = f"    return {original_name}(\n" f"        {parameters});\n"
            return Function("convert", f"{original_name}", "", body)

    def _generate_from_constructor(self, dart_class: DartClass) -> Function:
        original_name = dart_class.name.replace("ObjectBox", "")

        function_body = "\n".join(
            f"    {variable.name} = original.{variable.name};"
            for variable in dart_class.member_variables
        )
        return Function(
            f"{dart_class.name}.from",
            "",
            f"{original_name} original",
            f"{function_body}",
        )
