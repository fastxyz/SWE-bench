# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Related IDs Are Selected Per Target Model

For every `model` in `self.query.related_updates`,
`SQLUpdateCompiler.pre_sql_setup()` must add one select column whose value is the
identifier of `model`'s parent-link path for each selected child row.

Evidence: ledger E2, E4, E5, E8.

Discharge: V1 iterates `self.query.related_updates`, records the row index for
each model, and appends `_get_update_related_id_lookup(model)`. The helper uses
`get_path_to_parent(model)` and the final parent-link `attname`, preserving direct
and indirect parent-link paths.

## PO2: Related Updates Use Model-Keyed IDs

For every related update target `model`, the generated related update query must
filter with `pk__in = related_ids[model]`.

Evidence: ledger E3, E6.

Discharge: `UpdateQuery.get_related_updates()` now calls
`query.add_filter("pk__in", self.related_ids[model])`.

## PO3: Primary Update Filtering Is Preserved

The main update query must still filter by the queryset model primary keys
selected from the original query.

Evidence: intent obligation 3; existing update compiler behavior.

Discharge: V1 keeps the first selected field as `query.get_meta().pk.name`,
collects it into `idents`, and applies `self.query.add_filter("pk__in", idents)`.

## PO4: Stable Snapshot Across Progressive Updates

Identifier lists for all related update targets must be captured before any
update query executes.

Evidence: intent obligation 4 and existing comment in `pre_sql_setup()`.

Discharge: V1 collects `idents` and every `related_ids[model]` from the preselect
query before `execute_sql()` iterates over `get_related_updates()`.

## PO5: Empty Selection Updates No Ancestor Rows

If the preselect returns no rows, every identifier list is empty and related
updates must filter with empty lists.

Evidence: default update semantics and intent obligation 1.

Discharge: V1 initializes `idents = []` and `related_ids = {model: [] ...}` before
reading rows, so empty preselects produce empty filters.

## PO6: Private-State Compatibility

Changing `related_ids` from list to dict must not break public API or unrelated
update paths.

Evidence: compatibility audit.

Discharge: `related_ids` has no public consumers outside `UpdateQuery` and
`SQLUpdateCompiler`. `get_related_updates()` returns early when there are no
related updates.

## PO7: Proof Boundary

The proof must keep visible the property that distinguishes the bug: child/base
primary keys may differ from the target ancestor's parent-link identifiers.

Evidence: ledger E2 and K bug discriminator claim.

Discharge: The mini semantics models `PKIDS` and `RELATED_IDS[M]` as distinct
observables and includes a discriminator claim where `OtherBase` uses `[3, 4]`
instead of child/base `[1, 2]`.
