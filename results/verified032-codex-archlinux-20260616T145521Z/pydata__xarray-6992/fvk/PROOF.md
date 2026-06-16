# FVK Proof

Status: constructed, not machine-checked.

## Claims

The formal claims are in `fvk/reset-index-coord-names-spec.k`:

- Claim 1: `rebuildCoordNames(C, V', N)` reaches a state with
  `coordNames = (C intersect V') union N`.
- Claim 2: under `N <= V'`, the reached coordinate-name set is a subset of
  `V'`.

These claims correspond to PO-1 and PO-2. PO-3 through PO-8 are algebraic
consequences of the same set expression.

## Constructed Proof

Let `V' = (V - D) union N` and `C' = (C intersect V') union N`.

PO-1 follows by one symbolic rewrite of the mini semantics rule for
`rebuildCoordNames`: the `<coordNames>` cell is updated to
`(C intersect V') union N`.

PO-2 follows from set algebra:

- `C intersect V' <= V'`.
- `N <= V'` by SC-1.
- If `A <= V'` and `B <= V'`, then `A union B <= V'`.
- Therefore `(C intersect V') union N <= V'`.

PO-3 follows because a name absent from `V'` cannot be in `C intersect V'`, and
if it is also absent from `N`, it cannot be in the union.

PO-4 follows from PO-2. For finite sets, if `C' <= V'`, then
`|V' - C'| = |V'| - |C'| >= 0`. `DataVariables.__len__` computes this
difference under the invariant.

PO-5 instantiates the formula with the issue state:

- Before reset: `V = {z, a, b}` and `C = {z, a, b}`.
- Drop set: `D = {z}`.
- Replacement set: `N = {}`.
- Rebuilt variables: `V' = (V - D) union N = {a, b}`.
- Rebuilt coordinates: `C' = (C intersect V') union N = {a, b}`.
- Data variables: `V' - C' = {}`.
- Length: `2 - 2 = 0`.

The old formula was `C_old' = C union N = {z, a, b}`, giving `2 - 3 = -1`.
V1 removes exactly that stale-name path.

PO-6 follows because if `k in C` and `k in V'`, then `k in C intersect V'`,
so `k in C'`.

PO-7 follows because `N` is a union operand in `C'`.

PO-8 follows when `drop=False`: then `D = {}` and `V' = V union N`. Under the
incoming invariant `C <= V`, `C intersect V' = C`, so
`C' = C union N`, matching the old behavior for valid states.

PO-9 follows syntactically from the source diff: no method signature, return
type, dispatch call, or test file changed.

## Adequacy Gate

The formal English in `fvk/SPEC.md` matches the intent entries INT-1 through
INT-5:

- The proof targets the concrete failure mode from the issue, not an
  implementation-derived behavior.
- The proof keeps level coordinates because that is required by public tests
  and by reset-index semantics.
- The proof does not over-preserve stale coordinate names, because the issue
  identifies them as the bug.

## Commands Not Run

The following are the intended machine-check commands. They were not executed
because this task forbids running K tooling.

```sh
kompile fvk/mini-xarray-reset-index.k --backend haskell
kast --backend haskell fvk/reset-index-coord-names-spec.k
kprove fvk/reset-index-coord-names-spec.k
```

Expected outcome if the abstract K files are accepted by the toolchain:
`kprove` reduces the claims to `#Top`.

## Test Guidance

No tests were run and no test files were modified.

After machine checking and in a normal development setting, an explicit public
test for the MCVE would be useful. Existing reset-index tests that exercise
multi-index level preservation should be kept because this proof is a focused
name-set audit, not an integration proof of all xarray index behavior.
