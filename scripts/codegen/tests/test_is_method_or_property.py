from .. import codegen


def test_valid_method():
    line = "void myMethod(String arg) {"
    assert codegen.DartClassParser.is_method_or_property(line)


def test_valid_property():
    line = "String get myProperty {"
    assert codegen.DartClassParser.is_method_or_property(line)


def test_invalid_line():
    line = "This is not a method or property"
    assert not codegen.DartClassParser.is_method_or_property(line)


def test_variable():
    line = "String myVariable;"
    assert not codegen.DartClassParser.is_method_or_property(line)


def test_method_without_return_type():
    line = "myMethod(String arg) {"
    assert not codegen.DartClassParser.is_method_or_property(line)


def test_method_without_arguments():
    line = "void myMethod() {"
    assert codegen.DartClassParser.is_method_or_property(line)


def test_property_with_arguments():
    line = "void set myProperty(String arg) {"
    assert codegen.DartClassParser.is_method_or_property(line)
