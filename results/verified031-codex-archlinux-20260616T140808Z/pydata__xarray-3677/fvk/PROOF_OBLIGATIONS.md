# FVK Proof Obligations

Status: constructed, not machine-checked.

## Abstract State

- `DS`: the receiver Dataset.
- `DA`: a DataArray.
- `DDA`: `DA.to_dataset()`.
- `M`: a Dataset or mapping accepted by the pre-existing method.
- `OW`: normalized overwrite variable set.
- `core(objs, priority_arg, compat, join, fill_value)`: the call to
  `merge_core()` with those arguments.

The abstraction is property-complete for this issue because it preserves the
axis under test: whether `merge_core()` and overwrite branching receive a raw
`DataArray` or a Dataset/mapping-like object.

## PO-001: DataArray normalization

K-style claim:

```k
// SPEC-PROVENANCE: E-001, E-002, E-005
claim dataset_merge_method(DS, DA, OW, COMPAT, JOIN, FILL)
  => dataset_merge_method(DS, toDataset(DA), OW, COMPAT, JOIN, FILL)
  requires isDataArray(DA) andBool isNamed(DA)
```

Obligation: every in-domain DataArray input is converted before any operation
requiring `other` to be mapping-like.

## PO-002: No-overwrite branch calls `merge_core` with normalized input

K-style claim:

```k
// SPEC-PROVENANCE: E-001, E-002, E-003
claim dataset_merge_method(DS, DA, emptySet, COMPAT, JOIN, FILL)
  => core(list(DS, toDataset(DA)), none, COMPAT, JOIN, FILL)
  requires isDataArray(DA) andBool isNamed(DA)
```

Obligation: the reported `ds.merge(da)` call reaches the same object shape as
top-level `merge()` before merge resolution.

## PO-003: Overwrite-all branch uses normalized membership

K-style claim:

```k
// SPEC-PROVENANCE: E-006
claim dataset_merge_method(DS, DA, vars(toDataset(DA)), COMPAT, JOIN, FILL)
  => core(list(DS, toDataset(DA)), priority(1), COMPAT, JOIN, FILL)
  requires isDataArray(DA) andBool isNamed(DA)
```

Obligation: `set(other)` is taken over `toDataset(DA)`, not `DA`.

## PO-004: Partial-overwrite branch iterates normalized `.items()`

K-style claim:

```k
// SPEC-PROVENANCE: E-002, E-006
claim dataset_merge_method(DS, DA, OW, COMPAT, JOIN, FILL)
  => core(list(DS, splitNoOverwrite(toDataset(DA), OW),
                  splitOverwrite(toDataset(DA), OW)),
          priority(2), COMPAT, JOIN, FILL)
  requires isDataArray(DA)
       andBool isNamed(DA)
       andBool OW =/=K emptySet
       andBool OW =/=K vars(toDataset(DA))
```

Obligation: `.items()` applies only to the normalized Dataset/mapping.

## PO-005: DataArray conversion errors are preserved

K-style claim:

```k
// SPEC-PROVENANCE: E-004
claim dataset_merge_method(DS, DA, OW, COMPAT, JOIN, FILL)
  => raises(toDatasetError(DA))
  requires isDataArray(DA) andBool notBool canConvertToDataset(DA)
```

Obligation: unnamed DataArrays and name/coordinate conflicts fail at the same
conversion boundary used by top-level `merge()`.

## PO-006: Non-DataArray frame condition

K-style claim:

```k
// SPEC-PROVENANCE: E-006, E-007
claim dataset_merge_method(DS, M, OW, COMPAT, JOIN, FILL)
  => legacy_dataset_merge_method(DS, M, OW, COMPAT, JOIN, FILL)
  requires notBool isDataArray(M)
```

Obligation: Dataset and mapping inputs follow the pre-existing implementation.

## PO-007: Honesty and completeness boundary

Obligation: because no execution or K tooling may be run, the proof remains a
constructed proof. It can justify source-level confidence and code changes
derived from intent, but not test deletion or a machine-checked proof claim.
