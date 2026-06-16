# Public Compatibility Audit

Status: constructed, not machine-checked.

Changed symbol: `django.db.migrations.serializer.FunctionTypeSerializer.serialize`

Compatibility result:

- Signature: unchanged.
- Return shape for successful serialization: unchanged two-tuple
  `(serialized_string, imports_set)`.
- Import-set shape: unchanged, still `{"import <module>"}` for successful
  callable paths.
- Existing top-level class method paths: preserved because `klass.__qualname__`
  equals `klass.__name__` for non-nested top-level classes.
- Existing nested importable class method paths: changed intentionally from the
  buggy innermost class name to the full qualified class name.
- Existing lambda rejection: preserved and made uniform for class-bound lambda
  callables.
- Existing local-function rejection: preserved; V2 adds the equivalent rejection
  for local class-bound methods.
- Test files: not modified.

No public callsite or subclass override requires a signature or return-shape
update.
