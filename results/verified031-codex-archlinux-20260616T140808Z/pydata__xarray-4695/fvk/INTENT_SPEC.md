# Intent Spec

Status: constructed from public evidence before accepting candidate behavior.

## Required Behaviors

I1. `DataArray.loc[...]` is label-based indexing. When a mapping is supplied,
each mapping key is a dimension or coordinate indexer name, not an option to
`DataArray.sel`.

I2. Dimension names are semantically irrelevant for `.loc` dispatch. A dimension
named `method` must be selectable in the same way as a dimension named `dim2`.
The same rule applies to names that overlap other `.sel` parameters, including
`tolerance` and `drop`.

I3. Non-mapping `.loc` keys are first expanded against `DataArray.dims`; after
that expansion, the generated dimension-to-label mapping has the same
obligation as an explicit mapping key.

I4. `DataArray.sel` keeps its public API: direct keyword arguments may express
dimension indexers, while named parameters such as `method`, `tolerance`, and
`drop` keep their documented meanings. The unambiguous way to select a
dimension with a colliding name through `.sel` is the positional mapping form.

I5. Internal helpers that dynamically construct a dimension indexer and pass it
to `.sel` must preserve the dimension name as data. Dynamically derived
dimension names must not be unpacked into `.sel` keyword parameters.

I6. The fix must not alter downstream label lookup semantics: invalid labels,
missing dimensions, exact-vs-inexact matching, and coordinate/index rewriting
remain the responsibility of `.sel` and lower-level indexing code.

## Domain

The audited domain is in-domain label selection dispatch:

- the receiver is a `DataArray` or `Dataset`-like object with `.sel`;
- the key or generated key is a mapping from dimension or coordinate names to
  labels, slices, arrays, or DataArray indexers accepted by existing `.sel`;
- the audit covers dispatch of indexers into `.sel`, not pandas index lookup
  internals or full xarray selection semantics.

Out of domain:

- changing direct `da.sel(method="a")` to mean a dimension indexer;
- changing `.sel(method=...)`, `.sel(tolerance=...)`, or `.sel(drop=...)`
  parameter semantics;
- proving termination, performance, or pandas index lookup behavior.
