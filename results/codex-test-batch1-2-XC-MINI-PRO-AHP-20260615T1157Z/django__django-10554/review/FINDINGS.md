# Review Findings

1. Correctness against the reported issue: V1 addresses the aliasing point that
   lets a derived combined queryset mutate the original combined queryset's
   component queries. `QuerySet._clone()` routes derived queryset operations
   through `self.query.chain()` (`repo/django/db/models/query.py:1229`), which
   calls `Query.clone()`. With V1, `Query.clone()` now clones
   `combined_queries` recursively (`repo/django/db/models/sql/query.py:307`), so
   `qs.order_by().values_list('pk', flat=True)` receives independent component
   queries and cannot leave a one-column select list behind for the original
   ordered `union()` queryset.

2. Boundary conditions for empty and nested set operations are acceptable.
   Empty component queries are still represented as `Query` objects and remain
   clonable; `get_combinator_sql()` still filters them with `query.is_empty()`
   (`repo/django/db/models/sql/compiler.py:412-415`). Nested combinations are
   better covered by recursive cloning because child combined queries are also
   isolated. A hand-built self-referential `combined_queries` cycle would recurse,
   but that is not a supported public queryset construction path.

3. Error handling behavior is unchanged. V1 does not catch, convert, or suppress
   `DatabaseError`/`NotSupportedError` paths in combined query SQL generation.
   Unsupported slicing or ordering in component queries still raises in
   `get_combinator_sql()` (`repo/django/db/models/sql/compiler.py:416-421`), and
   ordering by a non-selected column on a combined query still raises through
   `get_order_by()` rather than being papered over.

4. Surrounding-code interaction is low risk. The compiler already clones a
   component query before applying `set_values()` for a limited select list
   (`repo/django/db/models/sql/compiler.py:428-434`). V1 does not replace that
   local safety check; it restores the broader `Query.clone()` invariant that a
   cloned queryset can be mutated independently. This makes the compiler path
   safer without changing the SQL-generation rules.

5. I considered cloning operands directly in `QuerySet._combinator_query()`
   (`repo/django/db/models/query.py:928-937`) because that method stores operand
   queries by reference. That broader change is not necessary for the reported
   derived-queryset failure: the failing path is a later queryset derivation,
   and every such derivation passes through `Query.clone()` after V1. Changing
   construction-time operand sharing would alter more behavior than needed for
   this issue.

6. Consistency with conventions and API contracts is good. `Query.clone()` already
   shallow-copies the object dictionary and then explicitly copies mutable or
   query-owned state (`alias_map`, `where`, masks, caches). Treating
   `combined_queries` as query-owned mutable state is consistent with that
   pattern. The public queryset API remains immutable from the caller's
   perspective.

7. Regression and performance risk is bounded. Cloning a combined queryset now
   costs one additional recursive clone per component query. Set operations
   generally contain a small number of component queries, and the cost is paid
   only when a combined query is cloned. This is preferable to state leakage
   between querysets and does not affect non-combined queryset clones because
   their `combined_queries` tuple is empty.

8. Verification limit: no tests or project code were run because the task
   explicitly forbids execution. The conclusion that V1 fixes the issue is based
   on static control-flow review of queryset cloning, combined-query SQL
   generation, and select-list propagation.
