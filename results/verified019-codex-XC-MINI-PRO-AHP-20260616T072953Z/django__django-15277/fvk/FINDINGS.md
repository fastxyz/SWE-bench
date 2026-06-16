# FVK Findings: django__django-15277

Status: constructed, not machine-checked.

## F1: Pre-fix unbounded `CharField()` created an invalid max-length validator

Classification: code bug, fixed by V1.

Evidence: E1, E2, E3, E5, E7 in `fvk/SPEC.md`; PO1, PO2, and PO4 in
`fvk/PROOF_OBLIGATIONS.md`.

Input -> observed vs expected:

`Value('test')._resolve_output_field()` -> pre-fix behavior produced a
`CharField()` whose validators included `MaxLengthValidator(None)`; expected
behavior is an unbounded `CharField()` with no automatic max-length validator.

Reasoning:

The issue text identifies `MaxLengthValidator(None)` as both invalid and
extraneous for expression output fields. Because `Field.__init__()` defaults
`max_length` to `None`, the constructor must distinguish "no maximum exists"
from "a maximum exists with a non-`None` value". V1 discharges this by guarding the append
with `if self.max_length is not None`.

Recommended code/spec action:

Keep V1's constructor guard.

## F2: Bounded `CharField(max_length=L)` behavior must be preserved

Classification: compatibility condition, satisfied by V1.

Evidence: E3, E4, and E8 in `fvk/SPEC.md`; PO3 and PO5 in
`fvk/PROOF_OBLIGATIONS.md`.

Input -> observed vs expected:

`CharField(max_length=L)` -> expected to retain an automatic
`MaxLengthValidator(L)` for non-`None` `L`.

Reasoning:

The public issue asks only to avoid validator construction when there is no
maximum length. It explicitly proposes the `is not None` guard, and
`BinaryField` already uses that shape. V1 preserves bounded construction.

Recommended code/spec action:

No further code change.

## F3: Concrete model `CharField(max_length=None)` remains invalid by system check

Classification: frame condition, satisfied by V1.

Evidence: E6 in `fvk/SPEC.md`; PO6 in `fvk/PROOF_OBLIGATIONS.md`.

Input -> observed vs expected:

Concrete model `CharField()` -> expected `fields.E120` from
`_check_max_length_attribute()`; the fix must not silently make such model
fields valid.

Reasoning:

V1 changes only validator construction. The system-check method still reports
missing `max_length`, so model-field validity remains governed by checks while
internal expression output fields avoid the invalid runtime validator.

Recommended code/spec action:

No further code change.

## F4: No unresolved FVK proof obstacle was found

Classification: confirmation of V1 against this spec.

Evidence: all proof obligations in `fvk/PROOF_OBLIGATIONS.md`.

Input -> observed vs expected:

The audited input classes are unbounded construction, bounded construction, and
string `Value` output-field resolution. V1 satisfies the expected validator
state for each class.

Reasoning:

The formal claims preserve the property axis under test: the validator sequence
distinguishes the failing pre-fix state from the passing V1 state. The proof is
constructed but not machine-checked; no hidden test or evaluator signal was
used.

Recommended code/spec action:

Keep V1 unchanged. Keep any tests until the emitted K commands are actually
machine-checked and the normal Django test suite is run outside this restricted
session.
