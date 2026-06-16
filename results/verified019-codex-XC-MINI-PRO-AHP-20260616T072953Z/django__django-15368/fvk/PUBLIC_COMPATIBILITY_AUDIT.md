# Public Compatibility Audit

Changed public symbol: `QuerySet.bulk_update(self, objs, fields, batch_size=None)`.

Compatibility result: no public API break found in the V1 diff.

- Signature: unchanged.
- Return type: unchanged; still returns `rows_updated`.
- Exceptions and validation guards before update construction: unchanged.
- Public callsites: no caller update is required because the call signature and accepted arguments are unchanged.
- Subclass/override concern: the patch does not add a virtual method call, keyword argument, or override-sensitive dispatch.
- Data/query shape: the intended SQL changes only for values implementing `resolve_expression`; literal values remain parameterized.
- Import surface: removal of `Expression` is local to `query.py` and does not remove any exported symbol.

Residual compatibility note: custom field-value objects that define `resolve_expression` are now treated as expression-like in `bulk_update()`, matching the public hint and other ORM paths. This is an intentional compatibility alignment, not a regression.
