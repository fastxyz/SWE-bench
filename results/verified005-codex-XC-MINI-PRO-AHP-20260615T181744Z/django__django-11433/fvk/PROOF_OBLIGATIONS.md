# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Non-empty derived cleaned data overwrites a default

Public evidence: E1, E2, E3.

Formal claim: `CI-DERIVED-NONEMPTY-ASSIGNS`.

Precondition: field is eligible; `hasDefault=true`; `omittedFromData=true`;
`cleanedEmpty=false`; `isFile=false`.

Postcondition: action is `assign(name, cleanedValue)`.

V1 result: discharged by the source condition at
`repo/django/forms/models.py:51-55`; the skip does not fire when the cleaned
value is not in `form_field.empty_values`, so line 61 assigns it.

## PO-2: Omitted empty cleaned values preserve defaults

Public evidence: E4.

Formal claim: `CI-OMITTED-EMPTY-PRESERVES-DEFAULT`.

Precondition: field is eligible; `hasDefault=true`; `omittedFromData=true`;
`cleanedEmpty=true`.

Postcondition: action is `skip`.

V1 result: discharged. The skip fires exactly for this conjunction.

## PO-3: Submitted blank and non-omitted widget values are assigned

Public evidence: E5, E6.

Formal claim: `CI-SUBMITTED-EMPTY-ASSIGNS`.

Precondition: field is eligible; `hasDefault=true`; `omittedFromData=false`;
`cleanedEmpty=true`; `isFile=false`.

Postcondition: action is `assign(name, empty)`.

V1 result: discharged. The skip requires `omittedFromData=true`, so submitted
blank values and widgets that report not omitted continue to assign.

## PO-4: Non-default fields are not affected by the default skip

Public evidence: E3 and existing control-flow intent.

Formal claim: `CI-NONDEFAULT-OMITTED-EMPTY-ASSIGNS`.

Precondition: field is eligible; `hasDefault=false`; `isFile=false`.

Postcondition: action is `assign(name, cleanedValue)`.

V1 result: discharged. The new branch is under `if f.has_default()`.

## PO-5: File fields retain delayed assignment

Public evidence: E8.

Formal claim: `CI-DERIVED-FILE-QUEUES`.

Precondition: field is eligible; `isFile=true`; the default-preservation skip
does not fire.

Postcondition: action is `queueFile(name, cleanedValue)`, corresponding to
append to `file_field_list` and later `save_form_data()`.

V1 result: discharged. V1 changes only the skip predicate before the existing
file-field branch and leaves delayed save code unchanged.

## PO-6: Ineligible fields are skipped

Public evidence: E3 and existing `construct_instance()` filters.

Formal claims: `CI-INELIGIBLE-NOT-EDITABLE-SKIPS`,
`CI-INELIGIBLE-AUTO-SKIPS`, `CI-INELIGIBLE-NOT-IN-CLEANED-SKIPS`,
`CI-INELIGIBLE-NOT-IN-FIELDS-SKIPS`, and
`CI-INELIGIBLE-EXCLUDED-SKIPS`.

Precondition: any of editable=false, isAuto=true, inCleaned=false,
fieldsAllowed=false, or excluded=true.

Postcondition: action is `skip`.

V1 result: discharged. The V1 edit happens after all existing eligibility
filters.

## PO-7: Public compatibility is preserved

Public evidence: E9 and `PUBLIC_COMPATIBILITY_AUDIT.md`.

Formal claim: compatibility audit rather than K state claim.

Precondition: existing public callers and hook implementors use the old
signature and hook shapes.

Postcondition: no new argument, return type, dispatch protocol, or data shape is
required.

V1 result: discharged. No compatibility source edit is needed.

## PO-8: Explicit empty override ambiguity is not discharged

Public evidence: E10 and ambiguity A1.

Formal claim: none; this is intentionally not encoded as expected assignment or
expected skip because public intent is insufficient.

Precondition: omitted defaulted field whose cleaned value is empty but was
deliberately reassigned by custom cleaning.

Status: unresolved/underspecified. This does not block V1 because PO-1 through
PO-7 cover the public issue and frame conditions.
