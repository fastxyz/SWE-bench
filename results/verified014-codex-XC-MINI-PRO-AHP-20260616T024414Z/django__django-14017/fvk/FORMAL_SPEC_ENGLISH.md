# Formal Spec English

Status: constructed, not machine-checked.

This file paraphrases the K claims in `q-combine-spec.k`.

1. `(COMBINE-NONCOND)`: For any left-hand `Q` and either connector, combining
   with a non-conditional operand returns the error result corresponding to
   `TypeError(other)`.
2. `(COMBINE-EMPTY-SELF-COND-EXPR)`: Combining an empty left-hand `Q()` with a
   conditional expression returns a `Q` containing that expression as a
   positional child. This is the minimal issue reproduction path.
3. `(COMBINE-LOOKUP-SELF-COND-EXPR-AND)`: Combining a non-empty lookup `Q` with
   a conditional expression under `AND` returns a non-empty `Q` whose connector
   is `AND` and whose children contain both the original lookup and the
   expression.
4. `(COMBINE-LOOKUP-SELF-COND-EXPR-OR)`: Combining a non-empty lookup `Q` with
   a conditional expression under `OR` returns a non-empty `Q` whose connector
   is `OR` and whose children contain both the original lookup and the
   expression.
5. `(DECONSTRUCT-EXPR-Q)`: Deconstructing a `Q` with one conditional expression
   child produces positional args, not lookup kwargs, so cloning
   `Q(Exists(...))` does not index the expression as if it were a lookup tuple.
6. `(DECONSTRUCT-LOOKUP-Q)`: Deconstructing a `Q` with one lookup tuple child
   still produces lookup kwargs, preserving the previous migration-friendly
   form for ordinary lookup `Q` objects.

