# FVK Notes

## Decision

V1 stands unchanged. No additional production-code edits were made during the
FVK pass.

## Trace from findings and obligations

F1 in `fvk/FINDINGS.md` identifies the original object-at-address repr as the
first root cause. O1 in `fvk/PROOF_OBLIGATIONS.md` requires
`_RepeatedSplits.__repr__` to delegate to `_build_repr(self)`. The V1 source
already satisfies this, so no V2 edit was needed for that part.

F2 identifies the second root cause: `n_splits` is stored in `cvargs`, so adding
`__repr__` alone would render `n_splits=None`. O3, O5, and O6 require
constructor parameters missing as direct attributes to fall back to `cvargs`.
The V1 sentinel fallback in `_build_repr` satisfies those obligations.

F3 records the parameter-order question. O2 and O5 preserve the existing
`_build_repr` and `_pprint` sorted-order convention, supported by source tests
for other cross-validation splitters and by the public hint's direction to use
`_build_repr`. I therefore kept V1's sorted helper behavior instead of adding a
special repeated-splitter repr.

F4 and O7 cover compatibility for existing direct-attribute splitters. V1 only
consults `cvargs` after a direct attribute is absent, so direct values including
`None` remain authoritative. That is why I did not revise `_build_repr` further.

P-F2 and O8 record the benchmark constraints and the constructed-not-machine-
checked status. I did not run tests, Python, `kompile`, `kast`, or `kprove`, and
I did not modify test files.

## Artifacts

The required artifacts are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

The FVK documentation also required the formal and adequacy core, so I added:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-python-repr.k`
- `fvk/repeated-splits-repr-spec.k`

