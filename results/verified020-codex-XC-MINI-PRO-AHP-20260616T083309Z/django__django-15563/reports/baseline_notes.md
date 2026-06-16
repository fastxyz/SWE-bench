## Root cause

`SQLUpdateCompiler.pre_sql_setup()` preselected only the queryset model's primary
key and stored those values on `UpdateQuery.related_ids` as a single list. That
worked for single-parent multi-table inheritance because the child primary key is
also the parent link value. With multiple concrete parents, a field from a second
parent is stored in that second parent's table and must be filtered by the second
parent link value, not by the child primary key. Reusing the child primary keys
therefore updated unrelated rows in the second parent table.

## Changed files

`repo/django/db/models/sql/compiler.py`

`SQLUpdateCompiler` now selects the queryset primary key plus one inherited
parent-link identifier for each related ancestor model being updated. During the
preselect step it builds `related_ids` as a dictionary keyed by ancestor model, so
each related update can filter with identifiers from its own parent link. The
lookup helper uses `Options.get_path_to_parent()` so direct and indirect
multi-table inheritance paths are handled through existing Django model metadata.

`repo/django/db/models/sql/subqueries.py`

`UpdateQuery.related_ids` is now treated as model-keyed state. `clone()` preserves
it when present, and `get_related_updates()` uses `self.related_ids[model]` when
adding the `pk__in` filter for each ancestor update.

## Assumptions and alternatives

I assumed the correct behavior is to preserve the existing preselect strategy for
updates involving parent tables, but make the selected identifiers specific to
the table each related update targets.

I considered selecting each ancestor model's primary key name directly. I rejected
that because inherited field names can be ambiguous across parent models, while
the parent-link path identifies the exact inheritance route from the queryset
model to the ancestor table.

I also considered keeping a single ID list and special-casing second parents in
`get_related_updates()`. I rejected that because the compiler is the place that
knows which columns were selected and can reliably keep row positions aligned
with the related update models.
