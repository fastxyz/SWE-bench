# FVK Notes

## Decisions

D-001: Revise V1 instead of leaving it unchanged.

Trace: `fvk/FINDINGS.md` F-001 and `fvk/PROOF_OBLIGATIONS.md` PO-002 show that
V1 forced only the top-level `im` call. The revised code wraps the whole probe
in `with evaluate_context(True)`, so helper constructors inside `im.eval` also
use evaluated semantics. This discharges PO-001, PO-002, and PO-005 in the
constructed model.

D-002: Keep the original truthiness-based rejection once inside evaluated mode.

Trace: F-003 and PO-003 require preserving the existing behavior that numeric
coordinates with nonzero evaluated imaginary parts raise
`ValueError('Imaginary coordinates are not permitted.')`. Replacing the check
with only `im(a).is_zero is False` was rejected because it would alter
indeterminate numeric behavior beyond the issue.

D-003: Keep the `a.is_number` boundary.

Trace: F-004 and PO-004 require preserving documented symbolic-coordinate
acceptance. The code still checks `a.is_number and im(a)`, only under a
temporary evaluated context.

D-004: Do not edit parser, `sympify`, public signatures, or tests.

Trace: F-002 localizes the failure to `Point.__new__` validation, and PO-006
requires preserving parser behavior and public API shape. Tests are fixed and
hidden for this task, and F-005/PO-007 require no execution or test edits.

## Source Changes

`repo/sympy/geometry/point.py`

- Imported `evaluate` from `sympy.core.parameters` as `evaluate_context`.
- Wrapped the imaginary-coordinate validation in `with evaluate_context(True)`.

No other source files were changed.

## Verification Status

The artifacts in `fvk/` include the requested FVK notes plus the formal core
required by the FVK documentation:

- `SPEC.md`, `FINDINGS.md`, `PROOF_OBLIGATIONS.md`, `PROOF.md`,
  `ITERATION_GUIDANCE.md`.
- `mini-sympy-point.k` and `point-imaginary-validation-spec.k`.
- Intent, evidence, formal-English, spec-audit, and compatibility-audit files.

The proof is constructed, not machine-checked. No tests, Python code, or K
tooling were run.
