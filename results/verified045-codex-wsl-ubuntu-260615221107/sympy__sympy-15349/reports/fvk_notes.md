# FVK Notes

## Decision

V1 stands unchanged. The FVK audit confirmed that the reported bug is the sign
of `M12` in `Quaternion.to_rotation_matrix()`, and V1 already changed it from
`2*s*(q.c*q.d + q.b*q.a)` to `2*s*(q.c*q.d - q.b*q.a)`.

## Trace to Findings and Proof Obligations

- Kept the V1 `M12` sign change because F1 identifies the pre-fix behavior as
  the reported bug, and PO2 proves from Hamilton multiplication that the
  coefficient of `z` in the rotated `y` component is `2*(c*d - a*b)/N`.
- Confirmed the issue reproducer because PO3 specializes the formula to
  `Quaternion(cos(x/2), sin(x/2), 0, 0)` and derives `(1, 2) = -sin(x)` and
  `(2, 1) = sin(x)`.
- Did not flip `M21` or change the overall active/passive convention because
  PO4 shows the existing z-axis docstring example remains correct, and PO5
  shows `from_rotation_matrix()` sign recovery requires `M21 - M12 = 4*a*b/N`.
- Did not edit tests because F2 classifies the visible `Quaternion(1, 2, 3, 4)`
  expectation as SUSPECT legacy evidence, while PO7 records that this benchmark
  forbids test-file changes.
- Did not add a zero-quaternion guard because F3 and PO1 make the nonzero
  quaternion requirement an explicit verified-domain precondition. A guard or
  documentation update would be a separate API-hardening change beyond the
  reported sign issue.
- Did not run verification commands because F4 and PO8 record the FVK honesty
  gate: K commands are emitted in `fvk/PROOF.md`, but this task forbids running
  K tooling.

## Artifacts Written

The required FVK artifacts are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Additional FVK adequacy and machine-check sketches were written under `fvk/`:
`mini-quaternion.k`, `quaternion-rotation-spec.k`, `INTENT_SPEC.md`,
`PUBLIC_EVIDENCE_LEDGER.md`, `FORMAL_SPEC_ENGLISH.md`, `SPEC_AUDIT.md`, and
`PUBLIC_COMPATIBILITY_AUDIT.md`.
