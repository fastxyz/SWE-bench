# FVK Spec: aligned-label figure pickling

Status: constructed from public intent and source inspection; not machine-checked.

## Intent-only requirements

1. Public issue requirement: after `fig.align_labels()`, `pickle.dumps(fig)` should complete successfully.
   Evidence: `benchmark/PROBLEM.md` says "Unable to pickle figure after calling `align_labels()`" and "Expected outcome: Pickling successful".

2. Alignment state should not be silently lost when making pickling work.
   Evidence: `Figure.align_xlabels()` and `Figure.align_ylabels()` docstrings say "Alignment persists for draw events after this is called." The aligned-Axes relationship is therefore persistent figure state, not disposable draw-time scratch state.

3. The relevant domain is a figure whose other state is already pickleable, with label-alignment groups containing live Axes objects that are hashable, weak-referenceable, and also strongly held elsewhere in the figure object graph.
   Evidence: `FigureBase.__init__` stores `_align_label_groups = {"x": cbook.Grouper(), "y": cbook.Grouper()}` before `_localaxes`; Axes are also held by figure axes lists. `Grouper` documents that grouped objects must be hashable and weak-referenceable.

## Public evidence ledger

| ID | Source | Evidence | Obligation | Status |
|---|---|---|---|---|
| E1 | prompt | "Unable to pickle figure after calling `align_labels()`" | The pre-fix `TypeError: cannot pickle 'weakref.ReferenceType' object` is a bug, not behavior to preserve. | Encoded by O1 and O4. |
| E2 | prompt | "Expected outcome: Pickling successful" | Pickle traversal of an aligned figure must not expose raw `weakref.ref` objects. | Encoded by O1 and O4. |
| E3 | source docstring | "Alignment persists for draw events after this is called." | A fix should preserve the alignment sibling relation through serialization rather than discard it. | Encoded by O2 and O4. |
| E4 | implementation | `align_xlabels()` / `align_ylabels()` call `self._align_label_groups[name].join(ax, axc)`. | The failing structure is `cbook.Grouper`; the spec must model its partition relation. | Used as implementation evidence for the model. |
| E5 | implementation | `Grouper` stores `weakref.ref` keys and values in `_mapping`. | Raw internal representation is not pickle-safe; pickle state must be representation-independent. | Encoded by O1. |
| E6 | implementation | `Axis._get_tick_boxes_siblings()` reads `grouper.get_siblings(self.axes)`. | After restore, group membership must support the same sibling queries. | Encoded by O2 and O4. |

## Formal model

The model abstracts a `Grouper` by its live partition:

- `groups(G)` is the list of disjoint nonempty groups yielded by `Grouper.__iter__()` after cleaning dead weakrefs.
- `same_group(groups, a, b)` holds iff `a` and `b` occur in the same group.
- `pickle_state(G)` is the result of `G.__getstate__()`.
- `restore(S)` is a fresh `Grouper` after `__setstate__(S)`.

The concrete weakref map is deliberately hidden in the observable model. Weakrefs are an implementation detail; public behavior is the partition returned by sibling queries.

## Contracts

O1. Serializable state:

For every valid `Grouper` `G`, `G.__getstate__()` returns `groups(G)`, a finite list of ordinary object lists. No `weakref.ref` object from `G._mapping` appears in that state.

O2. Partition preservation:

For every valid `Grouper` `G`, let `S = G.__getstate__()` and let `G2` be a fresh `Grouper` restored with `G2.__setstate__(S)`. For all live objects `a`, `b` in `S`, `G.joined(a, b) == G2.joined(a, b)`.

O3. `__setstate__` loop invariant:

After processing the first `i` groups of valid state `S`, the fresh grouper contains exactly the same sibling relation as those first `i` groups and no relation involving later groups. The transition for group `S[i]` preserves earlier groups and adds exactly the sibling relation for `S[i]`.

O4. Figure-level composition:

For a figure whose only previously unpickleable aligned-label state is `_align_label_groups`, pickling calls `Grouper.__getstate__()` for both x and y groupers. Because O1 removes raw weakrefs and O2 preserves the sibling relation, `pickle.dumps(fig)` can succeed without losing the state read by `Axis._get_tick_boxes_siblings()`.

O5. Compatibility:

No public method signature changes. `Grouper.join`, `joined`, `remove`, `__iter__`, and `get_siblings` keep their existing behavior. The only public behavioral addition is that a `Grouper` embedded in a pickleable object graph can now participate in pickling.

## Adequacy audit

The formal obligations match the public intent:

- E1 and E2 require eliminating raw weakrefs from the pickle-visible state. O1 states exactly that.
- E3 and E6 require preserving alignment relationships, not merely dropping them. O2 and O4 state that.
- E4 and E5 identify `Grouper` as the root cause. The V1 change is at that container, not at an unrelated caller.

No claim relies on hidden tests, upstream patches, internet sources, or evaluator output.

