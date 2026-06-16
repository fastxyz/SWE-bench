# FVK Findings

Status: source-audited and proof-constructed; no tests or Python execution were run.

## F1: raw weakrefs in `Grouper` were the pickle failure source

Input scenario:

`Figure.align_labels()` on a figure with two subplots, followed by `pickle.dumps(fig)`.

Observed before V1, from the public issue:

`TypeError: cannot pickle 'weakref.ReferenceType' object`.

Expected:

Pickling succeeds.

Cause:

`align_xlabels()` and `align_ylabels()` store Axes relationships in `FigureBase._align_label_groups`, and each group is a `cbook.Grouper`. Before V1, `Grouper` had no pickle protocol, so pickle traversed `_mapping`, whose keys and values are `weakref.ref` objects.

Resolution status:

Resolved by V1. `Grouper.__getstate__()` now exposes `list(self)`, the live object groups, rather than `_mapping`.

Traced obligations:

`SPEC.md` E1, E2, E4, E5; `PROOF_OBLIGATIONS.md` O1 and O4.

## F2: dropping `_align_label_groups` would satisfy only the narrow pickle symptom

Input scenario:

Aligned figure is pickled and later unpickled/drawn.

Observed with a possible discard-only alternative:

Pickling would succeed, but the sibling relationship used by `Axis._get_tick_boxes_siblings()` would be gone.

Expected:

The alignment relationship persists because the public docstrings say alignment persists for draw events after `align_xlabels()` / `align_ylabels()`.

Resolution status:

Resolved by V1. `__setstate__()` rebuilds the `Grouper` weakref mapping by joining each serialized object group, preserving sibling queries for objects that are strongly held by the figure graph.

Traced obligations:

`SPEC.md` E3 and E6; `PROOF_OBLIGATIONS.md` O2, O3, and O4.

## F3: standalone `Grouper` pickles need external strong references to members

Input scenario:

A `Grouper` is pickled by itself, with no other restored object holding strong references to the grouped objects.

Observed by static reasoning:

After unpickling, the new `Grouper` only stores weakrefs. If nothing else holds the member objects, they may be collected, so the groups may disappear.

Expected under this issue's intent:

For aligned figures, Axes are also held strongly by the figure object graph, so this liveness condition is satisfied.

Resolution status:

No code change needed for this issue. This is an inherent property of a weakref-backed container and is outside the public figure-pickling failure. The precondition is recorded in `SPEC.md`.

Traced obligations:

`SPEC.md` "Intent-only requirements" item 3; `PROOF_OBLIGATIONS.md` O2 preconditions.

## F4: invalid or handcrafted pickle state is outside the proven domain

Input scenario:

Calling `Grouper.__setstate__()` manually with malformed state such as empty groups or non-weak-referenceable members.

Observed by static reasoning:

The V1 implementation expects the state shape produced by `Grouper.__getstate__()`: a finite list of nonempty groups of valid members.

Expected under public intent:

Python pickle will feed `__setstate__()` the state produced by `__getstate__()` for this class. The public issue does not require defensive handling of corrupted pickle payloads or direct manual calls.

Resolution status:

No code change needed. Treating malformed manual state as out of domain keeps the fix minimal and aligned with the issue.

Traced obligations:

`SPEC.md` "Contracts" O2 and O3; `PROOF_OBLIGATIONS.md` domain assumptions.

## Proof-derived conclusion

No proof obligation requires a source edit beyond V1. The current `repo/lib/matplotlib/cbook.py` change is sufficient for the public intent: pickle-safe state plus preserved grouping semantics for figures.

