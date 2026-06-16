# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found that the existing edit to
`repo/sympy/matrices/sparse.py` discharges the shape obligations derived from
the public issue.

## Trace to Findings and Proof Obligations

- `FINDINGS.md` F1 identifies the horizontal sparse bug: the old
  `if not self: return type(self)(other)` shortcut replaced compatible
  zero-row accumulators and produced `(0, 3)` instead of `(0, 6)`.
  V1's `row_join` change is justified by PO1, PO2, and PO5: zero-column
  null adaptation is preserved, compatible horizontal shape accumulation is
  restored, and the four-argument zero-row hstack family reaches
  `shape(0, c0 + c1 + c2 + c3)`.
- `FINDINGS.md` F2 identifies the vertical counterpart: the same shortcut could
  replace compatible `n x 0` accumulators during sparse `vstack`. V1's
  `col_join` change is justified by PO3, PO4, and PO6: zero-row null adaptation
  is preserved, compatible vertical shape accumulation is restored, and the
  four-argument zero-column vstack family reaches
  `shape(r0 + r1 + r2 + r3, 0)`.
- `FINDINGS.md` F3 records that V1 preserves public sparse dispatch and method
  signatures. PO7 and PO8 justify keeping the fix local rather than converting
  sparse joins to a larger `_eval_row_join`/`_eval_col_join` refactor: ShapeError
  behavior outside the null-adaptation cases remains modeled, and the public
  `SparseMatrix` alias still dispatches to the sparse-specific methods.
- `FINDINGS.md` F4 records the only unresolved verification limitation: the
  proof is constructed but not machine-checked because this task forbids running
  K tooling, Python, or tests. This does not justify a source change; it only
  gates proof confidence and test-removal recommendations.

## FVK Artifact Decisions

- I added the required high-level FVK artifacts:
  `fvk/SPEC.md`, `fvk/FINDINGS.md`, `fvk/PROOF_OBLIGATIONS.md`,
  `fvk/PROOF.md`, and `fvk/ITERATION_GUIDANCE.md`.
- I also added the FVK formal/adequacy core required by the kit documentation:
  `fvk/mini-sparse-join.k`, `fvk/sparse-join-spec.k`,
  `fvk/INTENT_SPEC.md`, `fvk/PUBLIC_EVIDENCE_LEDGER.md`,
  `fvk/FORMAL_SPEC_ENGLISH.md`, `fvk/SPEC_AUDIT.md`, and
  `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.
- The formal model abstracts sparse entries away and proves shape behavior.
  That abstraction is adequate for this issue because every public expected
  output is shape-only; entry copying remains a frame condition untouched by V1.

## Execution Constraint

No tests, Python snippets, `kompile`, `kast`, or `kprove` commands were run.
The proof artifacts include the commands a future K-enabled environment should
run, but the current result remains "constructed, not machine-checked."
