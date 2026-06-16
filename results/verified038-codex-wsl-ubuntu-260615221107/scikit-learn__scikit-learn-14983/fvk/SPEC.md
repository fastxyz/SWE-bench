# FVK Specification

Status: constructed, not machine-checked.

## Scope

The audited production units are:

- `repo/sklearn/model_selection/_split.py::_RepeatedSplits.__repr__`
- `repo/sklearn/model_selection/_split.py::_build_repr`

The observable under audit is the string returned by `repr` for
`RepeatedKFold` and `RepeatedStratifiedKFold`, plus compatibility of the shared
repr helper for existing splitters.

## Public Intent Ledger

This file mirrors the detailed ledger in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

- E1/E3 require repeated splitters to stop returning object-at-address reprs.
- E2 requires default repeated reprs to expose `n_splits=5`,
  `n_repeats=10`, and `random_state=None`.
- E4 requires the repr behavior to live on `_RepeatedSplits`.
- E5/E9 require `_build_repr` to find parameters stored in `cvargs`.
- E6/E7/E8 require existing `_build_repr`/`_pprint` representation conventions
  to be preserved for other cross-validation splitters.
- E10 constrains this pass: no test-file edits and no execution.

## Formal Contract

O1. `_RepeatedSplits.__repr__(self)` returns `_build_repr(self)`.

O2. `_build_repr(self)` computes the constructor parameter names from
`self.__class__.__init__`, excluding `self` and `**kwargs`, using the same sorted
order as the existing helper.

O3. For each constructor parameter key, `_build_repr` resolves its value as:

1. If `self` has a direct attribute named `key`, use that value, even when the
   value is `None`.
2. Otherwise, if `self` has a `cvargs` mapping and `key` is present there, use
   `self.cvargs[key]`.
3. Otherwise, use `None`.

O4. `_build_repr` skips deprecated parameters using the existing warning logic;
the V1 change must not alter that behavior.

O5. `_build_repr` returns `ClassName(_pprint(params, offset=len(ClassName)))`.
The order of rendered parameters is therefore the established sorted order from
`_pprint`.

O6. For the default repeated splitter state:

- class name `RepeatedKFold`
- sorted constructor keys `n_repeats`, `n_splits`, `random_state`
- direct attributes `n_repeats=10`, `random_state=None`
- `cvargs["n_splits"] = 5`

the repr string is
`RepeatedKFold(n_repeats=10, n_splits=5, random_state=None)`.

O7. For the analogous default `RepeatedStratifiedKFold` state, the repr string
is `RepeatedStratifiedKFold(n_repeats=10, n_splits=5, random_state=None)`.

O8. Frame condition: split generation, `get_n_splits`, constructor signatures,
and existing direct-attribute reprs are unchanged. A direct attribute must not be
overridden by a same-named entry in `cvargs`.

## Boundary and Assumptions

This FVK pass models the repr-construction fragment, not all Python
introspection, warnings, or NumPy printing behavior. The abstraction is
property-complete for the defect because it retains the observable class name,
parameter names, parameter values, direct-vs-`cvargs` lookup order, and rendered
string.

No total-correctness or performance proof is attempted. There are no loops in
the audited helper logic.

