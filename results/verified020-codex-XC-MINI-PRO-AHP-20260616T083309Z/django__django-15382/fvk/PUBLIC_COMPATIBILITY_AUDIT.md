# Public Compatibility Audit

Status: constructed from source inspection; no code or tests executed.

## Changed Public Symbol

`django.db.models.expressions.Exists.as_sql()`

Compatibility result: Pass.

The V1 fix does not change the method signature, accepted arguments, public
class hierarchy, output tuple shape, or the `Exists.__invert__()` API. It only
changes the exceptional empty-subquery path when `self.negated` is true.

## Public Call Sites and Overrides

Search target from source inspection: `Exists.as_sql()` is a method override
used by Django's expression compiler through `compiler.compile()`.

Compatibility result: Pass.

The return shape remains `(sql, params)`. For the changed path, the SQL is a
boolean predicate and `params` is an ordered parameter sequence, which matches
the shape consumed by `WhereNode.as_sql()`, select formatting, and the SQL
compiler.

## Test Files

Compatibility result: Pass.

No test files were modified. Any future test removal would be only a
recommendation after machine-checking, not part of this change.
