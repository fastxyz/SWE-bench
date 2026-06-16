# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, Python, or test commands were run.

## Claims

C-001, `collect(STATES)`: collecting an abstract list of partition maps allocates one fresh public object id per state and stores at that id a map extensionally equal to the corresponding state.

C-002, `collectSize(STATES)`: collecting an abstract list of `(size, partition-map)` states allocates one fresh public object id per state, preserves the size component, and stores a map extensionally equal to the corresponding partition map.

These are encoded in `fvk/partitions-snapshot-spec.k` over the mini semantics in `fvk/mini-python-partitions.k`.

## Proof Sketch

Base case: `STATES == .List`. The `collect(.List)` and `collectSize(.List)` rules rewrite to `.K` without changing the heap, `nextId`, or output list. `idsAreRange` / `sizeIdsAreRange` and `heapMatches` / `sizeHeapMatches` reduce to `true` on empty lists.

Step case for normal mode: `STATES == ListItem(M) REST`. The `collect` rule rewrites to `emit(M) ~> collect(REST)`. The `emit(M)` rule allocates the current `nextId` as a new public id, writes `H[ID <- M]`, appends `ID` to the output list, and increments `nextId`. The circularity hypothesis applies to `collect(REST)` from `ID + 1`. Therefore output ids are the consecutive range starting at the original `ID`, and the heap at each id matches the corresponding map in `STATES`.

Step case for size mode: `STATES == ListItem(state(S, M)) REST`. The `collectSize` rule rewrites to `emitSize(S, M) ~> collectSize(REST)`. `emitSize` performs the same heap allocation and appends `out(S, ID)`, preserving the size component. The circularity hypothesis applies to the rest of the states.

Freshness follows from the monotonic `nextId` increment. Snapshot stability follows because later generator updates affect the internal working dictionary, while public outputs refer to separately allocated heap ids. Extensional equality follows from the heap update storing the same map bindings `M` at the fresh id.

## Connection to V1 Source

The K `emit(M)` rule models `yield ms.copy()` in `repo/sympy/utilities/iterables.py`. The K `emitSize(S, M)` rule models `yield sum(ms.values()), ms.copy()`. `dict.copy()` is the Python operation corresponding to fresh allocation with equal map contents.

The proof deliberately abstracts the partition enumeration as `STATES`. This is adequate for V1 because the source edit does not change the code that computes the next `ms`; it only changes whether the yielded object aliases `ms`.

## Commands Not Run

```sh
cd fvk
kompile mini-python-partitions.k --backend haskell
kast --backend haskell partitions-snapshot-spec.k
kprove partitions-snapshot-spec.k
```

Expected machine-check result in an environment with K installed: `#Top` for both claims. Until then, this remains constructed evidence only.

## Test Guidance

Do not remove tests based on this proof unless the commands above are run successfully. If new public tests are added later, the highest-value checks are:

- `list(partitions(6, k=2))` equals the expected partition dictionaries without caller-side `.copy()`.
- The dictionary objects in that list have distinct identities.
- The `P` dictionaries from `list(partitions(6, k=2, size=True))` have distinct identities and match their `M` values.
- Mutating a yielded dictionary does not affect later yielded dictionaries.
