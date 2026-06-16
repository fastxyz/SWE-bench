# FVK Findings

Status: constructed, not machine-checked.

## F-001: Legacy HPacker top/bottom inversion is the root bug

Classification: code bug in the pre-V1 implementation; resolved by V1.

Input: `HPacker` children with unequal heights and `align="bottom"`.

Observed before V1: the branch table placed `bottom` on the far-edge formula
`H - h + d`, so shorter children were moved upward and their top edges matched.

Expected: `bottom` must use offset `d`, giving `offset - d = 0` for every child
bottom edge.

Related proof obligations: PO-002, PO-003.

Recommended code action: keep the V1 branch swap.

## F-002: V1 discharges the reported HPacker obligations

Classification: confirmation.

Input: any in-domain child extent `(h, d)` in effective height `H`.

Observed in V1: `bottom` returns `d`; `top` returns `H - h + d`.

Expected: bottom-edge equality for `bottom`; top-edge equality for `top`.

Related proof obligations: PO-001, PO-002, PO-003, PO-006.

Recommended code action: no additional source edit.

## F-003: VPacker left/right behavior remains intact

Classification: compatibility confirmation.

Input: any in-domain child extent `(w, d)` in effective width `W`.

Observed in V1: `left` remains on the `d` branch; `right` remains on the
`W - w + d` branch.

Expected: left-edge equality for `left`; right-edge equality for `right`, as
called out in the public hints.

Related proof obligations: PO-004, PO-005.

Recommended code action: no additional source edit.

## F-004: Migration flag or uppercase temporary values are not justified here

Classification: rejected alternative.

Input: public API design for correcting the inverted `HPacker` behavior.

Observed in public hints: several migration paths are discussed, but the same
discussion also supports treating the inversion as a plain bugfix.

Expected: keep the fix minimal if the direct branch swap satisfies the public
intent and compatibility audit.

Related proof obligations: PO-005, PO-006.

Recommended code action: do not add a compatibility flag, temporary uppercase
alignment values, or new packer classes for this targeted fix.

## F-005: VPacker top/bottom aliases are ambiguous but not a blocker

Classification: residual compatibility risk, not a code bug found by this FVK
pass.

Input: external code calling `VPacker(align="top")` or
`VPacker(align="bottom")`.

Observed in source/docs: the public constructor accepts all alignment strings,
but the meaningful cross-axis names for a vertical packer are `left`, `right`,
and `center`. The source call-site audit found no in-repository public
dependency on `VPacker` top/bottom aliases.

Expected: do not preserve a legacy alias mapping without public intent evidence.
The helper's documented lower/far edge model supports `bottom` with `left` and
`top` with `right`.

Related proof obligations: PO-004, PO-005, PO-006.

Recommended code action: no additional source edit; document this as residual
risk in the compatibility audit.

## Proof-Derived Findings from /verify

No new code bug was surfaced by the constructed proof obligations. The proof
does not justify deleting tests because K tooling was not run, and this task
forbids modifying tests.
