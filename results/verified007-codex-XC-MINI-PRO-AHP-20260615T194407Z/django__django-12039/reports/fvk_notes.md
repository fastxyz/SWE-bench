# FVK Notes

## Source Decision

V1 stands unchanged.

Findings F-1 and F-2 identify the two public defects from the issue: missing whitespace before `DESC` and trailing whitespace after an opclass with an empty suffix. Proof obligations PO-1 through PO-4 show that the V1 implementation discharges both defects and preserves the opclass-plus-descending case.

I did not add stripping or broader normalization for pre-spaced suffix fragments. Finding F-4 records that such inputs are not produced by the public source path, and PO-5 frames compatibility as preserving existing signatures and dispatch while fixing the evidenced token contract. Changing arbitrary direct-helper fragments would exceed the public issue evidence.

## Artifact Decisions

I wrote the five requested artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

I also wrote the FVK adequacy and formal-core artifacts required by the FVK docs:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-python.k`
- `fvk/index-columns-spec.k`

These additional files support PO-6 and Finding F-5: the proof is constructed and has exact commands for later checking, but this benchmark forbids running K tooling.

## Execution Decision

No tests, Python code, or K commands were run. This follows the task's no-execution rule and is explicitly tracked by Finding F-5 and PO-6.
