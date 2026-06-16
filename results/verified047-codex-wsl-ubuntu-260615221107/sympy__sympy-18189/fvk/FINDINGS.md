# FVK Findings

Status: constructed, not machine-checked.

## F-001: V1 fixed the reported `permute` loss

Input family: equations whose canonical solve can expand solutions under
`permute=True`, with `syms` supplied in a non-canonical order. The public example
is `n**4 + m**4 - 2**4 - 3**4` with `syms=(n,m)` and `permute=True`.

Observed before V1: the `syms != var` branch called `diophantine(eq, param)`,
which used the default `permute=False`, so the recursive solve produced only the
base solution before tuple remapping.

Expected: the branch should call the canonical solve with the same `permute`
argument supplied by the caller.

Status: resolved by PO-2. The current source calls
`diophantine(eq, param, permute=permute)`.

## F-002: FVK audit found the remapping formula was inverse for longer orders

Input family: equations with three or more variables and a `syms` order that is
a cycle rather than a simple two-symbol swap, such as canonical `var=(a,b,c)`
and requested `syms=(b,c,a)`.

Observed in V1 source: the branch built `dict(zip(syms, range(len(syms))))` and
then iterated `for i in var`, yielding tuple entries from canonical tuple
positions indexed as if those positions were in `syms` order. This happens to be
correct for a two-variable transposition but is not the documented requested
`syms` order for a longer cycle.

Expected: because the recursive solve returns canonical-order tuples, build the
index map from `var` to canonical tuple positions and emit tuple entries while
iterating `syms`.

Status: resolved by PO-3. The current source builds `dict(zip(var,
range(len(var))))` and returns `tuple(t[dict_sym_index[i]] for i in syms)`.

## F-003: Full algebraic solver verification is an escalation boundary

Input family: all equation classes handled by `classify_diop`, `diop_solve`,
`permute_signs`, and `signed_permutations`.

Observed: the FVK mini-model abstracts the deeper solver as
`canonicalSolve(eq, permute)`.

Expected: this audit must still prove the branch-level issue without pretending
to verify every Diophantine algorithm.

Status: not a source bug. It is a proof capability boundary captured by PO-6.
Existing and hidden tests should be kept; any future test-removal recommendation
would require machine-checking plus a broader solver semantics.

## Summary

No unresolved source-code findings remain for the audited `syms` remapping path.
F-001 and F-002 both produced source-level obligations and are addressed in the
current code. F-003 remains a verification-scope limitation only.
