from dart import DartClass, DartFile, Function, Variable
import os


class ObjectBoxConverter:
    def __init__(self, file: DartFile, original_file_path: str, output_dir: str = None):
        self.file = file
        self.original_file_path = original_file_path
        self.output_dir = output_dir

    def convert(self) -> DartFile:
        self.file.add_comment("// GENERATED FILE: DO NOT MODIFY")
        self.file.add_comment("// ignore_for_file: annotate_overrides")

        self._convert_imports()

        for dart_class in self.file.classes:
            self._convert_class(dart_class)

        # Ensure there's a newline at the end of the file
        self.file.ensure_final_newline = True
        
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

        # Check for Model base class to ensure created/updated fields
        has_model_base_class = False
        if dart_class.parent_class_name and "Model" in dart_class.parent_class_name:
            has_model_base_class = True

        if dart_class.parent_class_name != "ObjectBoxModel":
            dart_class.parent_class_name = f"ObjectBoxModel<{original_class_name}>"

        # Remove all variables with the Transient annotation
        dart_class.member_variables = [
            variable
            for variable in dart_class.member_variables
            if "@Transient()" not in variable.annotations
            and "@Transient" not in variable.annotations
        ]

        # Process comment directives in the variable declaration
        for variable in dart_class.member_variables:
            # Check variable.comment_directives if available, otherwise use a fallback
            if hasattr(variable, 'comment_directives') and variable.comment_directives:
                if 'unique' in variable.comment_directives:
                    if not any(a.startswith('@Unique') for a in variable.annotations):
                        variable.annotations.append('@Unique(onConflict: ConflictStrategy.replace)')
                if 'transient' in variable.comment_directives:
                    if not any(a.startswith('@Transient') for a in variable.annotations):
                        variable.annotations.append('@Transient()')

        # Add created/updated DateTime fields if from Model base class and not already present
        if has_model_base_class:
            # Check if created and updated already exist
            has_created = any(var.name == "created" for var in dart_class.member_variables)
            has_updated = any(var.name == "updated" for var in dart_class.member_variables)
            
            # Add them if missing
            if not has_created:
                created_var = Variable(
                    type="DateTime",
                    name="created",
                    annotations=["@Property(type: PropertyType.date)"],
                    default_value=""
                )
                dart_class.member_variables.append(created_var)
                
            if not has_updated:
                updated_var = Variable(
                    type="DateTime",
                    name="updated",
                    annotations=["@Property(type: PropertyType.date)"],
                    default_value=""
                )
                dart_class.member_variables.append(updated_var)

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

        # Check if there's an include file and add its contents to the class
        self._add_include_file_contents(dart_class)

    def _add_include_file_contents(self, dart_class: DartClass):
        # First determine the output file path
        if self.output_dir is None:
            # If no output_dir provided, use the source directory
            src_path = self.original_file_path
            base_name = os.path.basename(src_path).replace('.dart', '')
            include_path = os.path.join(os.path.dirname(src_path), f"{base_name}.ob.include.dart")
        else:
            # Using the output directory
            base_name = os.path.basename(self.original_file_path).replace('.dart', '')
            include_path = os.path.join(self.output_dir, f"{base_name}.ob.include.dart")
        
        try:
            if os.path.exists(include_path):
                with open(include_path, 'r') as f:
                    include_contents = f.read()
                    # Add the include file contents directly to the class body
                    if include_contents.strip():
                        # Remove any leading comment if it's an auto-generated warning
                        if include_contents.startswith('//') and '\n' in include_contents:
                            first_line = include_contents.split('\n')[0].lower()
                            if 'generated' in first_line or 'ignore' in first_line:
                                include_contents = include_contents[include_contents.index('\n')+1:]
                        
                        # Properly indent each line with 2 spaces
                        lines = include_contents.splitlines()
                        indented_lines = ['  ' + line if line.strip() else line for line in lines]
                        indented_content = '\n'.join(indented_lines)
                        
                        # Add the content directly to the class body
                        dart_class.class_body += "\n" + indented_content
                        print(f"Added include file: {include_path}")
        except Exception as e:
            print(f"Error including file {include_path}: {e}")

    def _convert_variable(self, variable: Variable):
        # Check for special comment directives in the code
        # This is a fallback method if Variable doesn't have comment_directives
        if not hasattr(variable, 'comment_directives'):
            # Look for directives in the source code if we can
            comment_directives = []
            # Try to find the original file to extract comment directives
            try:
                with open(self.original_file_path, 'r') as f:
                    source_lines = f.readlines()
                    for line in source_lines:
                        if f"{variable.name};" in line or f"{variable.name} =" in line:
                            if "// generator:unique" in line:
                                comment_directives.append('unique')
                            if "// generator:transient" in line:
                                comment_directives.append('transient')
                            # Add more directive recognitions as needed
            except Exception:
                pass  # Silently fail if we can't read the file
        else:
            comment_directives = variable.comment_directives

        # Add directive-based annotations
        # Initialize annotations list
        annotations = []

        # Add @Unique based on generator:unique directive
        if comment_directives and 'unique' in comment_directives:
            annotations.append('@Unique(onConflict: ConflictStrategy.replace)')
            
        # Add @Transient based on generator:transient directive
        if comment_directives and 'transient' in comment_directives:
            annotations.append('@Transient()')
        
        # Filter annotations - keep only those we need for ObjectBox
        # Keep annotations that start with @Unique, @Index, @Id, or @Transient
        for annotation in variable.annotations:
            # Preserve ObjectBox-specific annotations
            if (
                annotation.startswith("@Unique") or
                annotation.startswith("@Index") or
                annotation.startswith("@Id") or
                annotation.startswith("@Transient")
            ):
                # Only add if not already added by directives
                if not any(a.startswith(annotation.split('(')[0]) for a in annotations):
                    annotations.append(annotation)
        
        default_value = variable.default_value

        # Remove final from the variable type if present
        variable_type = variable.type.replace("final ", "")

        # Add property annotation for DateTime if not already present
        if (variable_type == "DateTime" or variable_type == "DateTime?") and not any(a.startswith("@Transient") for a in annotations):
            annotations.append("@Property(type: PropertyType.date)")

        # Handle List types specially
        if variable_type.startswith("List<"):
            # For Lists, always provide a default value if not specified
            if not default_value:
                default_value = "[]"
                # Only add late if we're not providing an initializer
                variable_type = f"late {variable_type}"
        # For non-List types, add 'late' if needed
        elif not default_value and not any(a.startswith("@Transient") for a in annotations):
            variable_type = f"late {variable_type}"

        updated_variable = Variable(
            type=variable_type,
            name=variable.name,
            annotations=annotations,
            default_value=default_value,
        )

        return updated_variable

    def _generate_convert_method(self, dart_class: DartClass) -> Function:
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
            body = f"    return {dart_class.name}()\n{variable_assignments};"
            return Function(
                name="convert",
                return_type=original_name,
                parameters="",
                body=body.rstrip(),
            )
        # Generate method for custom constructor with parameters on new lines
        else:
            parameters = ",\n    ".join(
                f"  {variable.name}: {variable.name}"
                for variable in sorted_member_variables
            )
            body = f"    return {original_name}(\n    {parameters}\n    );"
            return Function(
                name="convert",
                return_type=original_name,
                parameters="",
                body=body,
            )

    def _generate_from_constructor(self, dart_class: DartClass) -> Function:
        original_name = dart_class.name.replace("ObjectBox", "")
        sorted_member_variables = sorted(
            dart_class.member_variables, key=lambda variable: variable.name
        )

        function_body = "\n".join(
            f"    {variable.name} = original.{variable.name};"
            for variable in sorted_member_variables
        )
        return Function(
            f"{dart_class.name}.from",
            "",
            f"{original_name} original",
            f"{function_body}",
        )
