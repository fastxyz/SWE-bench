# FVK Findings

Status labels: `RESOLVED`, `CONFIRMED`, `RESIDUAL`, or `PROOF-GAP`.

## F-1: Prime zero residue omitted by the old dispatch

Status: RESOLVED by V1.

Input family: `n > 0`, `n != 2`, prime `p`, and `a % p == 0`; concrete public
example `nthroot_mod(17*17, 5, 17)`.

Observed before V1: the function did not explicitly handle the zero-residue
case and could route the call into algorithms meant for nonzero residues.

Expected: return root `0 mod p`; with `all_roots=False`, return scalar `0`.

Evidence: intent entries I1 and I2 in `fvk/SPEC.md`; proof obligations PO-5 and
PO-7 in `fvk/PROOF_OBLIGATIONS.md`.

Decision: keep the V1 zero-residue guard.

## F-2: `all_roots=True` must return the complete prime zero-residue list

Status: RESOLVED by V1.

Input family: same as F-1, with `all_roots=True`.

Expected: `[0]`, not merely a scalar `0` and not a list omitting zero.

Reason: for prime `p` and `n > 0`, `x**n == 0 (mod p)` implies `x == 0 (mod p)`.
Zero is therefore both included and complete.

Evidence: intent entry I3 in `fvk/SPEC.md`; proof obligations PO-6 and PO-7.

Decision: keep V1's `return [0] if all_roots else 0`.

## F-3: Guard placement preserves validation and unsupported-composite behavior

Status: CONFIRMED.

Observed V1 behavior by code inspection: the zero-residue guard is after
`is_nthpow_residue(a, n, p)` and after the composite-modulus rejection.

Expected: invalid `a`, `n`, or `p` values still flow through existing validation;
`n > 2` composite moduli still raise `NotImplementedError`.

Evidence: intent entries I4 and I5; proof obligations PO-1 through PO-4.

Decision: do not move the zero-residue guard earlier.

## F-4: Composite zero-residue nth roots remain a residual compatibility boundary

Status: RESIDUAL, not a V2 code bug under this audit's spec.

Input family: `n > 2`, composite `p`, and `a % p == 0`, for example a call shaped
like `nthroot_mod(p, 3, p)`.

Mathematical fact: `0` is a root, but for composite moduli the all-roots set can
contain more than zero and the existing function publicly marks composite
`n > 2` support as not implemented.

Evidence: public composite `NotImplementedError` tests and the implementation's
`NotImplementedError("Not implemented for composite p")`; proof obligation PO-4.

Decision: do not partially implement composite zero residues in V2. A future
composite-support feature should specify both scalar and `all_roots=True`
semantics for nilpotent residues.

## F-5: Constructed proof is not machine-checked and does not re-prove helpers

Status: PROOF-GAP.

The K artifacts model the dispatch prefix affected by V1. They do not
machine-check the proof, and they do not prove `_nthroot_mod1`,
`_nthroot_mod2`, or the Euclidean reduction for nonzero residues.

Evidence: proof obligations PO-8 through PO-10.

Decision: source V1 can stand for the zero-residue fix, but test removal is not
recommended until the emitted K commands are actually run and the broader helper
contracts are separately verified.
