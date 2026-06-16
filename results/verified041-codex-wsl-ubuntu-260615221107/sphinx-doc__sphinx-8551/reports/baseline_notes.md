# Baseline Notes

## Root cause

Python-domain doc fields such as `:type:`, inline `:param Type name:`, and
`:rtype:` create pending references through `PyXrefMixin` and the generic
doc-field helpers, not through `PyXRefRole`. Unlike explicit Python xref roles,
that path did not copy the current Python reference context (`py:module` and
`py:class`) onto the pending reference.

At the same time, `PyXrefMixin.make_xref()` marked every field-generated Python
reference as `refspecific`. During resolution, that asks `PythonDomain.find_obj()`
to fall back to suffix-wide fuzzy lookup. For an unqualified type like `A`, the
field reference could therefore search all documented modules, report false
ambiguity, or pick the wrong suffix match instead of resolving relative to the
current module like an explicit `:py:class:` reference.

## Changed files

`repo/sphinx/domains/python.py`

- Added `PythonDomain.process_field_xref()` so field-generated Python xrefs get
  the same `py:module` and `py:class` context that `PyXRefRole.process_link()`
  adds for explicit roles.
- Changed `PyXrefMixin.make_xref()` to set `refspecific` only for targets that
  begin with `.`, matching the explicit Python role behavior. Tilde-only targets
  still get their display text shortened, but no longer trigger fuzzy lookup.

## Assumptions and alternatives

I assumed field-generated Python type references should follow explicit Python
xref lookup semantics because the issue compares `:type:` / `:rtype:` directly
to `:py:class:` and expects current-module resolution.

I considered fixing only the missing `py:module` / `py:class` context. That would
fix the main current-module example, but it would leave non-module-scope field
references in `refspecific` fuzzy mode, which matches the public hint about
silently wrong cross-references.

I also considered changing `find_obj()` to special-case field references, but
that would broaden the behavior of the resolver. Keeping the change in
field-reference construction is smaller and keeps the existing explicit-role
resolver semantics intact.
