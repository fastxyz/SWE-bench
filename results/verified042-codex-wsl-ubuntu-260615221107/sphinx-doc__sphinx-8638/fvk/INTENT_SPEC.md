# Intent Spec

Status: constructed for FVK audit, not machine-checked.

## Scope

This audit covers the Python-domain info-field behavior involved in issue
`sphinx-doc__sphinx-8638`: rendering `:var:`, `:ivar:`, and `:cvar:` field
arguments inside Python object descriptions, and preserving related type and
explicit-reference behavior.

## Intent-Derived Obligations

1. Variable field names are descriptions of the variable being documented. They
   must not be automatically converted into cross-references to any other Python
   object with the same short name.

2. The no-implicit-link rule covers module-level variables, variables in other
   subpackages, and attributes on other classes. The fact that another object
   has the same name is not evidence that it is related.

3. If users want a relationship to another variable or constant, they can write
   an explicit cross-reference such as `:py:const:` or another Python role.
   Explicit roles are outside the automatic field-label behavior and must keep
   their normal resolution behavior.

4. `:vartype:` and inline typed variable fields must still link type names when
   possible. Public documentation specifically says `vartype` creates a link if
   possible, while `var`/`ivar`/`cvar` are described only as variable
   descriptions.

5. The fix should be localized to source behavior. Public method signatures,
   constructor signatures, object inventory storage, and explicit Python-domain
   cross-reference resolution should not change unless required by the issue.

## Candidate Behavior Checked

V1 removes `rolename='obj'` from the Python-domain `variable` field definition.
Because `Field.make_xref()` returns plain content when `rolename` is falsey,
variable field arguments no longer create `pending_xref` nodes. Without a
`pending_xref`, `PythonDomain.find_obj()` cannot resolve the field label to a
module variable or unrelated attribute. The candidate still leaves
`typerolename='class'` in place for `vartype` handling and does not modify
explicit Python roles.
