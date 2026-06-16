# Baseline Notes

## Root cause

`Exists` is a conditional expression because it resolves to a `BooleanField`.
`Combinable.__and__()` and `Combinable.__or__()` already allow two conditional
expressions to be combined by wrapping them in `Q` objects, which is why
`Exists(...) & Q(...)` works.

The reverse order failed because `Q._combine()` only accepted operands that were
already instances of `Q`. When the left-hand operand was `Q(...)` and the
right-hand operand was `Exists(...)`, `Q._combine()` raised `TypeError` before
the conditional expression could be wrapped.

There was a second related edge case for empty `Q` objects. `Q() & Exists(...)`
should return an equivalent `Q(Exists(...))`, but the empty-`Q` shortcut clones
the other side via `deconstruct()`. `Q.deconstruct()` assumed a single non-`Q`
child was always a lookup tuple, which is not true for a wrapped conditional
expression such as `Exists`.

## Files changed

`repo/django/db/models/query_utils.py`

`Q._combine()` now accepts any operand with `conditional` set, preserving the
existing `TypeError` behavior for non-conditional objects. Non-`Q` conditional
operands are wrapped as `Q(other)` so `Q(...) & Exists(...)` and
`Q(...) | Exists(...)` use the same query tree representation as the already
working `Exists(...) & Q(...)` direction.

`Q.deconstruct()` now treats a single tuple child as the lookup shorthand and a
single non-tuple child as a positional argument. This preserves existing
deconstruction for ordinary lookup `Q` objects while allowing `Q(Exists(...))`
to be cloned by the existing empty-node logic.

## Assumptions and alternatives considered

I assumed the intended contract is the one already used elsewhere in the ORM:
objects with truthy `conditional` are valid boolean query conditions. That
matches `Combinable.__and__()`, `Combinable.__or__()`, `When()`, and
`Query.build_filter()`.

I considered adding reflected `__rand__` and `__ror__` implementations to
`Combinable` or `Exists`, but that would not fix this failure because
`Q.__and__()` raises `TypeError` directly instead of returning `NotImplemented`.
The reflected method is therefore not reached for `Q(...) & Exists(...)`.

I also considered special-casing `Exists`, but rejected it because the same
left-hand `Q` issue applies to any boolean expression, not only subquery
existence checks.

No tests or project code were run, per the benchmark instructions.
