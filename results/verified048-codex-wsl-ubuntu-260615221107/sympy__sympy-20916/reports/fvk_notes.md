# FVK Notes

## Decisions

V1 source code stands unchanged.

This decision traces to F-001 and PO-1/PO-2/PO-5: the V1 regex admits `ω` as
a Unicode word character while excluding digits and underscore from the base
capture, so `ω0` splits into base `ω` and subscript `0`; `pretty_symbol` then
has the subscript component needed to render `ω₀`.

I kept the V1 pattern rather than changing it to a direct greedy `\w+`
replacement because F-002 and PO-3 show that `\w` includes digits. A greedy
`^(\w+)([0-9]+)$` can split `x10` as base `x1` and suffix `0`, which conflicts
with the existing multi-digit suffix behavior.

I did not broaden the rule to internal digits or leading underscores. F-003 and
PO-4 classify those cases as outside the public intent for this issue, while
I5 requires explicit underscore handling to remain unchanged.

I did not edit tests because the task forbids modifying test files. Future test
recommendations are recorded in `fvk/ITERATION_GUIDANCE.md`.

I did not run tests, Python, or K tooling. F-005 and PO-7 record the proof as
constructed, not machine-checked, and list the commands that should be run in a
proper verification environment.

## Files Added

- `fvk/SPEC.md`: intent ledger, formal spec clauses, and non-executed K
  commands.
- `fvk/FINDINGS.md`: audit findings and V1 confirmation.
- `fvk/PROOF_OBLIGATIONS.md`: proof obligations tied to findings.
- `fvk/PROOF.md`: constructed proof and residual risks.
- `fvk/ITERATION_GUIDANCE.md`: V1-stands decision and future work.
- Additional FVK adequacy/formal-core files required by the FVK method:
  `INTENT_SPEC.md`, `PUBLIC_EVIDENCE_LEDGER.md`, `FORMAL_SPEC_ENGLISH.md`,
  `SPEC_AUDIT.md`, `PUBLIC_COMPATIBILITY_AUDIT.md`,
  `mini-symbol-conventions.k`, and `symbol-conventions-spec.k`.
