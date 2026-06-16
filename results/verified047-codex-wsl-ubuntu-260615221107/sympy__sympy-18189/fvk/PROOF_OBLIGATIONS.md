# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Intent adequacy

The formal claims must encode the public intent that `syms` order must not
change whether `permute=True` expands the solution set.

Evidence: SPEC I-1, I-2, and I-4.

Discharge: claims C-1 and C-2 in `fvk/SPEC.md` make `permute` an explicit
argument to `canonicalSolve(eq, permute)`, so the model can distinguish the
reported bug from the fixed behavior.

## PO-2: Recursive `permute` propagation

In the `syms != var` branch, the recursive solve must receive the caller's
`permute` argument.

Formal obligation:

```text
diophantine(eq, param, syms, p)
  => remapAll(canonicalSolve(eq, p), syms, vars(eq))
```

for the documented `syms` remapping domain.

Source status: discharged at `repo/sympy/solvers/diophantine.py:185`, where the
recursive call is `diophantine(eq, param, permute=permute)`.

Related finding: F-001.

## PO-3: Tuple remapping uses requested `syms` order

Because the recursive solve returns tuples in canonical `var` order, the
remapping branch must use a canonical index map and iterate requested `syms`.

Formal obligation:

```text
index = {var[j]: j for j in range(len(var))}
remap(t, syms, var) = tuple(t[index[s]] for s in syms)
```

Source status: discharged at `repo/sympy/solvers/diophantine.py:183-184`.

Related finding: F-002.

## PO-4: Default `permute=False` frame condition

When the caller leaves `permute` at its default `False`, the branch must still
use the base canonical solution set and then only apply tuple reordering.

Formal obligation:

```text
diophantine(eq, param, syms, False)
  => remapAll(canonicalSolve(eq, False), syms, vars(eq))
```

Source status: discharged by the same recursive call as PO-2 because
`permute=False` is forwarded unchanged.

Related finding: F-001.

## PO-5: Public compatibility

The public API shape of `diophantine` must not change.

Source status: discharged. The signature remains
`diophantine(eq, param=symbols("t", integer=True), syms=None, permute=False)`;
the edit changes only local branch implementation.

Related finding: none.

## PO-6: Solver abstraction boundary

The proof may assume the canonical solver's contract but must not claim to prove
the full Diophantine solver.

Formal boundary:

```text
canonicalSolve(eq, p)
```

is an abstract function representing the existing no-`syms` behavior for the
same `permute` value.

Source status: accepted as an escalation boundary, not a code change request.

Related finding: F-003.
