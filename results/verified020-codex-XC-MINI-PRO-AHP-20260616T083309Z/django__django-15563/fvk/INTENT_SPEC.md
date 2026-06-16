# Intent Specification

Status: constructed for FVK audit, not machine-checked.

## Intent-only obligations

1. `QuerySet.update()` on a concrete multi-table-inheritance child must update
   the rows that belong to the queryset's child instances, even when the updated
   field is declared on a non-primary concrete parent.

2. For every ancestor table updated as a related update, the `pk__in` filter must
   use identifiers from that ancestor's parent-link path for the selected child
   rows, not the child model primary key unless that primary key is the same
   parent link.

3. The primary update query, when present, must continue to be restricted by the
   queryset model's primary keys selected from the original queryset.

4. Related updates must use a stable preselected snapshot of identifiers so that
   progressive updates to one table cannot change which rows are updated in later
   related updates.

5. Existing public API shape is preserved: `QuerySet.update()` remains the public
   entry point, and the coordination between `SQLUpdateCompiler` and
   `UpdateQuery` remains private implementation state.

## Default-domain assumptions

- Django concrete multi-table inheritance uses single-column parent-link
  `OneToOneField`s. Composite primary keys are outside this Django version's
  model contract.
- `Query.add_fields()` and `Options.get_path_to_parent()` correctly resolve
  inherited field paths and parent-link paths according to Django metadata.
- The FVK proof is partial correctness over update planning: it proves the
  compiler constructs the right filters if it returns. It does not prove database
  execution, SQL backend behavior, performance, or termination.
