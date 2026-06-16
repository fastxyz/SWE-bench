# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## Claims Proved in the Model

C1: `copyIndexVariable(indexVar(adapter(object, unicode(N))), true)` preserves
the adapter dtype `unicode(N)` for all `N > 0`.

C2: `copyIndexVariable(indexVar(adapter(object, unicode(N))), false)` preserves
the adapter dtype `unicode(N)` for all `N > 0`.

C3: for any pandas dtype `P` and adapter dtype `D`,
`copyIndexVariable(indexVar(adapter(P, D)), true)` preserves adapter dtype `D`.

These claims correspond to `IndexVariable.copy(data=None)` in V1. Dataset,
DataArray, and `copy.deepcopy` preservation are composition results from their
delegation to variable copy.

## Symbolic Execution Sketch

Initial symbolic state for the bug:

```k
<k> adapterDType(
      copyIndexVariable(indexVar(adapter(object, unicode(N))), true))
    </k>
requires N >Int 0
```

Step 1: strictness evaluates the argument of `adapterDType`.

Step 2: the V1 deep-copy rule applies:

```k
copyIndexVariable(indexVar(adapter(PANDAS, ADAPTER)), true)
=> indexVar(adapter(PANDAS, ADAPTER))
```

With substitution `PANDAS := object`, `ADAPTER := unicode(N)`, the state becomes:

```k
<k> adapterDType(indexVar(adapter(object, unicode(N)))) </k>
```

Step 3: the adapter dtype projection rule applies:

```k
adapterDType(indexVar(adapter(_, ADAPTER))) => ADAPTER
```

With `ADAPTER := unicode(N)`, the final state is:

```k
<k> unicode(N) </k>
```

This discharges C1. C2 is identical except the shallow-copy rule applies. C3 is
the same derivation with symbolic `PANDAS` and `ADAPTER`.

## Why V0 Failed This Proof

The pre-fix deep-copy model would be:

```k
copyIndexVariable(indexVar(adapter(PANDAS, _ADAPTER)), true)
=> indexVar(adapter(PANDAS, PANDAS))
```

For the reported state `adapter(object, unicode(3))`, that yields
`adapter(object, object)`, and `adapterDType(...)` reduces to `object`, not
`unicode(3)`. That is Finding F-001.

## Container Composition

`Dataset.copy(deep=True)` copies each stored variable with `v.copy(deep=True)`.
For dimension coordinate `x`, `v` is an `IndexVariable`, so C1/C3 applies. Other
variables are outside the failing adapter reconstruction path.

`DataArray.copy(deep=True)` copies its coordinates with `v.copy(deep=True)`.
For coordinate `x`, C1/C3 applies.

`copy.deepcopy()` delegates to `copy(deep=True)` for the relevant classes, so it
inherits the same result.

`copy.copy()` delegates to `copy(deep=False)` in this checkout. C2 proves dtype
preservation for that branch, but the audit does not justify changing the
dispatch because the public hint says the `deep=False` path is not affected.

## Residual Risk

The proof models the dtype propagation axis only. It intentionally abstracts
away pandas index value equality, attrs, encoding copy mechanics, and object
identity because the public issue concerns dtype mutation. Those frame
properties are covered by source-level obligations in `PROOF_OBLIGATIONS.md`.

The proof is partial and constructed only. Machine-checking was not performed.

## Exact Commands Not Run

The task forbids running K tooling. These are the commands a human could run in
an environment with K installed:

```sh
kompile fvk/mini-xarray-copy.k --backend haskell
kast --backend haskell fvk/xarray-copy-spec.k
kprove fvk/xarray-copy-spec.k
```

Expected machine-check result after a successful K run: `#Top` for all claims.

## Test Recommendation

No tests were modified. Because this proof is not machine-checked and the
project tests are fixed/hidden in the benchmark, there is no test removal
recommendation. A useful public regression test, outside this task's allowed
edits, would assert that `Dataset.copy(deep=True)`, `DataArray.copy()`,
`DataArray.copy(deep=True)`, and `copy.deepcopy()` preserve `<U*>` dtype on
dimension coordinates.
