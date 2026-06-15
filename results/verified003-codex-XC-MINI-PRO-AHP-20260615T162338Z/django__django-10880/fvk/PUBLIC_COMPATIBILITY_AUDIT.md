# Public Compatibility Audit

Status: constructed, not machine-checked.

Changed public symbol: none.

Changed source symbol: `Aggregate.as_sql()` implementation detail in `repo/django/db/models/aggregates.py`.

Signature compatibility: pass. The method signature remains `as_sql(self, compiler, connection, **extra_context)`.

Return shape compatibility: pass. The method still returns `(sql, params)`.

Constructor compatibility: pass. No aggregate constructor signature changed.

Subclass and override compatibility: pass. `GeoAggregate.as_sql()` and `OrderableAggMixin.as_sql()` call `super().as_sql()` and continue to receive the same signature and return shape. The only changed value is the internal SQL token inserted for `%(distinct)s`.

Template compatibility: pass. Shared aggregate templates use `%(distinct)s%(expressions)s`, so a trailing separator in the distinct marker is compatible with the intended template contract. When `distinct=False`, the marker remains empty, preserving non-distinct SQL shape.

Unhandled compatibility issue: none found from static source inspection.
