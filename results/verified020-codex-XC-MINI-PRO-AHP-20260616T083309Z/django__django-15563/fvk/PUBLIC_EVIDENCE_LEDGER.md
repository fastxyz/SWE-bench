# Public Evidence Ledger

Status: constructed for FVK audit, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "Queryset update has a wrong behavior when queryset class inherits multiple classes." | Audit `QuerySet.update()` on multi-table inheritance with more than one concrete parent. | Encoded in `SPEC.md`, `update-related-ids-spec.k`, PO1-PO3. |
| E2 | `benchmark/PROBLEM.md` | "updating Child fields from second parent has no effect. Worse is that OtherBase fields where modifed because query is using primiary keys from Base class." | Related update for the second parent must filter by the second parent link identifiers, not by the child/base primary keys. | Encoded in PO1, PO2, BUG-DISCRIMINATOR claim. |
| E3 | public hint in `benchmark/PROBLEM.md` | "UpdateQuery.related_ids: list[int] to related_ids: dict[Model, list[int]]" | `related_ids` must be keyed by target ancestor model. | Encoded in source and PO2. |
| E4 | public hint in `benchmark/PROBLEM.md` | "pre_sql_setup populates query.related_ids by the parent_link of the related_updates" | Compiler must preselect parent-link values for every related update target. | Encoded in source and PO1. |
| E5 | public hint in `benchmark/PROBLEM.md` | "not only selecting the primary key of the parent model but all parent link values of child model fields being updated" | Preselect field list must include child primary key and all relevant parent-link identifiers. | Encoded in source and PO1/PO3. |
| E6 | public hint in `benchmark/PROBLEM.md` | "get_related_updates can be updated to do query.add_filter(\"pk__in\", self.related_ids[model])" | Each related `UpdateQuery(model)` must use `related_ids[model]`. | Encoded in source and PO2. |
| E7 | `repo/django/db/models/sql/query.py` | `add_fields()` resolves field lookups through `setup_joins()` and `trim_joins()`. | A parent-link path lookup is the local API for selecting the identifier column. | Implementation evidence used for the proof model; not standalone intent. |
| E8 | `repo/django/db/models/options.py` | `get_path_to_parent()` returns `PathInfo` objects for the path from a child model to a parent. | Indirect ancestors must be handled through the inherited path, not only direct `get_ancestor_link()`. | Encoded in source helper and PO1. |
