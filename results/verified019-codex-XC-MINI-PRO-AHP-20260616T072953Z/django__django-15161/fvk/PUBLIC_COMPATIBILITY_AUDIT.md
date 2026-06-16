# PUBLIC COMPATIBILITY AUDIT

Status: constructed, not machine-checked.

Changed public symbols:

- `Expression.deconstruct()` exact path, through changing the decorator to
  `@deconstructible(path='django.db.models.Expression')`.
- Newly exact-shortened paths for `OuterRef`, `Func`, `Value`,
  `ExpressionList`, `ExpressionWrapper`, `When`, `Case`, `OrderBy`, `Window`,
  `WindowFrame`, `RowRange`, and `ValueRange`.

Compatibility checks by inspection:

- No constructor signatures changed.
- No method bodies for SQL compilation, expression resolution, copying, or
  equality changed.
- No imports were removed or renamed.
- `django.db.models` exports every target class name used in a decorator path.
- The serializer already has behavior for `django.db.models` paths.
- Subclass fallback is preserved by the exact-type guard in
  `deconstructible.deconstruct`.

Unhandled compatibility issues: none found.

