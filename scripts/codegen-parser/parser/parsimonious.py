from itertools import chain

from parsimonious.exceptions import ParseError
from parsimonious.grammar import Grammar
from parsimonious.nodes import Node, NodeVisitor

from dart import Constructor, DartClass, DartFile, Function, Variable
from parser.base import Parser


class ParsimoniousParser(Parser):
    def __init__(self, grammar_file_path: str):
        with open(grammar_file_path) as grammar:
            self.parser = Grammar(grammar.read())

    def parse(self, text: str, filename: str = None):
        filename = "" if filename is None else filename

        try:
            parse_tree = self.parser.parse(text)
            visitor = DartNodeVisitor()
            dart_file = visitor.visit(parse_tree)
            return dart_file

        except ParseError as e:
            if filename:
                print(f"Parse error in file: {filename}")
            else:
                print("Parse error")
            raise e


def flatten(items) -> list:
    """Recursively flattens a nested list structure using itertools.chain."""
    return list(
        chain.from_iterable(
            flatten(item) if isinstance(item, list) else [item] for item in items
        )
    )


class DartNodeVisitor(NodeVisitor):
    def visit_start(self, node, visited_children):
        """Constructs the final DartFile object from all collected data."""
        imports, parts, classes = visited_children
        classes = flatten(classes)

        classes = [cls for cls in classes if isinstance(cls, DartClass)]

        return DartFile(classes, set(imports))

    def visit_part_statement(self, node, visited_children):
        """Extracts part statement paths and adds them to the import set."""
        _, _, _, _, part_path, _ = visited_children
        return part_path

    def visit_import_statement(self, node, visited_children):
        """Extracts import statement paths and adds them to the import set."""
        comment, _, _, _, import_path, _ = visited_children
        return import_path

    def visit_semicolon(self, node, visited_children):
        return node.text

    def visit_string(self, node, visited_children):
        """Extracts the string content from single or double-quoted strings."""
        return visited_children[0]

    def visit_single_quoted_string(self, node, visited_children):
        """Extracts the content of a single-quoted string."""
        _, content, _ = visited_children
        return "".join(child[0] for child in content)

    def visit_double_quoted_string(self, node, visited_children):
        """Extracts the content of a double-quoted string."""
        _, content, _ = visited_children
        return "".join(child[0] for child in content)

    def visit_content_single(self, node, visited_children):
        """Returns the content of a single-quoted string."""
        return node.text

    def visit_content_double(self, node, visited_children):
        """Returns the content of a double-quoted string."""
        return node.text

    def visit_escaped_sequence(self, node, visited_children):
        """Returns the escaped sequence as is."""
        return node.text

    def visit_annotation(self, node, visited_children):
        """Returns the annotation as a string."""
        return node.text.strip()

    def visit_modifier(self, node, visited_children):
        """Returns the modifier as a string."""
        return node.text.strip()

    def visit_type(self, node, visited_children):
        """Returns the type as a string."""
        return node.text.strip()

    def visit_name(self, node, visited_children):
        """Returns the name as a string."""
        return node.text.strip()

    def visit_return_type(self, node, visited_children):
        """Returns the return type as a string."""
        return node.text.strip()

    def visit_argument_string(self, node, visited_children):
        """Returns the argument string as a string."""
        _, _, arguments_content, _, _ = visited_children
        return "".join(arguments_content)

    def visit_arguments_content(self, node, visited_children):
        """Returns the arguments content as a string."""
        return node.text.strip()

    def visit_code_block(self, node, visited_children):
        """Returns the code block as a string."""
        block_string_or_equals, _ = visited_children
        return (
            block_string_or_equals[0]
            if isinstance(block_string_or_equals[0], str)
            else None
        )

    def visit_block_string(self, node, visited_children):
        """Returns the block string as a string."""
        _, _, block_content, _, _, _ = visited_children
        return "".join(block_content)

    def visit_block_content(self, node, visited_children):
        """Returns the block content as a string."""
        return node.text.strip()

    def visit_class_extends(self, node, visited_children):
        _, _, class_type, _ = visited_children
        return class_type.strip()

    def visit_constructor(self, node, visited_children):
        """Returns the constructor as a string."""
        factory, _, name, _, arguments, _, initializer, _, block = visited_children

        # Put factory with name if factory is a string
        if isinstance(factory, str):
            name = factory + " " + name

        if isinstance(initializer, list):
            initializer = initializer[0].text.strip()

        return Constructor(
            name=name,
            parameters=arguments,
            initializer=initializer,
            body=block,
        )

    def visit_constructor_initializer(self, node, visited_children):
        """Returns the constructor initializer as a string."""
        _, _, _, initializer = visited_children
        return initializer

    def visit_optional_equals(self, node, visited_children):
        """Returns the equals sign as a string."""
        return node.text

    def visit_class_declaration(self, node, visited_children):
        """Constructs a DartClass from its constituent parts parsed by child nodes."""
        (
            _,
            annotations,
            _,
            _,
            _,
            _,
            name,
            _,
            parent_class,
            implements,
            _,
            _,
            declarations,
            _,
            _,
            _,
        ) = visited_children

        declarations = flatten(declarations)
        parent_class = parent_class[0] if isinstance(parent_class, list) else ""

        return DartClass(
            name=name,
            parent_class_name=parent_class,
            member_variables=[
                child for child in declarations if isinstance(child, Variable)
            ],
            imports=set(),
            class_body="",
            annotations=annotations,
            member_functions=[
                child for child in declarations if isinstance(child, Function)
            ],
        )

    def visit_variable_declaration(self, node, visited_children):
        """Parses a variable declaration to create a Variable namedtuple."""
        annotations, modifiers, var_type, _, name, default_value, semi = (
            visited_children
        )

        if not isinstance(annotations, list):
            annotations = []

        if not isinstance(modifiers, list):
            modifiers = []

        full_type = " ".join(modifiers + [var_type]) if modifiers else var_type

        return Variable(
            type=full_type,
            name=name,
            annotations=annotations,
            default_value=None,
        )

    def visit__(self, node, visited_children):
        """Returns the whitespace as a string."""
        return node.text

    def visit_function_declaration(self, node, visited_children):
        """Creates a Function instance from the node."""
        (_, annotations, modifier, return_type, name, _, parameters, _, body) = (
            visited_children
        )

        if not isinstance(annotations, list):
            annotations = []

        if not isinstance(modifier, Node):
            if isinstance(modifier, list):
                modifier = modifier[0]

            if isinstance(return_type, list):
                return_type = return_type[0]

            return_type = modifier + " " + return_type

        return Function(
            name=name,
            return_type=return_type,
            parameters=parameters,
            body=body,
            annotations=annotations,
        )

    def generic_visit(self, node, visited_children):
        """Default handling for nodes without specific visit methods."""
        if "Literal" in str(node.expr):
            return node.text

        return visited_children or node
