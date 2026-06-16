# Baseline Notes

## Root cause

`WhereNode.as_sql()` rewrites `XOR` conditions for backends without native
logical XOR support. The fallback counted truthy operands with `CASE` clauses,
but it compared that count to `1`. That implements "exactly one operand is
true" instead of XOR parity, where an odd number of true operands should match.
As a result, expressions such as `Q(...) ^ Q(...) ^ Q(...)` failed when all
three operands were true.

## Changed files

`repo/django/db/models/sql/where.py`

Changed the non-native XOR fallback from `truthy_count == 1` to
`truthy_count % 2 == 1`. This preserves the existing SQL construction and
backend expression handling while matching native XOR parity semantics for more
than two operands.

`reports/baseline_notes.md`

Added this report to document the root cause, the source change, and the
assumptions considered.

## Assumptions and alternatives considered

I assumed Django's existing arithmetic expression support is the right portable
way to express modulo here. `Combinable.MOD` is already handled by the database
operation layer, including Oracle's `MOD()` rendering, and MySQL normally bypasses
this fallback because it advertises native logical XOR support.

I kept the existing `(a OR b OR c OR ...)` side of the fallback even though
`truthy_count % 2 == 1` is logically sufficient. Keeping it minimizes behavioral
change around the existing short-circuit handling for empty and full child
predicates.

I considered rewriting multi-operand fallback XOR as nested binary XOR
expressions. I rejected that because the current code already has a direct count
of truthy operands; changing the comparison to parity is smaller and more clearly
matches the intended semantics.
