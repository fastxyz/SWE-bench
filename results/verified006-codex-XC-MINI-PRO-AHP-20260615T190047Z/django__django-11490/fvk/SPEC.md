# FVK Spec for django__django-11490

Status: constructed, not machine-checked. No tests, Python, or K tooling were
executed.

## Scope

The audited unit is the combined-query compilation path in
`repo/django/db/models/sql/compiler.py`, specifically
`SQLCompiler.get_combinator_sql()`, as exercised by applying
`values()` or `values_list()` to a queryset returned by `union()`,
`intersection()`, or `difference()`.

The formal model abstracts a `Query` to the state needed for this issue:

- `values_select`: the values/values_list field names already selected on a
  child query, or empty when the child query has no explicit values selection.
- `select`: the actual selected SQL columns implied by `values_select`.
- `clone(query)`: a separate query object with the same abstract state.
- `set_values(fields)`: updates both `values_select` and `select` on the query
  object receiving the call.

This abstraction intentionally omits SQL text, joins, database backends, result
iteration classes, and expression resolution because the reported bug is a
state-leak bug in selected-column lists, not a SQL grammar or expression
evaluation bug.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| -- | -- | -- | -- | -- |
| I-001 | `benchmark/PROBLEM.md` | "Composed queries cannot change the list of columns when values()/values_list() is evaluated multiple times" | Applying different `values()` / `values_list()` selections to the same combined queryset across evaluations must independently determine the output column list. | Encoded by PO-1, PO-2, PO-3. |
| I-002 | `benchmark/PROBLEM.md` | `qs1.union(qs1).values_list('name', 'order').get()` followed by `qs1.union(qs1).values_list('order').get()` returns the old `('a', 2)` tuple | The second evaluation must not inherit the first evaluation's selected columns. The expected selected column list for the second evaluation is only `order`. | Encoded by PO-3 and Finding F-001. |
| I-003 | `repo/django/db/models/query.py` | `_values()` clones the queryset and calls `clone.query.set_values(fields)` | Queryset operations are expected to apply field-list changes to the clone being built, not mutate unrelated reusable query objects. | Encoded by PO-2. |
| I-004 | `repo/django/db/models/query.py` | `_combinator_query()` stores child `Query` objects in `combined_queries` | The compiler must treat child queries as reusable inputs and avoid leaking temporary compilation adjustments back into those inputs. | Encoded by PO-2 and PO-5. |
| I-005 | `repo/django/db/models/sql/compiler.py` | The compiler comment says all combined queries must share the limited column list and "Set the selects defined on the query on all combined queries, if not already set." | During a single compilation, a child query without its own selected values must receive the outer selected columns so all branches of the set operation produce compatible columns. | Encoded by PO-1. |
| I-006 | Current V1 diff | Child compilers are now built from `query.clone()` | Compiler-time `set_values()` mutations should happen on disposable child compiler queries. | Confirmed by PO-2, PO-3, and PO-5. |

SUSPECT legacy behavior: the issue's second printed result `('a', 2)` is the
reported bug, not an intended output. It is recorded only as observed pre-fix
behavior.

## Intent Specification

For every combined query `Q` with child queries `C1...Cn` and an outer
field-list selection `F`:

1. If a child query has no explicit `values_select`, compiling `Q.values(F)` or
   `Q.values_list(F)` must compile that child with selected columns exactly
   `F`.
2. The application of `F` to the child must be local to that compilation. The
   original child query object stored in `combined_queries` must remain
   unchanged after compilation.
3. If the same combined queryset is evaluated again with a different outer
   selection `G`, any child that originally had no explicit `values_select`
   must compile with `G`, not with a stale field list from an earlier
   compilation.
4. A child query that already has an explicit `values_select` remains governed
   by its own selected columns; the audited change must not override that
   existing behavior.
5. The public API, method signatures, combinator choice, empty-query omission,
   and backend feature checks are not changed by this fix.

## Formal Core

Standalone K-style artifacts are provided in:

- `fvk/mini-django-query.k`
- `fvk/combinator-values-spec.k`

Adequacy and compatibility artifacts are provided in:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

The claims are intentionally abstract and focus on the observable relevant to
this bug: repeated compilation with two different outer selected field lists
does not mutate or reuse the original child query's old selected columns.

Exact commands to machine-check later, not executed here:

```sh
kompile fvk/mini-django-query.k --backend haskell
kast --backend haskell fvk/combinator-values-spec.k
kprove fvk/combinator-values-spec.k
```

Expected result if the abstract semantics and claims are accepted by K:
`#Top` for the V1 claims.
