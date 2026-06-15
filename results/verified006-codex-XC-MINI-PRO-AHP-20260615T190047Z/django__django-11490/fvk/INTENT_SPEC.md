# Intent Specification

Status: intent-only. This file uses public issue text, allowed source code, and
named default queryset immutability expectations. It does not treat current
candidate behavior as expected behavior by itself.

## Required behavior

1. A combined queryset produced by `union()`, `intersection()`, or
   `difference()` can have `values()` or `values_list()` applied after the
   combinator is built.
2. Each evaluation's outer values field list determines that evaluation's
   selected output columns.
3. Reusing the same combined queryset with a different outer values field list
   must not reuse a field list applied during an earlier evaluation.
4. Compiler-time adjustments needed to make set-operation child queries use a
   compatible column list must not mutate the original child `Query` objects
   stored in `combined_queries`.
5. Existing behavior for child queries that already have their own explicit
   values selection is preserved unless public intent says otherwise.
6. The fix must not change public queryset APIs, method signatures, combinator
   semantics, or test files.

## Boundary and assumptions

The intent concerns selected-column state for composed queries. It does not
claim to prove full SQL text equivalence, database backend behavior, result
iterator formatting, termination, or performance.

The issue's pre-fix printed second result is a SUSPECT legacy display because
the issue reports it as the bug.
