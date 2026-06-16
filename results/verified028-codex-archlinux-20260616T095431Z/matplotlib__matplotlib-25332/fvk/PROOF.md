# FVK Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, tests, or Python code were run.

## Summary

The V1 fix satisfies the public issue intent. It changes `Grouper`'s pickle-visible state from raw weakref internals to ordinary live object groups, and it reconstructs weakref groups on unpickle. This removes the reported `weakref.ReferenceType` pickle failure while preserving the alignment sibling relation used during later draws.

## Proof of O1: `__getstate__` exposes no raw weakrefs

`Grouper.__iter__()` first calls `clean()`, then yields each unique live group as:

```python
[x() for x in group]
```

The yielded values are the referenced objects, not the `weakref.ref` wrappers. V1's `__getstate__()` returns `list(self)`, so its result is a list of those ordinary object lists. Therefore pickle does not traverse `Grouper._mapping` and does not encounter the raw weakref keys or values that caused the issue.

Constructed K claim:

```text
getstate(grouper(GS)) => result(GS)
requires validGroups(GS)
ensures noWeakRefs(GS)
```

## Proof of O2 and O3: restore preserves groups

`__setstate__()` starts from an empty mapping. The loop processes each serialized group and calls `join(*group)`.

Base case:

Before processing any group, the restored grouper has no sibling relation, matching the empty prefix of the serialized state.

Inductive step:

Assume the restored grouper matches the first `i` groups. The next state group `gi` is disjoint from earlier groups because it came from `Grouper.__iter__()` over unique disjoint sets. `join(*gi)` creates exactly one set for all members of `gi`; it does not merge with earlier groups because no member overlaps them. Thus the restored grouper matches the first `i + 1` groups.

Exit:

After the loop, every serialized group has been joined, so every pair of members has the same `joined(a, b)` truth value as in the serialized partition. This proves O2.

Constructed K circularity:

```text
joinAll(ACC, TODO) => result(ACC ++ TODO)
requires validGroups(ACC ++ TODO) and disjointGroups(ACC ++ TODO)
```

The loop measure is the number of unprocessed groups. Termination is evident for finite Python lists, but the FVK result is still labeled partial correctness because no machine check was run.

## Proof of O4: figure composition

The figure contains `_align_label_groups = {"x": Grouper(), "y": Grouper()}`. `align_xlabels()` and `align_ylabels()` populate those groupers with Axes. When pickling a figure, pickle uses each `Grouper.__getstate__()` rather than traversing `_mapping`.

By O1, neither grouper contributes raw weakrefs to the pickle stream. By O2, the unpickled x and y groupers answer sibling queries consistently with the serialized groups. Since the issue states pickling works when `align_labels()` is removed, the proof only needs to discharge the new aligned-label group state; V1 does so.

## Adequacy and compatibility

The proof targets exactly the public issue:

- It removes the reported weakref pickle failure.
- It preserves the persistent alignment relation promised by the label-alignment docstrings.
- It does not change public method signatures or existing non-pickle `Grouper` operations.

Residual domain caveat:

A standalone restored `Grouper` only holds weakrefs, so its members must be strongly held elsewhere. A restored figure satisfies this because Axes are part of the figure object graph. This is recorded in `FINDINGS.md` F3 and does not require a source change for this issue.

## Commands for later machine check

These commands are intentionally not run in this workspace:

```sh
kompile fvk/mini-python-grouper.k --backend haskell
kast --backend haskell fvk/grouper-pickle-spec.k
kprove fvk/grouper-pickle-spec.k
```

Expected result after a real K formalization pass:

`kprove` should discharge the two reachability claims and the loop circularity as `#Top`, modulo the abstraction that `Grouper` is represented by its live disjoint partition rather than Python's concrete weakref map.

## Test guidance

No test files were edited. Useful tests to add in the fixed upstream suite would cover:

- `pickle.dumps(fig)` after `fig.align_labels()`.
- `pickle.loads(pickle.dumps(fig))` preserving aligned-label sibling groups for a figure whose Axes are still strongly held by the figure graph.

Existing broad figure pickle tests should be kept unless and until a real machine-checked proof covers their full integration behavior.

