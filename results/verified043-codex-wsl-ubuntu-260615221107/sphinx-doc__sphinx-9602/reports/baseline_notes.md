# Baseline Notes

## Root Cause

`sphinx.domains.python._parse_annotation()` parses a type annotation into a flat list
of text and signature punctuation nodes, then turns every non-empty text node into a
Python-domain cross-reference. In annotations such as `Literal[True]`, the `True`
argument is an AST constant value, not a type name, but it was emitted as plain text
and then converted into a `py:class` pending reference. With nitpick enabled, that
pending reference produced a missing-reference warning because `True` is not a class.

## Changed Files

- `repo/sphinx/domains/python.py`: added recognition for `Literal`,
  `typing.Literal`, and `typing_extensions.Literal` while parsing annotation
  subscripts. The parser now preserves literal argument values as plain signature
  text, using `repr()` for constants in the `Literal[...]` argument list, and skips
  cross-reference conversion while walking that bracketed literal-value region.
  Normal annotation names outside the literal argument list continue to become
  Python-domain references.

## Assumptions and Rejected Alternatives

- I assumed the intended behavior is that `Literal` itself can still be referenced as
  a typing object, but its values are data values and should not be treated as
  class/object targets.
- I treated string, numeric, boolean, `None`, ellipsis, and dotted literal values
  inside `Literal[...]` as non-reference text. This matches the issue wording about
  literal values rather than only special-casing booleans.
- I considered changing the missing-reference resolver to silently ignore unresolved
  `True` and `False` class references. I rejected that because it would leave the
  doctree incorrectly modeling literal values as class references and would only
  cover a subset of valid `Literal` values.
- I did not modify tests, per the benchmark instructions, and I did not run tests or
  project code in this session.
