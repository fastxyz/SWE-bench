# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Shape preservation for `&`

For any in-domain coordinate matrices `L` and `R`, `_cstack(L, R)` returns a
matrix with `rows(L) + rows(R)` rows and `cols(L) + cols(R)` columns.

Provenance: INT-4, INT-5.

Discharged by: `CSTACK-SHAPE` in `fvk/separability-spec.k`.

## PO-2: Left block preservation

For all valid left-block coordinates `i, j`,
`_cstack(L, R)[i, j] == L[i, j]`.

Provenance: INT-2, INT-4, INT-5.

Discharged by: `CSTACK-LEFT-PRESERVE`.

## PO-3: Right block preservation

For all valid right-block coordinates `i, j`,
`_cstack(L, R)[rows(L) + i, cols(L) + j] == R[i, j]`.

Provenance: INT-1, INT-3, INT-4, INT-5.

Discharged by: `CSTACK-RIGHT-PRESERVE`. This is the obligation V1 repairs.

## PO-4: Off-block independence

For all coordinates in the upper-right and lower-left blocks, `_cstack(L, R)`
contains zero/False. This prevents a left model from depending on right inputs
and prevents a right model from depending on left inputs.

Provenance: INT-2, INT-3.

Discharged by: `CSTACK-OFF-BLOCKS`.

## PO-5: Nesting invariance for right-hand `&`

For any matrices `A`, `B`, and `C`, the dependency entries of
`_cstack(A, _cstack(B, C))` match the corresponding block-concatenated entries
of the flattened `A & B & C` layout. In particular, zeros inside `_cstack(B, C)`
remain zeros after it is placed to the right of `A`.

Provenance: INT-1, INT-2, INT-3.

Discharged by: `CSTACK-NESTED-RIGHT`.

## PO-6: Scope and compatibility

The source change must not alter public signatures, return shapes, or operator
dispatch outside the intended `_cstack` matrix semantics.

Provenance: INT-4, INT-5, compatibility audit.

Discharged by: no signature/API change and unchanged `_operators` dispatch.
