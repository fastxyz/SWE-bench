# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## What Is Proved

The constructed proof covers dispatch correctness for dimension-indexer
mappings passed into `.sel`:

- `DataArray.loc[M]` dispatches `M` as the positional `indexers` mapping.
- `.loc` does not convert a key named `method`, `tolerance`, or `drop` into the
  reserved `.sel` parameters.
- The audited internal helpers that construct `{dim: value}` dispatch the
  mapping positionally.
- The pre-fix keyword-unpacking path reproduces the reported invalid fill
  method symptom for `{"dim1": "x", "method": "a"}`.

This is partial correctness of the dispatch fragment. There are no loops in the
audited code slice, and termination is not separately proved.

## Symbolic Proof Sketch

### LOC-GENERIC

Initial state:

```k
<k> locGet(M) </k>
```

By the `locGet` rule in `mini-python-loc.k`:

```k
<k> locGet(M) => selPos(M) </k>
```

By the `selPos` rule:

```k
<k> selPos(M) => dispatched(M, exact) </k>
```

By transitivity, `locGet(M)` reaches `dispatched(M, exact)`. No rule inspects
the keys of `M`, so a key named `"method"` remains inside `M`.

### LOC-METHOD-CONCRETE

Instantiate `M` from `LOC-GENERIC` with:

```k
"dim1" |-> "x" "method" |-> "a"
```

The same two rewrite steps reach:

```k
dispatched("dim1" |-> "x" "method" |-> "a", exact)
```

The reserved method state remains `exact`.

### HELPER-GENERIC and HELPER-METHOD-CONCRETE

Initial state:

```k
<k> helperSelect(D, V) </k>
```

By the `helperSelect` rule:

```k
<k> helperSelect(D, V) => selPos(D |-> V) </k>
```

By the `selPos` rule:

```k
<k> selPos(D |-> V) => dispatched(D |-> V, exact) </k>
```

Instantiating `D = "method"` and `V = "a"` proves the concrete reserved-name
case.

### LEGACY-METHOD-COUNTEREXAMPLE

Initial state:

```k
<k> legacyLocGet("dim1" |-> "x" "method" |-> "a") </k>
```

By the `legacyLocGet` rule, this reaches `selKw(...)`. By the concrete
`selKw` counterexample rule, because `"a"` is not one of the valid fill methods,
the state reaches:

```k
invalidFillMethod("a")
```

This matches the public traceback mechanism and confirms the localization.

## Proof Obligations Discharged

- `PO-1`: discharged by the fact that `selPos(M)` preserves all keys of `M`.
- `PO-2`: discharged by the V2 `DataArray.loc` call shape and `LOC-GENERIC`.
- `PO-3`: discharged because the non-dict path produces `key` and then shares
  the same `self.data_array.sel(key)` call.
- `PO-4`: discharged by V2 helper call shapes and `HELPER-GENERIC`.
- `PO-5`: discharged because fixed paths set method state to `exact`; no key is
  projected into reserved `.sel` parameters.
- `PO-6`: discharged by source inspection: no public signature changed and the
  existing mapping-form `.sel(indexers)` API is used.
- `PO-7`: discharged by `LEGACY-METHOD-COUNTEREXAMPLE` plus
  `LOC-METHOD-CONCRETE`.
- `PO-8`: discharged by artifact process; no prohibited commands were run.

## Commands to Machine Check Later

These commands are written for a future environment with K installed. They were
not executed in this session.

```sh
cd fvk
kompile mini-python-loc.k --backend haskell
kast --backend haskell dataarray-loc-spec.k
kprove dataarray-loc-spec.k
```

Expected machine-check result: `kprove` returns `#Top` for the stated dispatch
claims.

## Test Recommendations

No tests were edited. Because the proof is not machine-checked, no test removal
is recommended now.

Tests to add or keep in a normal development environment:

- `DataArray.loc[dict(dim1="x", method="a")]` selects exactly as the same array
  with dimension name `dim2`.
- Positional `.loc` indexing on a `DataArray` whose second dimension is named
  `method` also succeeds after expansion.
- Similar `.loc` cases for dimensions named `tolerance` and `drop`.
- Dynamic helper coverage through grouped or computation paths with a dimension
  named `method`.

## Residual Risk

- The mini semantics models Python argument binding and dispatch only; it does
  not model full xarray or pandas selection.
- The proof is constructed, not machine-checked.
- Hidden tests, benchmark results, and upstream patches were not used.
