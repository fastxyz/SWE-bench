# Intent Spec

Status: constructed for FVK audit, not machine-checked.

## Scope

This FVK pass audits the V1 fix for `pydata__xarray-4629`. The target behavior is the attrs-combination path for `merge_attrs` as used by `xr.merge(..., combine_attrs="override")`, with compatibility checks for the helper's other attrs modes and public callers.

## Required Behavior

I1. For a non-empty attrs sequence and `combine_attrs="override"`, the result attrs must contain the same key/value bindings as the first source attrs mapping.

I2. For `combine_attrs="override"`, the result attrs mapping must be a distinct mutable mapping from the first source attrs mapping. Mutating the merged result's attrs dictionary must not mutate the source dataset's attrs dictionary.

I3. The `override` mode ignores attrs from later inputs for result contents, except that later inputs still participate in the surrounding merge behavior outside this helper.

I4. The intended copy is a shallow mapping copy. The public issue demonstrates mutation of the attrs dictionary itself (`attrs["a"] = ...`), and the existing `no_conflicts` and `identical` branches also use `dict(...)`. No public evidence requires deep-copying attr values.

I5. Existing documented behavior for other modes remains: `drop` returns empty attrs, `no_conflicts` combines compatible attrs and errors on conflicts, `identical` requires identical attrs, invalid `combine_attrs` raises `ValueError`, and an empty attrs input returns `None` by existing internal convention.

I6. Public function signatures and accepted `combine_attrs` option names for `merge`, `concat`, and combine helpers must not change.
