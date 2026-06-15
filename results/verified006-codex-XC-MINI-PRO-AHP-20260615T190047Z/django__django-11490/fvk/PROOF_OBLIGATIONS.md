# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Per-compilation column alignment

For a combined query with outer selected fields `F`, every non-empty child
query with empty `values_select` must be compiled with selected columns `F`.

Trace: intent ledger I-001 and I-005; Finding F-002.

V1 status: discharged. V1 still calls `set_values(F)` on the child compiler
query when the child clone has empty `values_select` and the outer query has a
non-empty selection.

## PO-2: No mutation of original combined child queries

Compiling a combined query must not mutate the original child `Query` objects
stored in `combined_queries`, including their `values_select` and selected
column state.

Trace: intent ledger I-001, I-003, I-004; Finding F-001.

V1 status: discharged. Child compilers are constructed from `query.clone()`, so
the subsequent `set_values()` call mutates only the cloned query owned by that
compiler.

## PO-3: Repeated outer values selections are independent

Given one reusable combined queryset whose children originally have no
`values_select`, compiling with outer selected fields `F1` and later compiling
with outer selected fields `F2` must compile the second query with `F2`, not
`F1`.

Trace: intent ledger I-001 and I-002; Finding F-001.

V1 status: discharged. Since PO-2 keeps the original child query unchanged
after the first compile, the second compile clones an unchanged child with empty
`values_select`, passes the same branch condition, and applies `set_values(F2)`
to the second clone.

## PO-4: Preserve explicitly selected child behavior and public API shape

If a child query already has an explicit `values_select`, V1 must not override
it merely because the combined outer query also has a selected field list. V1
must also preserve method signatures, combinator selection, empty-query
filtering, and backend feature checks.

Trace: intent ledger I-005; Finding F-003.

V1 status: discharged. The branch condition still checks
`not compiler.query.values_select`, now on a clone with the same initial
`values_select` value as the original. Public APIs and signatures are untouched.

## PO-5: Nested combined queries receive the same isolation recursively

When a child query is itself a combined query, its own `get_combinator_sql()`
must also compile its children through clones so compiler-time selection
adjustments do not leak from nested set operations.

Trace: intent ledger I-004 and I-006.

V1 status: discharged by structural recursion on `get_combinator_sql()`: every
entry to the method constructs child compilers from `query.clone()`, including
nested invocations from a cloned combined child.

## PO-6: Proof honesty and test policy

Because no execution environment is available and K tooling is forbidden in
this task, all proof results must be labeled constructed, not machine-checked.
No test deletion is justified by the proof.

Trace: Finding F-004.

V1 status: discharged in the artifacts by including exact commands and the
honesty caveat.
