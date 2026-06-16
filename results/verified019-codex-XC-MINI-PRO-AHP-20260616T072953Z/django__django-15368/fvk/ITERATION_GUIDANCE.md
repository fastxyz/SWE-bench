# Iteration Guidance

Status: V1 stands unchanged.

## Decision

No additional source edit is recommended. The FVK audit confirms that the V1 predicate change is exactly the public-intent repair:

- `F()` is expression-like because it implements `resolve_expression`.
- Other expression-like values should follow the same protocol.
- Literal values without `resolve_expression` still become `Value(...)`.

## Rejected Alternatives

1. Special-case `F` with `isinstance(attr, (Expression, F))`.

   Rejected because it fixes the concrete witness but keeps `bulk_update()` narrower than Django's established expression protocol. This would under-discharge PO-2 for other expression-like values.

2. Add extra wrapping such as `ExpressionWrapper` around `F()`.

   Rejected because `When` and `Case` already parse and resolve expression-like results, and `UpdateQuery.add_update_fields()` already resolves update expressions. Extra wrapping is not needed to discharge PO-3.

3. Modify tests in this task.

   Rejected because the user constraints forbid modifying test files. Finding F-003 records the needed regression coverage for a later context.

## Next Validation Steps

These steps are not to be executed in this workspace:

```sh
kompile fvk/mini-django-bulk-update.k --backend haskell
kast --backend haskell fvk/bulk-update-spec.k
kprove fvk/bulk-update-spec.k
```

After machine checking the FVK claims in an environment with K available, run Django's relevant ORM test suite in a normal execution environment and add/keep a regression test for `bulk_update()` with plain `F()` values.
