# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed public symbols

- `django.db.models.constraints.BaseConstraint.__init__`
- `django.db.models.constraints.CheckConstraint.__init__`
- `django.db.models.constraints.UniqueConstraint.__init__`
- `django.contrib.postgres.constraints.ExclusionConstraint.__init__`

## Compatibility checks

PC-1. The new parameter is optional and defaults to `None`, so existing public
callers that omit it remain source-compatible.

PC-2. Existing no-code validation behavior remains source-compatible because
`ValidationError(..., code=None)` is equivalent to the prior no-code construction
for the modeled observable.

PC-3. In-repo subclass/override scan found no built-in subclass that rejects the
new keyword. The custom test subclass `ValidateNoCodeErrorConstraint` overrides
`validate()` with `**kwargs`, so it is not broken by validation call shape.

PC-4. `BaseConstraint.clone()` reconstructs from `deconstruct()`. Because the
concrete built-in constructors now accept `violation_error_code`, serialized
custom codes can be cloned without breaking these classes.

PC-5. Deprecated positional arguments remain deprecated. V1 preserves the
warning path while mapping the new argument consistently if supplied positionally;
this is a compatibility choice for the temporary deprecation bridge, not a new
recommended calling convention.

## Residual non-code note

The public documentation snippets in `repo/docs/ref/.../constraints.txt` still
show the older signatures. That is a documentation-sync follow-up, not a source
correctness blocker for the benchmark repair, and no docs were edited in this
phase.

