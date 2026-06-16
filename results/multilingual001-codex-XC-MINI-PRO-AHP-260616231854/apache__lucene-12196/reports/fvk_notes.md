# FVK Notes

The FVK audit confirms V1 as the final source change. Finding F-001 identifies the original bug:
`BoostQuery` hid the inner `PhraseQuery` from `applySlop`, so the boost was preserved while the
parsed slop was lost. Proof obligations PO-003 and PO-005 are the decisive obligations for the
issue, and the V1 `BoostQuery` branch discharges both by unwrapping, applying slop recursively, and
rewrapping with the original boost.

I kept V1 unchanged because F-003 records that all specified input families are covered by the
current code, and PO-001 through PO-008 are discharged by static inspection. In particular, PO-001
and PO-002 show the existing direct phrase and multi-phrase behavior remains intact; PO-004 shows
phrase payload is preserved; PO-006 covers null and non-phrase behavior; PO-007 covers termination
over finite boost-wrapper nesting; and PO-008 confirms there is no public API compatibility issue.

I considered the same alternative noted in the baseline, moving field-boost application after
`applySlop`. The FVK obligations make that unnecessary and less targeted: PO-003 requires wrapper
transparency as the semantic property, and V1 proves that property for both phrase and multi-phrase
queries. Moving call order would fix the reproduced path but would not make `applySlop` correct for
already-boosted inputs, which F-002 identifies as part of the wrapper family.

I added the requested FVK artifacts plus the supporting K and adequacy files under `fvk/`. The K
model keeps slop, payload, and boost as separate observables to satisfy PO-009, and the command
snippets in `PROOF.md` and `ITERATION_GUIDANCE.md` satisfy PO-010 without executing tooling. The
adequacy files mirror the same public evidence used in F-001 through F-003 so the proof is not based
on the legacy missing-slop behavior.

I did not modify test files, run tests, run project code, run Python, or run K tools. Finding F-004
and PO-010 record that the proof is constructed but not machine-checked; the exact commands are
included in `fvk/PROOF.md` and `fvk/ITERATION_GUIDANCE.md` for a future execution environment.
