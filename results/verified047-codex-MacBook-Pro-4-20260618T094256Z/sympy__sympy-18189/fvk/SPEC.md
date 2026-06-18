# Specification

Status: constructed, not machine-checked; escalation-bounded for full solver
internals.

## Scope

This FVK package audits the V1 change in
`repo/sympy/solvers/diophantine.py`: the `syms != var` normalization branch of
the public `diophantine(eq, param, syms=None, permute=False)` function.

The model intentionally abstracts the rest of the solver as
`canonical(EQ, P, PERM)`, the result produced when no `syms` override is active.
This abstraction keeps the verified observable complete for the issue: whether
`PERM` is preserved, whether tuple positions are remapped, and whether the
solution set is widened only when `permute=True`.

## Preconditions

`SYMS` is in domain when, after filtering to variables of `EQ`, it is a complete
permutation of `vars(EQ)`. This is represented by
`completeSyms(SYMS, vars(EQ))`.

`needsReorder(SYMS, vars(EQ))` selects the branch where supplied `syms` differs
from canonical variable order.

`sameOrder(SYMS, vars(EQ))` selects the branch where supplied `syms` already
matches canonical variable order.

## Postconditions

If `syms` is omitted, `diophantine(EQ, P, noSyms, PERM)` returns
`canonical(EQ, P, PERM)`.

If `syms` is complete and in a different order, `diophantine(EQ, P, SYMS, PERM)`
returns `reorder(vars(EQ), SYMS, canonical(EQ, P, PERM))`. The `PERM` value is
symbolic in the claim, so both `true` and `false` are frame-checked.

If `syms` is complete and already in canonical order, `diophantine(EQ, P, SYMS,
PERM)` returns `canonical(EQ, P, PERM)`.

For the public issue equation, `vars(pow4_mn_2_3) = mn`,
`canonical(pow4_mn_2_3, tparam, true) = pow4_signed_mn`, and
`reorder(mn, nm, pow4_signed_mn) = pow4_signed_nm`. Therefore
`diophantine(pow4_mn_2_3, tparam, nm, true)` reaches the complete permuted set
in `(n,m)` tuple order.

## Claim Map

Claim C1, `DIO-CANONICAL-OMITTED-SYMS`, specifies the canonical no-`syms` path.

Claim C2, `DIO-SYMS-REORDER-FORWARDS-PERMUTE`, specifies that the reordered
`syms` branch recursively solves with the same `PERM` flag and remaps the
canonical result.

Claim C3, `DIO-SYMS-SAME-ORDER-FRAME`, specifies the same-order frame condition.

Claim C4, `DIO-ISSUE-PERMUTE-TRUE-NM`, instantiates the public issue example and
requires the complete signed/permuted result for `syms=(n,m), permute=True`.

Claim C5, `DIO-ISSUE-PERMUTE-FALSE-FRAME`, checks that the same branch with
`permute=False` remains the non-permuted canonical result after remapping.

## Public Evidence Ledger Mirror

The issue text provides the primary postcondition: solution completeness must
not depend on `syms` ordering when `permute=True`.

The prompt's hint identifies the mechanism: `permute=True` was lost in the
recursive `diophantine` call.

The docstring supplies the tuple-position obligation for `syms` and the
solution-set expansion obligation for `permute=True`.

The displayed pre-fix `{(3, 2)}` result is SUSPECT legacy behavior, not a
desired output.

## Escalation Boundaries

`CANONICAL-SOLVER-ADEQUACY`: this audit does not verify SymPy's full Diophantine
classification and solving algorithms. They are represented by
`canonical(EQ, P, PERM)`.

`PYTHON-RUNTIME-ADEQUACY`: this audit does not model all Python runtime behavior,
exception paths, object identity, SymPy expression expansion, or termination.
