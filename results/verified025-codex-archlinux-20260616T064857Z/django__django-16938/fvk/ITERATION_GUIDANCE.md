# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Code decision

V1 stands unchanged. The audit did not surface a public-intent or proof-obligation
failure requiring another source edit.

The decisive obligations are:

- PO-1: remove the reported FieldError.
- PO-2: preserve primary-key-only m2m output.
- PO-3: use the actual clearing API, `select_related(None)`.
- PO-4: cover both Python-derived serializers and XML.

The current source satisfies all four.

## Why no further source change

- Replacing `only("pk")` with a full related-object fetch would satisfy PO-1 but
  violate PO-2 by dropping the existing optimization.
- Using no-argument `select_related()` would not satisfy PO-3 because this
  codebase treats that as enabling unrestricted traversal, not clearing.
- Clearing `select_related` in the natural-key branch would exceed the intent and
  could remove useful manager behavior for `natural_key()` computation, violating
  PO-5.
- Limiting the fix to JSON/Python would leave XML's duplicated path uncovered,
  violating PO-4; V1 already fixed XML.

## Future tests to add

Do not edit tests in this benchmark. For maintainers, add conventional tests for:

- Python/JSON serialization of non-natural m2m primary keys when the related
  default manager uses `select_related("master")`.
- XML serialization of the same model shape.
- Natural-key m2m serialization with a manager using `select_related`, to guard
  the intentional frame condition.

## Machine-check follow-up

Run these commands in a real K environment:

```sh
kompile fvk/mini-serializer-queryset.k --backend haskell
kast --backend haskell fvk/serializer-m2m-spec.k
kprove fvk/serializer-m2m-spec.k --definition fvk/mini-serializer-queryset-kompiled
```

Keep all tests until the claims machine-check.
