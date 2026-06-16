# Spec Audit

Status: adequacy audit of `FORMAL_SPEC_ENGLISH.md` against `INTENT_SPEC.md`.

## C1: `NONFORM-UNBOUND`

Result: pass.

Reason: I4 places `formset.non_form_errors()` itself in scope, and I3 mirrors
the form `nonfield` convention where even an empty `ErrorList` is constructed
with the extra class.

## C2: `NONFORM-CLEAN`

Result: pass.

Reason: I1 and I2 require every formset non-form error list to carry `nonform`;
an empty clean result must still expose the constructor-time signal for custom
`ErrorList` subclasses per I3.

## C3: `NONFORM-MANAGEMENT`

Result: pass.

Reason: management-form errors are appended to `_non_form_errors` and are
accessed through `formset.non_form_errors()`, so I1, I2, and I4 apply.

## C4: `NONFORM-VALIDATION`

Result: pass.

Reason: max/min/custom `clean()` validation errors are the primary
formset-level non-form errors named by I1 and I4.

## C5: `PREFIX-DISCRIMINATOR`

Result: pass.

Reason: the model must distinguish legacy and fixed behavior. E6 confirms
legacy public tests encoded the no-`nonform` rendering, but the issue marks
that behavior as buggy.

## Adequacy conclusion

The formal claims are neither weaker nor stronger than the public issue intent
for the audited observable. They do not prove unrelated per-form non-field
error behavior, and they do not rely on suspect legacy tests to preserve the
old class string.
