# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Claims Proved by Construction

The proof target is `ExpressionWrapper.get_group_by_cols(alias=None)` in
`repo/django/db/models/expressions.py`.

### PO-001 and PO-003: wrapped `Value`

1. The V2 method inspects the child method signature.
2. `Value.get_group_by_cols(self, alias=None)` accepts `alias`.
3. The method follows the alias-aware branch:
   `return self.expression.get_group_by_cols(alias=alias)`.
4. For `Value`, that delegated call returns `[]`.
5. Therefore `ExpressionWrapper(Value(V)).get_group_by_cols(alias=A)` returns
   `[]` for any alias `A`, and the wrapper itself is not inserted as `[self]`.

### PO-002: alias-aware delegation

1. For any child expression whose `get_group_by_cols()` signature contains
   `alias`, V2 follows the alias-aware branch.
2. That branch returns exactly
   `self.expression.get_group_by_cols(alias=alias)`.
3. Therefore the wrapper's group-by columns are extensionally equal to the
   child expression's group-by columns for the same alias.
4. Alias-sensitive children such as `Subquery` can still return alias references
   when Django passes an annotation alias.

### PO-004: legacy missing-alias compatibility

1. For any child expression whose `get_group_by_cols()` signature lacks
   `alias`, V2 follows the missing-alias branch.
2. That branch constructs the same deprecation message shape used by
   `Query.set_group_by()` and emits `RemovedInDjango40Warning`.
3. It then returns `self.expression.get_group_by_cols()` without passing the
   unsupported `alias` keyword.
4. Therefore a wrapped legacy child reaches the deprecation path instead of a
   keyword-argument `TypeError`.

### PO-005: frame conditions

The edit adds imports for `warnings` and `RemovedInDjango40Warning` and changes
only `ExpressionWrapper.get_group_by_cols()`. It does not modify tests, `Value`,
`BaseExpression`, SQL rendering, output-field behavior, or source-expression
accessors.

## Machine-Check Commands

These commands are emitted for a future environment. They were not run.

```sh
kompile fvk/mini-django-expressions.k --backend haskell
kast --backend haskell fvk/expression-wrapper-spec.k
kprove fvk/expression-wrapper-spec.k
```

Expected machine-check result after adapting paths for a real K workspace:
`#Top` for all three claims in `expression-wrapper-spec.k`.

## Test Guidance

No tests were modified. After machine checking and in a normal development
environment, add or keep tests for:

- `ExpressionWrapper(Value(42), output_field=IntegerField()).get_group_by_cols(alias=None) == []`.
- A wrapped alias-aware expression receives and uses the supplied alias.
- A wrapped legacy `get_group_by_cols(self)` override emits
  `RemovedInDjango40Warning` and returns the no-arg child result.

No existing tests should be removed based on this constructed proof alone.
