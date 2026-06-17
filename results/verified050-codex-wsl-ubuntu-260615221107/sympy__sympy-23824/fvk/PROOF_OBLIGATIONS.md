# PROOF_OBLIGATIONS.md

Status: constructed, not machine-checked.

## PO-1: Leading Prefix Preservation

Provenance: E1, E2, E3.

For any in-domain gamma product with leading free prefix `P`, simplification
must not reorder that prefix. The restored branch list must use `P` exactly as
it appeared in the input.

Formal claim: RESTORE-GENERAL in `fvk/kahane-prefix-spec.k`.

Status: discharged by constructed proof.

## PO-2: Correct Prefix Boundary

Provenance: E6.

`first_dum_pos = min(map(min, dum))` identifies the first contracted Lorentz
index position. Therefore every gamma position less than `first_dum_pos` is in
the leading free segment skipped by the Kahane graph walk.

Status: discharged by source inspection under the in-domain assumption that the
input is a `TensMul` product of `GammaMatrix` tensors and each Lorentz index
position is either free or dummy.

## PO-3: Descending Prepend Loop Preserves Order

Provenance: E1, E2, E4.

For branch `ri_old` and prefix `P` of length `k`, V1 must satisfy this loop
invariant:

```text
after processing positions i+1 through k-1:
    ri = P[i+1:k] ++ ri_old
after processing position i:
    ri = P[i:k] ++ ri_old
```

At loop exit, each branch is `P[0:k] ++ ri_old`.

Formal claims: RESTORE-ONE and RESTORE-GENERAL.

Status: discharged by constructed proof.

## PO-4: All Branches Receive the Same Prefix

Provenance: E7.

The restoration loop must update every list in `resulting_indices`, because the
Kahane graph walk can produce additive alternatives.

Formal claim: RESTORE-GENERAL.

Status: discharged by constructed proof over branch lists.

## PO-5: Framed Kahane-Core Behavior

Provenance: E4, E5.

Changing the prefix loop must not alter the contraction coefficient, graph
traversal result, additive branch count, or non-leading branch order computed
before restoration.

Status: discharged by source diff inspection. V1 changes only the final prefix
loop direction and a comment.

## PO-6: Public Witness

Provenance: E3.

For `P = [rho, sigma]`, one empty core branch, and coefficient `4`, V1 must
produce `4*G(rho)*G(sigma)`.

Formal claim: RESTORE-WITNESS.

Status: discharged by constructed proof.

## PO-7: Compatibility

Provenance: public API names and static source diff.

The fix must not change `kahane_simplify`'s public signature or require caller
changes.

Status: discharged by compatibility audit.

## PO-8: Honesty Gate

Provenance: FVK docs.

The proof artifacts must be labeled constructed, not machine-checked, because
this session must not run `kompile`, `kast`, `kprove`, Python, or tests.

Status: discharged by artifact labels and command-only reproduction notes.
