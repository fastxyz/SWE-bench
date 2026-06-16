# FVK Notes

## Source Decision

I kept V1 unchanged. `fvk/FINDINGS.md` F1 identifies the actual bug as returning the first attrs mapping for `combine_attrs="override"`, and `fvk/PROOF_OBLIGATIONS.md` PO2 requires the result mapping to be distinct from `variable_attrs[0]`. The V1 source line `return dict(variable_attrs[0])` discharges PO2 while preserving PO1's first-input contents requirement.

## Why No Additional Code Change Was Made

- No deep copy: F2 and PO5 say the public issue requires independence of the attrs dictionary, not deep copies of attr values. A deep copy would exceed the evidence and could change user-visible value identity.
- No empty-input change: F3 and PO6 say `merge_attrs([], ...) -> None` has no source attrs mapping to alias and is outside the reported defect.
- No caller/signature change: F4 and PO4 show public call protocols and accepted mode strings remain unchanged. The fix belongs in `merge_attrs` because PO3 shows `merge` stores helper attrs directly via `_construct_direct`.

## Artifacts Produced

The requested artifacts are `fvk/SPEC.md`, `fvk/FINDINGS.md`, `fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`, and `fvk/ITERATION_GUIDANCE.md`.

To satisfy the FVK formal-core contract, I also wrote `fvk/mini-python.k`, `fvk/merge-attrs-spec.k`, `fvk/INTENT_SPEC.md`, `fvk/PUBLIC_EVIDENCE_LEDGER.md`, `fvk/FORMAL_SPEC_ENGLISH.md`, `fvk/SPEC_AUDIT.md`, and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

No tests, Python, or K commands were run.
