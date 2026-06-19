"""Regression test for sphinx.pycode.ast.unparse() one-element tuple subscripts.

Issue #9367 reported that a one-element tuple ``(1,)`` was rendered without its
trailing comma as ``(1)``, silently turning a tuple into a scalar. The headline
fix patched ``visit_Tuple``, but the *sibling* ``visit_Subscript`` code path has
the identical defect: a one-element tuple slice ``obj[1,]`` is rendered as
``obj[1]``. These are semantically different subscripts -- ``obj[1,]`` calls
``__getitem__((1,))`` (a tuple key) while ``obj[1]`` calls ``__getitem__(1)``
(a scalar key) -- so dropping the comma is a correctness defect, not cosmetics.
This path is reachable from autodoc (preserve_defaults / annotations render
through unparse()).
"""

from sphinx.pycode import ast


def test_unparse_one_element_tuple_subscript():
    # A subscript whose slice is the one-element tuple (1,) must keep its
    # trailing comma so it round-trips to the same AST.
    source = "obj[1,]"
    module = ast.parse(source)
    assert ast.unparse(module.body[0].value, source) == "obj[1,]"


def test_unparse_multi_element_tuple_subscript_unchanged():
    # A multi-element tuple slice must be unaffected (no spurious comma, no
    # regression for the common case such as numpy/typing-style subscripts).
    source = "obj[1, 2]"
    module = ast.parse(source)
    assert ast.unparse(module.body[0].value, source) == "obj[1, 2]"
