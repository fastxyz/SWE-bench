# FVK Proof Obligations

Status: constructed, not machine-checked.

## Claim Schema

Let `G` be a finite data-variable group passed to
`_infer_concat_order_from_coords`. Let `concat_dims(G)` be the returned
`concat_dims`. Let `combined(G)` be the result of `_combine_nd` for that group.

K-style claim schema, expressed in the abstract model used for this audit:

```text
claim validate(combined(G), concat_dims(G)) => ok
  requires exists d . bystander_dim(G, d) and not global_monotonic(combined(G), d)
   ensures no error is raised for d

claim validate(combined(G), concat_dims(G)) => error(d)
  requires d in concat_dims(G)
       and coordinate_dim(combined(G), d)
       and not global_monotonic(combined(G), d)
```

The concrete code under audit implements `validate` as the final loop in
`combine_by_coords`.

## PO-1: Intent-Derived Bystander Dimensions Are Out of Validation Scope

Statement: If a coordinate dimension has equal indexes across all datasets in
the current data-variable group, it must not be validated for monotonicity by
the final global-index check.

Provenance: `SPEC.md` I1 and I2.

Discharge status: discharged by PO-2 and PO-3.

## PO-2: `_infer_concat_order_from_coords` Excludes Equal-Index Dimensions

Statement: For any dimension `d`, if every index for `d` equals the first
dataset's index for `d`, `_infer_concat_order_from_coords` does not append `d`
to `concat_dims`.

Source mechanism: the code enters the concat-dimension branch only under:

```python
if not all(index.equals(indexes[0]) for index in indexes[1:]):
    concat_dims.append(dim)
```

Discharge status: discharged by direct control-flow inspection. When all
indexes equal the first, the negated condition is false, so `concat_dims.append`
is not reached for that dimension.

## PO-3: V1 Validation Iterates Only `concat_dims`

Statement: The final global-index monotonicity loop in `combine_by_coords`
checks exactly dimensions selected for concatenation by PO-2.

Source mechanism:

```python
for dim in concat_dims:
    if dim in concatenated:
        indexes = concatenated.indexes.get(dim)
        if not (indexes.is_monotonic_increasing
                or indexes.is_monotonic_decreasing):
            raise ValueError(...)
```

Discharge status: discharged by direct control-flow inspection. Any dimension
not in `concat_dims` is not bound to `dim` by this loop and cannot trigger this
specific `ValueError` branch.

## PO-4: Non-Monotonic Concat Dimensions Still Raise

Statement: For any dimension `d in concat_dims`, if `d` is present in the
combined result and the combined index is neither monotonic increasing nor
monotonic decreasing, `combine_by_coords` raises the same `ValueError` as
before V1.

Provenance: `SPEC.md` I3 and I4.

Discharge status: discharged by PO-3 plus inspection of the unchanged branch
body. V1 changed the loop domain from all dimensions to `concat_dims`; it did
not change the condition or exception inside the loop.

## PO-5: Public Compatibility Is Preserved

Statement: V1 must not change the public API or merge/concat behavior outside
the validation scope.

Provenance: `SPEC.md` C4.

Discharge status: discharged by diff inspection. The only source change is the
loop iterable and explanatory comment in `combine_by_coords`; no signature,
parameter, return, grouping, concat, or merge call changed.

## PO-6: Honesty Gate

Statement: The proof must not be represented as machine-checked, and tests
must not be removed based on this constructed proof.

Provenance: FVK `verify.md` honesty gate and the user's no-execution
constraint.

Discharge status: discharged by artifact labeling and by making no test-file
edits.
