# FVK Findings

Status: constructed, not machine-checked.

## F1: Original cutoff bug

Input: `Decimal('1e-200')`, `decimal_pos=2`, decimal separator `"."`.

Observed before the fix, from the public issue: `'1.00e-200'`.

Expected from intent E3: `'0.00'`.

Classification: code bug.

Trace: Proof obligation PO1 and claim C1. The cutoff branch selected
scientific notation before the fixed-width decimal truncation could produce
zeros.

Resolution: V2 keeps the fixed-zero shortcut inside the cutoff branch.

## F2: Suspect legacy public-test expectation

Input family: very small `Decimal` values such as
`Decimal('0.' + '0' * 299 + '1234')` with `decimal_pos=3`.

Observed in public tests: expected `'1.234e-300'`.

Expected from public issue intent E3: `'0.000'`, because the value is smaller
than the smallest nonzero value encodable with three decimal places.

Classification: stale or legacy test evidence, not an intent source.

Trace: Proof obligation PO2 and claim C3.

Resolution: Do not preserve this expectation in the production code. The task
forbids editing tests, so no test file was changed.

## F3: V1 residual zero-valued Decimal gap

Input: a zero-valued `Decimal` with a large exponent, for example
`Decimal('0E-200')` and `decimal_pos=200`.

Observed in V1 by inspection: the nonzero threshold
`exponent + len(digits) <= -decimal_pos` can be false for zero, allowing the
200-digit cutoff to choose scientific notation.

Expected from default decimal formatting intent: zero is exactly representable
at every non-negative fixed width, so the output should be fixed zero.

Classification: code bug found by FVK audit.

Trace: Proof obligation PO3 and claim C2.

Resolution: V2 explicitly checks `number.is_zero()` before applying the
nonzero adjusted-exponent threshold.

## F4: Decimal subclass compatibility risk

Input: a `Decimal` subclass with a custom `__format__()` method and a tiny value
that triggers the cutoff.

Observed in V1/V2 before refinement: the fixed-zero shortcut synthesized the
literal string `"0"` or `"-0"`, which could bypass subclass formatting.

Expected from public test E6: normal `Decimal` subclass formatting should be
preserved where feasible.

Classification: compatibility risk.

Trace: Proof obligation PO6.

Resolution: V2 confines the shortcut to the cutoff branch so ordinary
non-cutoff subclass formatting is untouched, and formats a same-class zero
surrogate in the cutoff shortcut when construction succeeds.

## F5: Proof capability boundary

Input: any behavior depending on full Python `Decimal` internals, localization
settings, grouping loops, or arbitrary subclass constructors.

Observed: the FVK model abstracts these into `FixedZero`, `Scientific`, and
`Other` states.

Expected: the proof must not claim more than this abstraction can distinguish.

Classification: proof capability gap / trusted base.

Trace: Proof obligations PO7 and PO8.

Resolution: The proof is explicitly limited to the cutoff decision and fixed
zero output shape. Existing non-cutoff paths and unrelated formatting behavior
are frame conditions, not formally machine-checked here.
