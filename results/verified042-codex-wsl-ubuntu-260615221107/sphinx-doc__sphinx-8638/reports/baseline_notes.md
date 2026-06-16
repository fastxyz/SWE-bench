# Baseline Notes

## Root cause

Python object descriptions define `:var:`, `:ivar:`, and `:cvar:` as typed
fields whose field argument is automatically converted into a `:py:obj:`
cross-reference.  A variable field argument is the name being documented, not
an explicit request to link to another object.  Because `:py:obj:` references
use the Python domain's contextual and suffix-based lookup, an instance
variable field such as `:ivar limit:` can resolve to an unrelated module-level
variable or to an attribute with the same short name elsewhere in the project.

## Changed files

`repo/sphinx/domains/python.py`

Removed `rolename='obj'` from the Python domain's `variable` doc field
definition.  Variable field names are now rendered like parameter field names:
as field labels, without an automatic object cross-reference.  The field's
type role remains `class`, so `:vartype:` and inline typed variable fields
still create type links.  Explicit user references such as `:py:attr:`,
`:py:data:`, and `:py:obj:` are unchanged.

## Assumptions and rejected alternatives

I assumed the bug is caused by automatically generated links from variable
field names, which is the path used by autodoc/apidoc-generated class
documentation containing `:ivar:`, `:cvar:`, or `:var:` fields.

I considered narrowing `PythonDomain.find_obj()` so that fuzzy lookup would not
return attributes or data objects.  I rejected that because it would still leave
same-module fallbacks such as `module.limit` available when documenting
`Class.limit`, and it would alter explicit cross-reference behavior globally.

I also considered changing variable fields from `obj` links to `attr` links.
That would avoid module-level data links, but unrelated class attributes with
the same short name could still be selected by suffix lookup.  It would also
continue treating a variable field label as an implicit cross-reference, which
is the behavior that caused the issue.

No tests or project code were run, per the benchmark instructions.
