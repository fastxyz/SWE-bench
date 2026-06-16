# Intent Spec

Status: constructed, not machine-checked.

## Public requirements

1. `Q(...) & Exists(...)` must not raise `TypeError` merely because the
   right-hand operand is an `Exists` expression.
2. `Q(...) | Exists(...)` has the same requirement, because the issue names
   both `&` and `|`.
3. The `Q`/`Exists` pair must be symmetric with the already-working
   `Exists(...) & Q(...)` and `Exists(...) | Q(...)` direction at the logical
   filter level.
4. Non-conditional operands are outside the successful-combination domain and
   should continue to be rejected with `TypeError`.
5. Empty `Q()` remains the existing identity operand for `Q` combination:
   `Q() & condition` and `Q() | condition` produce the condition wrapped as a
   `Q`, consistent with the existing `Q() & Q(...)` and `Q() | Q(...)`
   behavior.

## Default-domain assumptions

1. A Django boolean expression is represented by an object whose `conditional`
   property is true. `Exists` satisfies this because its `output_field` is a
   `BooleanField`.
2. Query construction consumes a `Q` child that is either another `Q`, a lookup
   tuple, or an expression accepted by `Query.build_filter()`.
3. The proof is partial correctness over object construction and dispatch. It
   does not prove SQL execution, database results, or termination of arbitrary
   queryset compilation.

