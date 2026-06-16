# FVK Proof Obligations

Status: constructed, not machine-checked.

## Domain assumptions

DA1. `Grouper` members are hashable and weak-referenceable, matching the class docstring.

DA2. For the figure-pickling scenario, grouped Axes are strongly referenced elsewhere in the figure object graph while the restored `Grouper` stores weakrefs.

DA3. `__setstate__()` is proved for states produced by `Grouper.__getstate__()`: finite lists of nonempty object groups. Corrupted or manually fabricated state is out of scope.

DA4. The rest of the figure state is pickleable under Matplotlib's existing figure pickle protocol. The issue reports that pickling works if `align_labels()` is removed, so the new obligation is the aligned-label grouper state.

## O1: `__getstate__` exposes no raw weakrefs

Claim:

For any valid `Grouper` `G`,

```text
state = G.__getstate__()
state == list(G)
state contains only live grouped objects, not weakref.ref keys or values
```

Source code:

```python
def __getstate__(self):
    return list(self)
```

Why it matters:

The public error is `TypeError: cannot pickle 'weakref.ReferenceType' object`. If pickle sees only ordinary grouped objects, the specific weakref error is removed.

## O2: round-trip preserves the sibling relation

Claim:

For any valid `Grouper` `G`, let `S = G.__getstate__()`. For a fresh `Grouper` `G2` after `G2.__setstate__(S)`, for all members `a`, `b` in `S`:

```text
same_group(S, a, b) iff G2.joined(a, b)
```

Source code:

```python
def __setstate__(self, state):
    self._mapping = {}
    for group in state:
        self.join(*group)
```

Why it matters:

`Axis._get_tick_boxes_siblings()` uses `grouper.get_siblings(self.axes)`. Preserving sibling relations preserves the aligned-label behavior.

## O3: `__setstate__` loop invariant

Let `S = [g0, g1, ..., gn-1]`.

Invariant after `i` iterations:

```text
Processed = [g0, ..., g(i-1)]
For all a, b in union(Processed):
    G2.joined(a, b) iff a and b are in the same processed group
For all a in union(Processed), b in union(S[i:]):
    G2.joined(a, b) is false unless a == b and b has already been introduced
```

Initialization:

Before the loop, `_mapping = {}`. No nontrivial sibling relation exists, so the invariant holds for `i = 0`.

Step:

For group `gi`, `join(*gi)` introduces every member of `gi` into one weakref set. Because `S` came from `Grouper.__iter__()`, groups are disjoint, so previous groups are not merged accidentally.

Exit:

At `i = n`, all groups from `S` have been processed, which is exactly O2.

## O4: figure-level pickling composition

Claim:

For a figure `F` after `F.align_labels()`, if all non-alignment state of `F` is pickleable, then the `_align_label_groups` portion is pickleable and preserves x/y grouping.

Reasoning:

`_align_label_groups` is a dictionary with `"x"` and `"y"` `Grouper` values. Pickle invokes each grouper's `__getstate__()`. By O1, the pickle-visible state contains no raw weakrefs. On unpickle, O2 restores the partition for each grouper. Therefore the aligned-label state no longer blocks figure pickling and remains semantically usable.

## O5: compatibility and frame conditions

Claim:

All existing public `Grouper` operations keep their behavior on live groupers:

```text
join, joined, remove, __contains__, __iter__, get_siblings
```

Reasoning:

V1 adds pickle protocol methods only. It does not alter the existing methods' bodies or signatures.

## K artifacts

The constructed K sketch is in:

- `fvk/mini-python-grouper.k`
- `fvk/grouper-pickle-spec.k`

The intended later commands are recorded in `fvk/PROOF.md`. They were not run.

