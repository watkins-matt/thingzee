import os
import sys

from lark import Discard, Lark, Token, Transformer, Tree, UnexpectedCharacters

from dart import DartClass, DartFile, Type, Variable
from parser.base import Parser


class LarkParser(Parser):
    def __init__(self, grammar_file_path: str):
        with open(grammar_file_path) as grammar:
            self.parser = Lark(grammar.read(), start="start")

    def parse(self, text: str, filename: str = None):
        filename = "" if filename is None else filename

        try:
            parse_tree = self.parser.parse(text)
        # Handle UnexpectedCharacters
        except UnexpectedCharacters as e:
            filename = os.path.basename(filename)
            print(f"Parse Error: {filename} {e.line}:{e.column}")
            print(f"Unexpected: {e.char}")
            print(f"Allowed: {e.allowed}")
            print(f"Context: {e.get_context(text)}")
            sys.exit(1)
        dart_file = DartTransformer().transform(parse_tree)
        return dart_file


class DartTransformer(Transformer):
    def start(self, items):
        classes = [item for item in items if isinstance(item, DartClass)]
        imports = set(item for item in items if isinstance(item, str))
        return DartFile(classes, imports)

    def import_statement(self, items):
        import_value = items[0].value

        # Remove quotes if present
        if import_value.startswith(("'", '"')):
            import_value = import_value[1:-1]

        if import_value.endswith(("'", '"')):
            import_value = import_value[:-1]

        return import_value

    def declaration(self, items):
        return items[0]

    def modifier(self, items):
        if len(items) == 0:
            return Discard
        return items[0].value

    def type(self, items):
        return Type(items[0].value)

    def variable_declaration(self, items):
        var_type = ""
        var_name = ""

        for item in items:
            if isinstance(item, Type):
                var_type = item.name
            elif isinstance(item, Token):
                var_name = item.value

        return Variable(
            type=var_type, name=var_name, annotations=[], default_value=None
        )

    def class_declaration(self, items):
        name = ""
        member_variables = []
        parent_class_name = None

        for item in items:
            if isinstance(item, Token) and item.type == "NAME":
                name = item.value
            if isinstance(item, Tree) and item.data == "class_parent":
                parent_class_name = item.children[0].name
            # Check if the item is a declaration tree containing an Attribute
            if isinstance(item, Variable):
                member_variables.append(item)

        return DartClass(name, parent_class_name, member_variables, set(), "", True)
