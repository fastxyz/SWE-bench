# FVK Proof Obligations

Status: constructed, not machine-checked.

## Definitions

Let:

- `V` be the old variable-key set.
- `C` be the old coordinate-name set.
- `D` be the set of variable names removed by `drop=True`.
- `N` be `set(new_variables)`.
- `V' = (V - D) union N`.
- `C' = (C intersect V') union N`.

Reachability side condition:

- `SC-1: N <= V'`, because the source executes `variables.update(new_variables)`
  before rebuilding `coord_names`.

## Obligations

PO-1 Exact transition:

`Dataset.reset_index` must compute `C' = (C intersect V') union N`.

PO-2 Coordinate subset invariant:

Given `SC-1`, prove `C' <= V'`.

PO-3 Stale coordinate removal:

For every name `k`, if `k in C` and `k notin V'` and `k notin N`, then
`k notin C'`.

PO-4 Non-negative data-variable length:

Given `C' <= V'`, prove
`len(V') - len(C') >= 0`, matching the precondition required by
`DataVariables.__len__`.

PO-5 MCVE discharge:

For the issue state after `set_index(z=["a", "b"])` and before
`reset_index("z", drop=True)`, use `V = C = {z, a, b}`, `D = {z}`, and
`N = {}`. Prove `V' = {a, b}`, `C' = {a, b}`, and data-variable length `0`.

PO-6 Frame for surviving coordinates:

For every name `k`, if `k in C` and `k in V'`, then `k in C'`.

PO-7 New index-variable coordinates:

For every name `k`, if `k in N`, then `k in C'`.

PO-8 Drop-false compatibility:

When `drop=False`, `D = {}`. Assuming the incoming invariant `C <= V`, prove
`C' = C union N`, which is the old behavior for valid states.

PO-9 Public compatibility:

No public signature, return type, virtual dispatch, or test file may change.

## Formal Artifacts

The K semantics fragment is in `fvk/mini-xarray-reset-index.k`.

The K claims are in `fvk/reset-index-coord-names-spec.k`.

Intended commands, not executed in this session:

```sh
kompile fvk/mini-xarray-reset-index.k --backend haskell
kast --backend haskell fvk/reset-index-coord-names-spec.k
kprove fvk/reset-index-coord-names-spec.k
```
