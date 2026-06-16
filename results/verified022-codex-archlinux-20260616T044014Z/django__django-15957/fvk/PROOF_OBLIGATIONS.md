# FVK Proof Obligations

Status: constructed from public intent and source inspection; not machine-checked.

## PO1: No public filter call while a queryset is still sliced

- Intent links: SPEC I1, I6; FINDINGS F1.
- Claim: if `queryset.query.is_sliced` is true, `_filter_prefetch_queryset()` must call `queryset.query.clear_limits()` before the final `queryset.filter(predicate)`.
- Source evidence: `repo/django/db/models/fields/related_descriptors.py` captures marks, builds row-number lookups, clears limits, then calls `.filter()`.
- Discharge: satisfied. The helper is the only V2 path used by covered collection prefetch relation filters.

## PO2: Slice bounds become correct per-partition row-number predicates

- Intent links: SPEC I2, I3, I4; FINDINGS F1.
- Claim: for each partition, Django slice `[low_mark:high_mark]` is represented by `row_number > low_mark` and, when `high_mark` is not `None`, `row_number <= high_mark`.
- Boundary cases:
  - `[:3]` becomes `row_number > 0 AND row_number <= 3`.
  - `[1:3]` becomes `row_number > 1 AND row_number <= 3`.
  - `[3:]` becomes `row_number > 3`.
- Discharge: satisfied by the helper's `GreaterThan(window, low_mark)` and conditional `LessThanOrEqual(window, high_mark)` predicates.

## PO3: Partition keys match relation grouping

- Intent links: SPEC I2, C4; FINDINGS F6.
- Claims:
  - Reverse many-to-one groups related rows by `self.field.name`.
  - Many-to-many groups related rows by `self.query_field_name`.
  - Reverse generic relations group related rows by both content type and object id.
- Source evidence:
  - Reverse many-to-one passes `self.field.name`.
  - Many-to-many passes `self.query_field_name` while preserving `_next_is_sticky()`.
  - Generic relation passes `(self.content_type_field_name, self.object_id_field_name)`.
- Discharge: satisfied.

## PO4: Ordering is preserved when present and made backend-valid when absent

- Intent links: SPEC I5; FINDINGS F2.
- Claim: the row-number order uses the queryset's resolved ordering when available; if no ordering is available, it uses the model primary key as a deterministic fallback.
- Source evidence: `_filter_prefetch_queryset()` obtains order expressions from `queryset.query.get_compiler(using=db).get_order_by()` and V2 adds `order_by = [queryset.model._meta.pk.name]` when the resolved list is empty.
- Rationale: ordered querysets preserve public ordering. Unordered querysets have no guaranteed ordering, so a primary-key fallback does not violate a public ordering guarantee and avoids Oracle's `ROW_NUMBER()` restriction.
- Discharge: V1 failed the empty-order backend-validity subcase; V2 satisfies it.

## PO5: Unsupported window backends fail explicitly

- Intent links: SPEC I3, I8; FINDINGS F3.
- Claim: if the queryset is sliced and `connections[db].features.supports_over_clause` is false, the helper raises `NotSupportedError`.
- Source evidence: `_filter_prefetch_queryset()` checks the feature flag before building `Window(RowNumber())`.
- Discharge: satisfied.

## PO6: Prefetch cache path without `to_attr` uses the same rewrite

- Intent links: SPEC C5; FINDINGS F5.
- Claim: manager-level `_apply_rel_filters()` must avoid filtering a sliced custom queryset directly when prefetch cache querysets are constructed.
- Source evidence:
  - Reverse many-to-one `_apply_rel_filters()` branches to `_filter_prefetch_queryset()` when sliced.
  - Many-to-many `_apply_rel_filters()` branches to `_filter_prefetch_queryset(queryset._next_is_sticky(), ...)` when sliced.
  - Generic relation `_apply_rel_filters()` branches to `_filter_prefetch_queryset()` when sliced.
- Discharge: satisfied.

## PO7: Unsliced and existing non-target behavior is framed

- Intent links: SPEC I7.
- Claim: unsliced prefetch querysets follow the same filtering behavior as before, aside from passing through the helper.
- Source evidence:
  - Unsliced helper path returns `queryset.filter(predicate)`.
  - Reverse many-to-one `_apply_rel_filters()` preserves `_defer_next_filter` on the unsliced path.
  - Many-to-many `_apply_rel_filters()` preserves `_defer_next_filter` and `_next_is_sticky()` on the unsliced path.
  - `Prefetch` validation for raw/values querysets is untouched.
- Discharge: satisfied by source inspection.

## PO8: Single-valued relations are excluded by intent, not accidentally ignored

- Intent links: SPEC scope; FINDINGS F4.
- Claim: not changing forward foreign key and reverse one-to-one sliced queryset handling is acceptable only because the public issue requires bounded collections per parent.
- Source evidence: the issue example is `post_set`, and the rationale is displaying "couple of example objects from each category."
- Discharge: satisfied as a scope decision. If future intent includes single-valued sliced prefetches, this becomes a new obligation.

## PO9: Formal adequacy and compatibility

- Intent links: all SPEC ledger entries; FINDINGS F7.
- Claims:
  - The formal abstraction preserves the property under verification: sliced relation predicates are rewritten into per-partition rank bounds before filtering.
  - No changed public function signature or return tuple shape breaks public call sites.
- Source evidence:
  - `_filter_prefetch_queryset()` is new internal helper only.
  - Existing `get_prefetch_queryset()` tuple shapes are preserved.
  - Existing manager public method signatures are preserved.
- Discharge: satisfied by source inspection; proof remains constructed, not machine-checked.
