# FVK Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 fix to `Coarsen.construct` in
`repo/xarray/core/rolling.py`. The public issue is about coordinate
classification after `Dataset.coarsen(...).construct(...)`; the shared
implementation also serves `DataArray.coarsen(...).construct(...)`, so the
DataArray temporary-dataset path is included in the compatibility proof.

The proof is partial correctness over successful calls that satisfy existing
argument validation and reshape preconditions. No test, Python, or K command
was executed.

## Intent ledger summary

- E1/E2: The issue says all variables that were coordinates before
  `coarsen.construct` should stay coordinates afterward.
- E3: The example coordinate `day` is a non-dimension coordinate whose dims are
  reshaped from `(time)` to `(year, month)`.
- E6: The implementation loops over `obj.variables.items()` and assigns every
  key into `reshaped`.
- E7: `Dataset.set_coords` marks provided existing variable names as
  coordinates.
- E8: The DataArray path uses a temporary `_THIS_ARRAY` variable that is not in
  `self.obj.coords`.

The complete ledger is in `PUBLIC_EVIDENCE_LEDGER.md`.

## Abstract model

The model abstracts each xarray object to:

- `VARS`: the set of variable names present in the dataset-like object.
- `COORDS`: the set of names classified as coordinates.

Array values, attrs, indexes, and exact dimension sizes are abstracted away
because the public bug is only about coordinate membership. The abstraction
retains the discriminating observable: whether `day` is in the result's
coordinate set.

The core transition is:

1. `reshapeAll(ds(VARS, COORDS))` preserves `VARS` and resets coordinate status
   to whatever the empty-dataset assignment path establishes.
2. `setCoords(ds(VARS, RCOORDS), NAMES)` requires `NAMES subsetSet VARS` and
   returns `ds(VARS, RCOORDS union NAMES)`.
3. The V2 implementation uses `NAMES = COORDS`, while the pre-fix
   implementation used `NAMES = COORDS intersect window_dim_names`.

The minimal K-style semantics are in `mini-xarray.k`; the claims are in
`coarsen-construct-spec.k`.

## Formal claims

- `COORD-PRESERVATION-V2`: for any in-domain object where original coordinates
  are variables, the audited implementation returns a result whose coordinate
  set contains every original coordinate.
- `LOOP-PRESERVES-NAMES`: the reshape loop preserves variable names, so every
  original coordinate name is available for `set_coords`.
- `PREFIX-COUNTEREXAMPLE`: the pre-fix intersection with `window_dim` drops a
  non-dimension coordinate such as `day`.
- `DATAARRAY-TEMP-PRESERVATION`: the shared fix preserves DataArray coordinates
  without relying on `_THIS_ARRAY` being a coordinate.

## Adequacy

The formal claims match the public intent:

- They prove coordinate preservation for all original coordinate names, not only
  the example name `day`.
- They include non-dimension coordinates and dimension coordinates.
- They do not overclaim exact equality of result coordinate sets, because the
  issue requires preservation, not absence of any additional xarray
  dimension-coordinate classification.
- They do not change or specify invalid argument behavior beyond existing
  validation.

The adequacy details are in `INTENT_SPEC.md`, `FORMAL_SPEC_ENGLISH.md`, and
`SPEC_AUDIT.md`.

