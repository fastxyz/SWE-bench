# FVK Notes

## Decision

V1 stands unchanged.

The FVK audit traced the issue to the same production behavior as the baseline:
the old local indentation algorithm included the first line when determining
the common margin. `fvk/FINDINGS.md` records this as F-001, and
`fvk/PROOF_OBLIGATIONS.md` records the required correction as PO-2 and PO-4.
V1 satisfies those obligations by using `inspect.cleandoc()` for non-empty
docstrings.

## Source Changes

No additional production source files were edited in this pass.

Reason: the only open proof boundary is F-005, which is a trusted-base boundary
for the standard-library `inspect.cleandoc()` contract, not a defect in the
Django source. The public hint in `benchmark/PROBLEM.md` specifically identifies
`inspect.cleandoc()` as the PEP 257 implementation, and the existing helper
comment already names PEP 257 as the intended algorithm. That discharges PO-2,
PO-3, and PO-5 for this source-level repair.

## Artifact Changes

Created the requested FVK artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Created the FVK adequacy and formal-core artifacts required by the method:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-python-string.k`
- `fvk/trim-docstring-spec.k`

## Traceability

F-001 maps to PO-2 and PO-4: first-line-summary docstrings must be dedented
before `parse_rst()`.

F-002 maps to PO-3: the rejected skip-first-line `min()` patch must not raise
for one-line docstrings.

F-003 maps to PO-5: leading-empty-line docstrings remain in the PEP 257 cleanup
family.

F-004 maps to PO-1 and PO-6: the empty guard and public call protocol remain
unchanged.

F-005 is carried as an honesty caveat in `fvk/PROOF.md`: the proof is
constructed, not machine-checked, and models `inspect.cleandoc()` through its
public PEP 257 contract rather than by inlining standard-library source.

No tests, Python commands, or K tooling were run.
