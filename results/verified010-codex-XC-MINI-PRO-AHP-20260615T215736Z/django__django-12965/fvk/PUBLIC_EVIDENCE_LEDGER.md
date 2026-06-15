# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "The tests run Model.objects.all().delete(). Django 3.0 generates this SQL: DELETE FROM `testapp_alphabet`." | Unfiltered fast delete over one model must use direct `DELETE FROM base_table`. | Encoded in `django-delete-spec.k` claim `ALL-DELETE-DIRECT`. |
| E2 | prompt | "Django 3.1 generates this SQL: DELETE FROM ... WHERE ... IN (SELECT ... FROM same table)." | Self-subquery for this single-table case is the buggy behavior, not a compatibility target. | Encoded as negative finding F1 and direct-delete postcondition. |
| E3 | prompt | "The subquery is a blocker for using LOCK TABLES along with delete()." | The corrected single-table SQL must avoid referring to the same table twice. | Encoded as direct shape for active single-alias states. |
| E4 | prompt | "Additionally this change is a performance regression." | Avoiding the fallback for single-table deletes is performance-relevant, not just cosmetic. | Encoded as branch-selection postcondition. |
| E5 | public hint | "It should be possible to prevent the query when dealing with a single alias. It looks like this is a regression on other backends as well." | The rule should be backend-neutral: direct when there is one table alias, fallback otherwise. | Encoded in `SQLDeleteCompiler.single_alias`, not in a backend subclass. |
| E6 | code | `SQLCompiler.setup_query()` calls `get_initial_alias()` when all alias refcounts are zero. | Delete compiler must count the base table before deciding whether an uninitialized query is single-table. | Encoded in proof obligation PO2 and V2 source edit. |
| E7 | code | `get_from_clause()` appends `query.extra_tables`; `_as_sql()` does not emit a `FROM` clause beyond the delete target. | `extra_tables` must keep the query off the direct branch. | Encoded in proof obligation PO5 and V2 source edit. |
