# Public Compatibility Audit

## Changed Public or Semi-Public Symbols

`sphinx.ext.autodoc.mock._MockObject.__getitem__`

- V1 changed the annotation from `str` to `Any`; arity and return behavior remain
  the same.
- Public compatibility status: compatible. Python subscription already permits
  arbitrary key objects at runtime, and the issue shows a non-string key reaching
  this path.

`sphinx.ext.autodoc.mock._make_subclass`

- V1 changed the annotation from `str` to `Any`; arity and returned value shape
  remain the same.
- Search found internal callers in `mock.py` only. Public compatibility status:
  compatible.

`sphinx.ext.autodoc.mock._make_subclass_name`

- New private helper. No public compatibility burden.

## Producer/Consumer Shape

- Existing string-name callers still produce generated mock subclasses with
  dotted display names.
- Generic subscription now produces generated mock subclasses using normalized
  string names. The consumer shape remains "generated class, then instance."

No unhandled public callsite, override, or return-shape incompatibility was
found.
