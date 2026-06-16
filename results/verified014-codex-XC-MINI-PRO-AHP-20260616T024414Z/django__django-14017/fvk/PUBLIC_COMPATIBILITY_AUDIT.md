# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed symbols

`django.db.models.query_utils.Q._combine(self, other, conn)`

- Signature: unchanged.
- Public caller shape: `Q.__and__()` and `Q.__or__()` still call `_combine()`
  with the same arguments.
- Compatibility status: pass. The accepted domain is expanded for conditional
  expressions such as `Exists`; non-conditional objects still raise
  `TypeError`.

`django.db.models.query_utils.Q.deconstruct(self)`

- Signature: unchanged.
- Return shape: still `(path, args, kwargs)`.
- Compatibility status: pass. Ordinary single lookup children still return
  kwargs. Nested `Q` children still return args through the existing `else`
  path. The new positional-args branch applies only to a single non-tuple,
  non-`Q` child such as a conditional expression.

## Public callsites and consumers

- `Q.__and__()` and `Q.__or__()`: compatible; no call signature change.
- Migration serialization through `deconstruct()`: compatible for ordinary
  lookup `Q` objects; gains a representable form for `Q(Exists(...))`.
- Query filtering through `Query.build_filter()`: compatible for `Exists`
  children because `Exists` has `resolve_expression` and `conditional == True`.

No public override or subclass signature change was found in the audited source.

