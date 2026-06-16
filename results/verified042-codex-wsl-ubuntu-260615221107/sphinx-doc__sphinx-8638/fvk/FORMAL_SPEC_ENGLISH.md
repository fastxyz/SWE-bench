# Formal Spec in English

Status: constructed, not machine-checked.

## Claim: VARIABLE-FIELD-NO-XREF

For every variable name, field body, and possible same-name object inventory,
rendering a Python `var`/`ivar`/`cvar` field whose role is `noRole` results in a
rendered field with a plain label and plain body. The label is not a pending
cross-reference and cannot become a link to a module variable, same-class
attribute, other-class attribute, or suffix match.

## Claim: VARIABLE-FIELD-WITH-TYPE-PRESERVES-TYPE-XREF

For every variable name, type name, field body, and possible same-name object
inventory, rendering a variable field with no field-label role but with a
`classRole` type role produces a plain variable label, a pending type
cross-reference for the type name, and the plain body. The fix therefore
preserves `:vartype:` link behavior while removing only the variable label's
implicit object reference.

## Claim: EXPLICIT-REFERENCE-STILL-LINKS

An explicit user-authored Python data reference with a matching module-level
object still resolves to a link. This claim frames the fix: the automatic
variable-field label is changed, but explicit cross-reference roles remain the
user-controlled way to link related variables or constants.

## Adequacy Summary

These claims match the public issue and docs: variable documentation labels must
not auto-link to same-name objects, type references must continue linking if
possible, and explicit references remain opt-in link syntax.
