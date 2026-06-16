# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Intent Adequacy

The formal claims must express public intent rather than V1 behavior alone.

Discharge:

`INTENT_SPEC.md`, `PUBLIC_EVIDENCE_LEDGER.md`, `FORMAL_SPEC_ENGLISH.md`, and
`SPEC_AUDIT.md` connect each claim to issue text and public docs. No claim uses
legacy behavior as the expected behavior.

## PO2: No Automatic XRef for Variable Field Labels

For every variable field name `N`, body `C`, and object inventory `O`,
rendering a Python `var`/`ivar`/`cvar` field must produce a plain label for
`N`, not a pending or resolved reference.

Formal claim:

`VARIABLE-FIELD-NO-XREF` in `fvk/sphinx-fields-spec.k`.

Implementation discharge:

`repo/sphinx/domains/python.py` no longer gives the `variable` typed field a
`rolename`. `repo/sphinx/util/docfields.py` returns plain content when
`rolename` is falsey.

## PO3: Preserve Variable Type Links

For every variable type name `T`, `:vartype:` and inline typed variable fields
must remain eligible for Python type cross-reference generation.

Formal claim:

`VARIABLE-FIELD-WITH-TYPE-PRESERVES-TYPE-XREF` in
`fvk/sphinx-fields-spec.k`.

Implementation discharge:

`typerolename='class'` remains unchanged on the variable typed field.

## PO4: Preserve Explicit References

User-authored explicit roles such as `:py:data:`, `:py:const:`, or `:py:attr:`
remain the supported way to link related objects.

Formal claim:

`EXPLICIT-REFERENCE-STILL-LINKS` in `fvk/sphinx-fields-spec.k`.

Implementation discharge:

No role table, `PyXrefMixin`, or resolver code was changed.

## PO5: Rule Out Incomplete Alternatives

The proof must cover same-module and cross-project same-name objects. A fix that
only removes suffix/fuzzy lookup would leave same-module fallback intact.

Discharge:

The selected fix prevents the field-label `pending_xref` from being created, so
no resolver path is entered for the label in any inventory case.

## PO6: Honesty Gate

The FVK proof must be labeled constructed, not machine-checked, and no tests may
be removed based on this session.

Discharge:

`PROOF.md` includes exact commands but states they were not executed. No tests
were modified or recommended for unconditional removal.
