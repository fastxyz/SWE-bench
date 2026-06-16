# Intent Spec

Status: constructed from public issue text and source inspection; not
machine-checked.

## Required Behavior

1. `~Exists(queryset.none())` must behave as an always-true predicate.
   It must not make a surrounding `filter(..., name='test')` collapse to an
   empty result set.

2. `Exists(queryset.none())` must continue to behave as an always-false
   predicate. The issue only identifies the negated case as wrong, and the ORM
   already uses `EmptyResultSet` to represent impossible predicates.

3. Non-empty `Exists(queryset)` behavior must be preserved. A positive
   non-empty `Exists` compiles to an `EXISTS(...)` predicate, and a negated
   non-empty `Exists` compiles to a negated predicate.

4. The fix must live at the `Exists.as_sql()` abstraction boundary because
   `Exists.__invert__()` stores negation in `self.negated`; a surrounding
   `WhereNode` cannot infer that the expression intended to negate an
   `EmptyResultSet`.

5. The always-true result for a negated empty `Exists` must be a concrete SQL
   predicate, not an omitted SQL fragment, because `Exists` can be compiled in
   contexts other than a WHERE child.

6. No public method signature, return shape, or test file may be changed.

## Out of Scope

Termination is not relevant for this straight-line compilation branch. The
FVK proof is partial correctness and constructed only; no K tooling or tests
were executed.
