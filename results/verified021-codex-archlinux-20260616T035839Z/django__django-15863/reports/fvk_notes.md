# FVK Notes

## Decisions

No additional source edit was made after V1. This is justified by finding F-002
and proof obligations PO-2 and PO-3: for Decimal input, V1 assigns `d = text`,
so the exact Decimal value reaches the existing quantize/render path instead of
the `float()` fallback that finding F-001 identifies as the original bug.

The V1 choice to special-case only `Decimal` values was kept. Finding F-003 and
PO-4 reject the broader alternative of changing all initial conversion from
`repr(text)` to `str(text)`, because the public issue is Decimal-specific and
non-Decimal behavior is covered by existing public docs/tests.

The V1 `input_val = str(text)` choice for Decimal values was kept. The
compatibility audit records that invalid Decimal arguments may now display a
numeric Decimal string rather than `Decimal('...')`; no public evidence requires
the Python repr, and PO-5 confirms the public API shape is unchanged.

No tests were modified or run. PO-6 and the task instructions require all
proofs to remain constructed, not machine-checked, and forbid test edits or
execution.

## Artifacts

The required artifacts are under `fvk/`: `SPEC.md`, `FINDINGS.md`,
`PROOF_OBLIGATIONS.md`, `PROOF.md`, and `ITERATION_GUIDANCE.md`.

The additional FVK core required by the method docs is also under `fvk/`:
`INTENT_SPEC.md`, `PUBLIC_EVIDENCE_LEDGER.md`, `FORMAL_SPEC_ENGLISH.md`,
`SPEC_AUDIT.md`, `PUBLIC_COMPATIBILITY_AUDIT.md`, `mini-floatformat.k`, and
`floatformat-spec.k`.
