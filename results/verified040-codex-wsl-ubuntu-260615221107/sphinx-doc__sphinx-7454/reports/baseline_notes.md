# Baseline Notes

## Root cause

`autodoc_typehints = "signature"` renders annotations through the Python
domain signature parser, specifically `_parse_annotation()` in
`sphinx/domains/python.py`. That helper created `pending_xref` nodes for every
annotation token with `reftype="class"`.

For most type annotations this is correct, but `None` is not documented as a
Python class. The field-list path used by `autodoc_typehints = "description"`
already special-cases `None` in `PyField` and `PyTypedField`, changing the
reference role from `class` to `obj`. Because signature annotations lacked the
same special case, `-> None` could not resolve to the Python documentation entry
for the `None` singleton while `-> int` still resolved normally.

## Changed files

- `repo/sphinx/domains/python.py`
  - Updated `_parse_annotation()` so its internal `make_xref()` helper uses
    `reftype="obj"` when the annotation text is exactly `None`, and keeps
    `reftype="class"` for all other annotation tokens.
  - This aligns signature annotation references with the existing behavior of
    return type field rendering without changing autodoc signature generation,
    Python domain object registration, or non-`None` type annotation handling.

## Assumptions

- The expected link target for `None` is the Python object/constant target, not
  a class target. This follows the existing `PyField` and `PyTypedField`
  special cases and the issue's description of linking to the Python
  documentation for the `None` singleton.
- The fix should apply to all signature annotation positions parsed by
  `_parse_annotation()`, including parameter annotations and return
  annotations, because both are rendered by the same helper and `None` has the
  same object-vs-class issue in either position.
- The literal string `None` is the intended special case. Names such as
  `NoneType` or expressions containing `None` that the parser cannot decompose
  were left unchanged because the reported inconsistency is for direct
  `None` annotations.

## Alternatives considered

- Changing `sphinx.util.typing.stringify()` or autodoc's signature formatting
  was rejected because both signature and description modes already stringify
  `type(None)` as `None`; the issue occurs later, when signature annotation text
  is converted into cross-reference nodes.
- Changing the missing-reference resolver was rejected because description mode
  already uses the correct role up front, and the signature parser should emit
  the same kind of pending reference rather than relying on a later fallback.
- Treating every annotation as `py:obj` was rejected because normal type
  annotations such as `int` and `List` are intentionally class references in the
  existing parser.
