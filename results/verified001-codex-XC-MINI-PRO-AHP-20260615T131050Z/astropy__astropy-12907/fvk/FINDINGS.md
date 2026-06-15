# FVK Findings

Status: constructed, not machine-checked.

## FVK-F1: Right nested separability matrix was overwritten

Input:

```python
cm = m.Linear1D(10) & m.Linear1D(5)
separability_matrix(m.Pix2Sky_TAN() & cm)
```

Observed in the public issue before V1:

```text
[[ True,  True, False, False],
 [ True,  True, False, False],
 [False, False,  True,  True],
 [False, False,  True,  True]]
```

Expected from INT-1 through INT-4:

```text
[[ True,  True, False, False],
 [ True,  True, False, False],
 [False, False,  True, False],
 [False, False, False,  True]]
```

Classification: code bug, fixed by V1.

Trace: PO-3 requires `_cstack` to preserve `R[i, j]` in the lower-right block.
The pre-V1 implementation wrote `1` into every lower-right entry for ndarray
right operands, which changed zero entries of the nested diagonal matrix into
dependencies. V1 changes that assignment to copy `right`.

## FVK-F2: V1 preserves the right block and matches the intent contract

Input class: any `_cstack(L, R)` call where both operands are already coordinate
matrices and `R` may contain zero entries.

Observed in V1 source:

```python
cright[-right.shape[0]:, -right.shape[1]:] = right
```

Expected from PO-3: lower-right entries equal the corresponding entries of
`R`, not a constant all-ones block.

Classification: confirmed fixed behavior.

Trace: claim `CSTACK-RIGHT-PRESERVE` in `fvk/separability-spec.k`; proof
obligation PO-3.

## FVK-F3: Proof scope does not cover unrelated operators

Input class: compound models using `|`, arithmetic operators, `Mapping`, or
private direct calls to `_cstack` with raw `Model` operands.

Observed: V1 did not modify these paths, and the public issue does not require
changing them.

Expected: the FVK proof should not claim coverage beyond the matrix `&` block
construction that caused the issue.

Classification: proof coverage boundary and test gap, not a code bug for this
task.

Trace: PO-6 states the proof scope. Existing public and hidden tests for other
operators should be kept.

## Proof-derived findings from `/verify`

No additional code bug was derived. The constructed proof depends on the
dimension and block-layout preconditions in PO-1 through PO-4; those preconditions
are justified by the `coord_matrix` and `CompoundModel('&')` contracts recorded
as INT-4 and INT-5. No new source edit is justified beyond V1.
