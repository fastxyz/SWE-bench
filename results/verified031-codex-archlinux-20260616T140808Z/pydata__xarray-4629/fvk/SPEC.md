# FVK Spec

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Target

Audited source unit: `repo/xarray/core/merge.py::merge_attrs`, with propagation through `merge_core` and public `merge`. Compatibility was checked for shared helper callers in `concat` and combine paths.

This is a focused FVK pass for the reported issue. The proof model covers the observable property under repair: attrs contents selected by `combine_attrs="override"` and absence of object aliasing between the result attrs mapping and the first source attrs mapping.

## Public Intent Ledger

- E1, prompt: "`combine_attrs='override'` does not copy attrs but instead references attrs from the first object" -> aliasing is the defect.
- E2, prompt: "attrs of the merged product should be able to be changed without having any effect on the sources" -> result attrs mutation must not mutate source attrs.
- E3, prompt example: result initially has first attrs value (`a3 == "b"`) -> override chooses first mapping contents.
- E4, prompt hint: `dict(variable_attrs[0])`, matching other branches -> shallow copy is intended and sufficient.
- E5, merge docstring: `override` copies attrs from first dataset to result -> fresh result mapping with first contents.
- E7/E8, implementation: `merge` uses `_construct_direct`, which stores attrs directly -> the helper must create the fresh mapping.

The full ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

## Domain

For the K claim:

- `variable_attrs` is non-empty.
- The first attrs object has identity `ID0` and contents map `M0`.
- `combine_attrs` is `override`.
- The allocator state supplies a result identity `N` with `N != ID0`.
- Key and value objects inside `M0` are arbitrary and are copied by reference as Python `dict(...)` does.

Other `merge_attrs` modes are covered by proof obligations and source inspection rather than the central aliasing K claim, because the reported issue and V1 edit concern only `override`. They remain part of the adequacy/compatibility audit.

## Function Contract

`merge_attrs(variable_attrs, "override")` for non-empty `variable_attrs` must return a fresh dictionary `R` such that:

- `R` has the same key/value bindings as `variable_attrs[0]`;
- `R is not variable_attrs[0]`;
- updates to `R` do not update `variable_attrs[0]`;
- no later attrs mapping contributes a key/value binding in override mode.

For modes outside the issue slice:

- empty `variable_attrs` returns `None`;
- `drop` returns empty attrs;
- `no_conflicts` starts from a shallow copy of the first attrs, unions compatible later attrs, and raises `MergeError` on conflicts;
- `identical` starts from a shallow copy of the first attrs and raises `MergeError` if any later attrs differ;
- unknown `combine_attrs` raises `ValueError`.

## Frame Conditions

- No public function signatures change.
- No variable, coordinate, dimension, index, or data-merging behavior changes.
- Attr value objects are not deep-copied; only the attrs mapping object is fresh.

## Formal Files

- `fvk/mini-python.k`: mini Python attrs fragment that models attr map identity, map contents, and shallow-copy allocation.
- `fvk/merge-attrs-spec.k`: K reachability claims for the override copy property and smoke claims for other helper modes.

Exact commands to machine-check later are recorded in `fvk/PROOF.md`.
