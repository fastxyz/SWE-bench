# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Missing `to` is not an exceptional relational case

Statement: for any relational field with `D(field) = (path, args, kwargs)` and `"to" not in kwargs`, normalization returns `(path, args, kwargs)` and does not raise.

Public evidence: I-001, I-002, I-003.

V1 discharge: Python `dict.pop('to', None)` returns the default and leaves the dictionary unchanged when the key is absent.

Result: discharged by V1.

## PO-002: Present `to` is removed for relational fields

Statement: for any relational field with `D(field) = (path, args, kwargs)` and `"to" in kwargs`, normalization returns `(path, args, kwargs without "to")`.

Public evidence: I-003, I-004.

V1 discharge: `dict.pop('to', None)` removes the key when present.

Result: discharged by V1.

## PO-003: Relational status comes from the field object, not serialized kwargs

Statement: `Rel(field)` and membership of `"to"` in `D(field).kwargs` are independent facts; the helper must handle all combinations where `Rel(field)` is true.

Public evidence: I-002.

V1 discharge: the branch still checks `field.remote_field and field.remote_field.model`, and the branch body is total for both key-present and key-absent dictionaries.

Result: discharged by V1.

## PO-004: Non-relational fields are unchanged

Statement: when `Rel(field)` is false, the returned deconstruction equals `D(field)` exactly.

Public evidence: I-004.

V1 discharge: V1 did not change the branch condition or the non-relation path; `pop()` is not executed.

Result: discharged by V1.

## PO-005: Loop preserves cardinality and sorted-name order

Statement: the output list contains one normalized deconstruction for each field in `fields`, in `sorted(fields.items())` order, and does not include field names in the deconstruction entries.

Public evidence: I-004 and the source loop structure.

V1 discharge: V1 changes only the dictionary-key removal operation inside the existing loop; it does not change iteration, append behavior, or use of the field name.

Result: discharged by V1.

## PO-006: Public compatibility and adjacent call paths are unchanged

Statement: the fix must not change the helper's signature, return shape, call sites, or unrelated renamed-field behavior.

Public evidence: I-006.

V1 discharge: the method signature and returned list shape are unchanged. The only source edit is internal to relation-target removal. The adjacent `generate_renamed_fields()` access to `old_field_dec[2]['to']` already has a membership guard.

Result: discharged by V1.

## PO-007: `kwargs` is a dictionary

Statement: the proof assumes `D(field).kwargs` is a finite dictionary.

Public evidence: I-005.

V1 discharge: Django's field deconstruction contract documents the fourth value as "A dict of keyword arguments", and `deep_deconstruct()` already relies on `kwargs.items()`.

Result: discharged for in-contract fields; malformed custom fields are out of scope for this issue.

## PO-008: Honesty gate for verification

Statement: because no K tooling or tests can be run, all proof results must be labeled constructed, not machine-checked, and no tests may be removed.

Public evidence: user task restrictions and FVK verify documentation.

V1 discharge: source stands unchanged after the FVK audit; artifacts record non-execution, and no tests are modified.

Result: discharged.
