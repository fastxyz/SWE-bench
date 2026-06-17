# FVK Notes

## Source-code decision

No additional source change was made after V1.

The FVK audit confirmed the V1 loop direction change in
`repo/sympy/physics/hep/gamma_matrices.py` is the targeted repair for the
reported bug. Finding F-001 identifies the original left-to-right prepend loop
as the reversal mechanism for the public witness
`G(rho)*G(sigma)*G(mu)*G(-mu)`. Proof obligations PO-1, PO-3, and PO-6 state
the required prefix-preservation contract and the concrete witness.

Finding F-002 then confirms V1 satisfies the general branch-restoration contract:
for any leading prefix `P` and every core branch `ri`, the descending loop
produces `P ++ ri`. This directly discharges PO-3 and PO-4, so there was no
justified source edit beyond the V1 patch.

## Scope decision

The formal model verifies the leading-prefix restoration slice rather than the
entire SymPy tensor/Kahane implementation. Finding F-003 records this as a
scoped verification boundary, not as a V1 code bug. PO-2 covers the source-level
reason that positions before `first_dum_pos` are the skipped leading prefix, and
PO-5 frames the previously computed contraction coefficient and graph branches
as unchanged by V1.

## Artifact changes

I created the five required FVK artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

I also created the additional adequacy and formal-core files required by the FVK
docs:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-kahane-prefix.k`
- `fvk/kahane-prefix-spec.k`

The K files encode RESTORE-GENERAL, RESTORE-WITNESS, and LEGACY-WITNESS so the
proof can distinguish the intended `[rho, sigma]` order from the legacy
`[sigma, rho]` order. This traces to F-001, F-002, PO-3, PO-4, and PO-6.

## Compatibility and execution decisions

No API compatibility change is needed because F-004 and PO-7 show that
`kahane_simplify`'s public signature and caller protocol are unchanged.

No tests, Python, `kompile`, `kast`, or `kprove` were run. PO-8 records this
honesty gate, and `fvk/PROOF.md` emits the commands that should be run later in
an environment with K installed.
