# FVK Notes

## Decision: keep V1 source unchanged

V1 stands because `fvk/FINDINGS.md` F2 confirms that the current filter order sends selected include-file lines through `dedent_filter` before `prepend_filter` or `append_filter` can insert synthetic option lines. This discharges `fvk/PROOF_OBLIGATIONS.md` PO1 and PO2. F2 also covers PO4 because the content-selection filters still precede dedent.

No additional source edit was made in `repo/sphinx/directives/code.py`.

## Decision: do not alter standalone prepend, append, or dedent behavior

F3 confirms that no-dedent `prepend`/`append` behavior is preserved, discharging PO3. F4 confirms the diff path remains unchanged, discharging PO5. Because those frame obligations pass, no compatibility-motivated source change was made.

## Decision: do not attempt docutils leading-whitespace recovery

F6 records that docutils may already discard leading option whitespace before Sphinx receives directive options. PO8 therefore rejects a speculative parsing-level contract and scopes the repair to the filter-order defect. This is why the FVK pass did not change option specs, directive syntax, or docutils integration.

## Decision: add FVK artifacts

The files under `fvk/` encode the obligations used to audit V1. `SPEC.md`, `FINDINGS.md`, `PROOF_OBLIGATIONS.md`, `PROOF.md`, and `ITERATION_GUIDANCE.md` are the requested summary artifacts. The supporting files `INTENT_SPEC.md`, `PUBLIC_EVIDENCE_LEDGER.md`, `FORMAL_SPEC_ENGLISH.md`, `SPEC_AUDIT.md`, `PUBLIC_COMPATIBILITY_AUDIT.md`, `mini-literalinclude.k`, and `literalinclude-spec.k` satisfy the FVK artifact contract. Their contents trace to F1 through F6 and PO1 through PO8.

## Decision: no tests, Python, or K tooling

F5 and PO7 require the honesty label "constructed, not machine-checked." I did not run tests, Python, `kompile`, `kast`, or `kprove`, and I did not modify any test files.
