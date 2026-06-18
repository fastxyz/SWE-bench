# FVK Notes

## Decision

V1 stands unchanged. I did not edit source under `repo/` during the FVK pass.

The audit found no concrete counterexample and no unmet public proof obligation
that V1 demonstrably fails. Under the revision discipline, that means no code
change is justified.

## Artifact Trace

- `fvk/INTENT_SPEC.md` records the public obligations: avoid the reported
  `IndexError`, return unsupported denesting inputs unchanged, make
  `split_surds` safe on no-surd inputs, stop `rad_rationalize` non-progressing
  recursion, and preserve supported square-root behavior.
- `fvk/PUBLIC_EVIDENCE_LEDGER.md` maps those obligations to the public issue and
  source docstrings. The key entries are E1-E7 for the failing paths and E8-E10
  for regression frames.
- `fvk/mini-sympy-surds.k` and `fvk/sqrtdenest-spec.k` provide the constructed K
  semantics and claims. Claims C1-C4 cover the public crash/no-progress cases;
  C5-C6 cover the regression frames.
- `fvk/SPEC_AUDIT.md` marks all formalized obligations as passing within the
  finite public-issue model.
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` confirms the V1 edits keep helper
  signatures and return shapes unchanged.
- `fvk/FINDINGS.md` records that no finding forces a source edit and that the
  remaining limitation is model scope, not a demonstrated V1 bug.

## Why No Source Edit Was Made

The constructed proof shows V1 routes `_sqrt_match(4 + I)` to no-match, routes
`split_surds(4 + I)` to `(1, 0, 4 + I)`, routes
`rad_rationalize(1, 4 + I)` to unchanged output, and routes
`rad_rationalize(1, 1 + cbrt(2))` to unchanged output without recursive
progress. It also preserves the public `rad_rationalize(1, sqrt(2) + I)` frame
and the documented regular-surd `split_surds` example.

Because every potential edit would broaden the source change beyond a documented
finding, the regression-avoidance rule requires leaving V1 as is.

## Verification Status

The FVK proof is constructed, not machine-checked. I did not run tests, Python,
`kompile`, or `kprove`, per the task constraints. The exact K commands are
listed in `fvk/PROOF.md` for a future environment that has K installed.
