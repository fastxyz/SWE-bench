# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO1: Reported cutoff example

For `Decimal('1e-200')`, `digits=(1)`, `exponent=-200`, `decimal_pos=2`, and
the cutoff predicate true, the formatter must reach fixed zero output rather
than scientific notation.

Linked evidence: E1, E2.

Linked finding: F1.

Formal claim: C1 in `fvk/numberformat-spec.k`.

Status: discharged by constructed proof.

## PO2: Nonzero tiny family

For any nonzero finite `Decimal` with `decimal_pos=N >= 0`, if
`exponent + len(digits) <= -N`, then all significant digits lie beyond the
displayed fractional width. The output must be fixed zero with width `N`.

Linked evidence: E3, E5.

Linked finding: F2.

Formal claim: C3.

Status: discharged by constructed proof.

## PO3: Zero-valued Decimal family

For any zero-valued finite `Decimal` and `decimal_pos=N >= 0`, the output must
be fixed zero with width `N`, regardless of exponent and regardless of whether
the 200-digit cutoff predicate is true.

Linked evidence: E8.

Linked finding: F3.

Formal claim: C2.

Status: discharged by constructed proof after the V2 source change.

## PO4: Preserve non-small cutoff behavior

For nonzero cutoff-triggering `Decimal` values that are not smaller than the
displayable width, the existing scientific notation fallback must remain
available to avoid high memory use.

Linked evidence: E4.

Linked finding: none; frame condition.

Formal claim: C4.

Status: discharged by constructed proof.

## PO5: Preserve non-cutoff fixed formatting

When `abs(exponent) + len(digits) <= 200`, the existing `'{:f}'.format(number)`
path should remain responsible for Decimal formatting.

Linked evidence: E5, E6.

Linked finding: F4.

Formal claim: represented as a frame condition outside the `Cutoff=true`
shortcut; not a separate K claim because the mini model abstracts non-cutoff
formatting as `Other` or already-fixed `FixedZero`.

Status: addressed by source inspection and V2 branch placement.

## PO6: Decimal subclass formatting compatibility

The shortcut must not unnecessarily bypass custom `Decimal.__format__()`
behavior.

Linked evidence: E6.

Linked finding: F4.

Formal claim: compatibility obligation in `fvk/SPEC.md`; not fully modeled in
K because the mini semantics abstracts subclass constructors and methods.

Status: addressed by source refinement; residual fallback risk documented.

## PO7: Output-shape adequacy

The formal abstraction must distinguish the issue's failing output class
(`Scientific`) from the intended output class (`FixedZero`).

Linked evidence: E1, E3.

Linked finding: F5.

Formal claim: all claims in `fvk/numberformat-spec.k`.

Status: adequate for this issue; not a full Python string proof.

## PO8: Honesty gate

All formal results remain constructed, not machine-checked, until the emitted
commands are run and return `#Top`.

Linked evidence: FVK `verify.md` honesty gate.

Linked finding: F5.

Status: commands emitted in `fvk/PROOF.md`; no tests or K tooling were run.
