# Public Compatibility Audit

Status: pass.

## Changed Symbol

`Query.resolve_lookup_value(self, value, can_reuse, allow_joins)`

Signature status: unchanged.

Return protocol status: unchanged for expressions, scalars, plain lists, and
plain tuples. Standard named tuples now return a resolved named tuple instead of
raising the reported constructor `TypeError`.

## Callers

`Query.build_filter()` calls:

```python
value = self.resolve_lookup_value(value, can_reuse, allow_joins)
```

No callsite update is required because the signature is unchanged.

## Downstream Consumers

`FieldGetDbPrepValueIterableMixin.get_prep_lookup()` iterates over `self.rhs`.
A named tuple remains iterable after V1, and a two-field named tuple still
provides two values in field order.

`Range.get_rhs_op()` consumes processed RHS SQL positions, not the original
Python named tuple constructor protocol. V1 does not change this interface.

## Overrides

Static search found no override of `resolve_lookup_value()` in
`repo/django/db/models`. No virtual dispatch compatibility issue was found.
