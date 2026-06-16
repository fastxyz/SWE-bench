# FVK Notes

## Source Change

Changed `repo/django/db/models/sql/query.py` after the FVK audit:

- `Query.get_count()` now skips `prune_unused_annotations()` when
  `obj.combinator` is set.
- `Query.exists()` now skips top-level pruning when `q.combinator` is set.

This addresses `fvk/FINDINGS.md` F1. The corresponding proof obligations are
PO7 and PO8 in `fvk/PROOF_OBLIGATIONS.md`: non-combined terminal queries may
prune safely, but combined queries preserve selected-column row shape and row
identity by not pruning at this stage.

## V1 Decisions Kept

Kept annotation alias delta tracking from V1. This is justified by F2 and PO1,
PO4: masking an annotation is not sufficient when the annotation introduced
joins, because stale joins can change `COUNT(*)` cardinality.

Kept lookup-reference tracking and annotation dependency tracking. This is
justified by F3 and PO2, PO3: annotations referenced by filters or by retained
annotations are required by the public issue and must remain available.

Kept conservative preservation of selected annotations for `distinct()` count
and selected non-aggregate annotations with multi-valued joins. This is
justified by F4 and PO5: these annotations can affect row identity or
cardinality, so stripping them would violate the "same results" obligation.

Kept the `group_by is True and not annotations` cleanup. This is justified by
PO6: after all annotations are removed, the stale aggregate grouping flag should
not force grouped `exists()` SQL.

## Verification Status

The FVK proof is constructed but not machine-checked. The task forbids tests,
Python execution, and K tooling, so no runtime result is claimed. The exact
future commands are recorded in `fvk/PROOF.md` and
`fvk/PROOF_OBLIGATIONS.md`.
