# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Public Symbol

`django.contrib.admindocs.utils.trim_docstring(docstring)`

## Signature

Before V1 and after V1: one positional argument, `docstring`.

Compatibility result: pass. No callsite requires a signature update.

## Return Shape

Before V1 and after V1: a string is returned for in-scope inputs.

Compatibility result: pass. `parse_docstring()` continues to split a string,
and direct callers pass the string to `parse_rst()`.

## Public Call Sites Reviewed

- `parse_docstring(docstring)` in `repo/django/contrib/admindocs/utils.py`;
- model method documentation path in
  `repo/django/contrib/admindocs/views.py`;
- tag, filter, view, and model docstring parsing through
  `utils.parse_docstring()`.

Compatibility result: pass. These callsites depend on cleanup semantics, not on
the old local implementation.

## Imports and API Surface

V1 adds `from inspect import cleandoc` inside the implementation module. This
does not change public imports, exported names, function signatures, virtual
dispatch, subclass override contracts, storage formats, or template context
shapes.

Compatibility result: pass.
