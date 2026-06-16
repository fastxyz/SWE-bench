# FVK Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Claims Proved in the Mini Model

C-1. For `syms` that are a non-canonical permutation of `vars(eq)`:

```text
diophantine(eq, param, syms, True)
  reaches remapAll(canonicalSolve(eq, True), syms, vars(eq))
```

C-2. For the same branch with `permute=False`:

```text
diophantine(eq, param, syms, False)
  reaches remapAll(canonicalSolve(eq, False), syms, vars(eq))
```

## Proof Sketch

1. Enter the `diophantine` wrapper with an equation whose free symbols sort to
   `var`.
2. The `syms` argument passes the sequence check and is filtered to symbols in
   `var`.
3. Under the branch condition `syms != var`, execution constructs
   `dict_sym_index` from canonical variables to canonical tuple positions.
4. The set comprehension recursively calls `diophantine(eq, param,
   permute=permute)`. By the `canonicalSolve` abstraction, this produces
   `canonicalSolve(eq, permute)`.
5. For each canonical tuple `t`, the tuple constructor iterates requested
   `syms` and selects `t[dict_sym_index[i]]`. This is exactly
   `remap(t, syms, var)`.
6. Set comprehension over all canonical tuples gives
   `remapAll(canonicalSolve(eq, permute), syms, vars(eq))`.

This discharges PO-2 and PO-3. PO-4 follows by substituting `permute=False`.
PO-5 follows because the function signature is unchanged. PO-6 is a declared
abstraction boundary and is not used to claim full solver correctness.

## V0 Counterexample Mechanism

In the pre-fix branch, step 4 was `diophantine(eq, param)`, so the mini-model
would produce:

```text
remapAll(canonicalSolve(eq, False), syms, vars(eq))
```

even when the caller supplied `permute=True`. For the public issue's even-power
equation, `canonicalSolve(eq, True)` is the signed/value-permuted set while
`canonicalSolve(eq, False)` is only the base solution set. This matches F-001.

## V1 Audit-Derived Counterexample Mechanism

V1 still used an index map from `syms` to positions while iterating canonical
`var`. For a longer order such as `var=(a,b,c)` and `syms=(b,c,a)`, that computes
positions `[2,0,1]` over the canonical tuple rather than the requested
`[1,2,0]`. Building the map from `var` and iterating `syms` resolves this
general `syms` ordering obligation. This matches F-002.

## Would-Run Commands

These commands are recorded for a future environment with K installed; they were
not executed here.

```sh
kompile fvk/mini-diophantine.k --backend haskell
kast --backend haskell fvk/diophantine-syms-spec.k
kprove fvk/diophantine-syms-spec.k
```

Expected machine-check result after syntax/semantics validation: `#Top` for the
two branch claims.

## Test Guidance

No tests may be edited in this task. Because the proof is not machine-checked
and the full solver is abstracted, no test removal is recommended. Focused tests
that would be useful in a normal development setting are:

- the public two-variable `permute=True` reproduction for both `syms` orders;
- a three-variable equation with a non-transposition `syms` order to cover
  F-002's remapping family.
