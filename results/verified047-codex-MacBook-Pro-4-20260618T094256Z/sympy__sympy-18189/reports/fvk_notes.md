# FVK Notes

## Decision

V1 stands unchanged. I made no additional edits under `repo/`.

The FVK audit found the pre-fix defect described in the public issue and showed
that V1 addresses it: the reordered-`syms` branch now forwards the caller's
symbolic `permute` value into the recursive canonical solve before remapping
tuple positions.

## Artifact Trace

`fvk/INTENT_SPEC.md` records the public intent: changing `syms` order must not
drop `permute=True` solutions, and `syms` should only control tuple position
order.

`fvk/PUBLIC_EVIDENCE_LEDGER.md` marks the public issue's `{(3, 2)}` output as
SUSPECT legacy behavior and records the hint that `permute=True` was lost in the
recursive call.

`fvk/mini-python.k` models the audited branch. The reordered-`syms` rule calls
`diophantine(EQ, P, noSyms, PERM)` and then applies a `remap` continuation, so
the model distinguishes V1 from the pre-fix hard-coded `PERM=false` behavior.

`fvk/diophantine-syms-spec.k` contains five K reachability claims. The key one
is Claim C2, `DIO-SYMS-REORDER-FORWARDS-PERMUTE`, whose postcondition is
`reorder(vars(EQ), SYMS, canonical(EQ, P, PERM))`. Claim C4 instantiates the
public issue with `syms=(n,m), permute=True` and reaches the complete
`pow4_signed_nm` result. Claim C5 checks the `permute=False` regression frame.

`fvk/PROOF.md` constructs the proof and records exact `kompile`, `kast`, and
`kprove` commands without running them. It concludes that no counterexample or
unmet proof obligation requires a source edit beyond V1.

`fvk/FINDINGS.md` records F1, the pre-fix dropped-`permute` bug fixed by V1, and
F2, the confirmation finding that no V1 counterexample was found in the audited
branch.

## Assumptions And Boundaries

The formal model assumes `syms`, after filtering to equation variables, is a
complete permutation of the equation's free symbols. That matches the intended
ordering use in the public issue.

The proof is constructed, not machine-checked. I did not run K tooling, Python,
or tests.

The full Diophantine solver is abstracted as `canonical(EQ, P, PERM)` and is
recorded as an escalation boundary in `fvk/diophantine-syms-obligations.k`.
That boundary does not block the V1 decision because the changed behavior is the
preservation of `PERM` across the recursive call, not the internals of canonical
solution generation.
