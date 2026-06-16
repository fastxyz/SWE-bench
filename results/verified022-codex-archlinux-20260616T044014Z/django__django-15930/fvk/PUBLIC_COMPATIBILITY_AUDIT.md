# Public Compatibility Audit

Changed public symbol: `django.db.models.expressions.When.as_sql()`.

Compatibility result: pass.

- Signature unchanged: `as_sql(self, compiler, connection, template=None, **extra_context)`.
- Return shape unchanged: `(sql, params)`.
- Constructor/API unchanged: `When(...)` inputs are not changed.
- Dispatch shape unchanged: no new virtual-method keyword arguments or altered
  calls to subclasses/overrides were introduced.
- Existing impossible-predicate behavior is preserved because
  `EmptyResultSet` still propagates out of `When.as_sql()` to `Case.as_sql()`.
- No test files were modified.
