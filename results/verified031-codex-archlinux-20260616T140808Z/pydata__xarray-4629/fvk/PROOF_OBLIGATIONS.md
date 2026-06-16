# Proof Obligations

Status: constructed, not machine-checked.

## PO1 - Override Content Selection

For any non-empty attrs sequence `A`, `merge_attrs(A, "override")` returns attrs with the same key/value bindings as `A[0]` and ignores later attrs for contents.

Evidence: E3, E5. Formal claim: `MERGE-ATTRS-OVERRIDE-COPY`.

Status: discharged by V1 source and constructed proof.

## PO2 - Override Non-Aliasing

For any non-empty attrs sequence `A`, `merge_attrs(A, "override") is not A[0]`. Therefore dictionary-key updates to the result attrs do not update the first source attrs mapping.

Evidence: E1, E2, E4. Formal claim: `MERGE-ATTRS-OVERRIDE-COPY`.

Status: discharged by V1 source because `dict(variable_attrs[0])` allocates a fresh dictionary.

## PO3 - Merge Propagation

`xr.merge(..., combine_attrs="override")` must propagate the helper's fresh attrs mapping into the resulting `Dataset` without reintroducing aliasing.

Evidence: E7, E8. Source path: `merge_core` calls `merge_attrs`; `merge` passes `_MergeResult.attrs` to `Dataset._construct_direct`, which stores that object directly. If the helper is fresh, the result is fresh; if the helper aliases, the bug appears.

Status: discharged by PO2 plus source inspection.

## PO4 - Compatibility With Other Modes and Callers

The fix must not alter public signatures, accepted mode names, or documented behavior of `drop`, `no_conflicts`, `identical`, invalid mode, concat, or combine call paths.

Evidence: I5, I6, E6. Formal claims: `MERGE-ATTRS-DROP`, `MERGE-ATTRS-EMPTY`, `MERGE-ATTRS-NO-CONFLICTS`, `MERGE-ATTRS-IDENTICAL`, `MERGE-ATTRS-BAD-MODE`.

Status: discharged by source inspection and compatibility audit. No V2 source edit required.

## PO5 - Shallow Copy Scope

The fix must copy the attrs mapping object, but it is not required to deep-copy attr values.

Evidence: E4 and existing sibling-branch behavior. A deep copy would exceed the public issue and could change user-visible identity of attr values.

Status: discharged. V1 uses `dict(...)`, matching the intended shallow-copy contract.

## PO6 - Empty Attrs Boundary

When there are no attrs to merge, the helper returns `None`; this creates no source/result alias because no source attrs mapping participates.

Evidence: existing helper convention in source. Formal claim: `MERGE-ATTRS-EMPTY`.

Status: unchanged and not a defect for this issue.
