# Public Compatibility Audit

Changed symbol: `AutoFieldMeta.__subclasscheck__(self, subclass)`.

- Signature: unchanged.
- Return shape: unchanged boolean result.
- Intended behavior change: custom subclasses of `BigAutoField` and
  `SmallAutoField` now return true for `issubclass(C, AutoField)`.
- Existing concrete `BigAutoField` and `SmallAutoField` compatibility:
  preserved by reflexive subclassing.
- Direct `AutoField` subclass compatibility: preserved by the unchanged
  `super().__subclasscheck__(subclass)` fallback.
- `AutoFieldMeta.__instancecheck__`: unchanged and already subclass-aware via
  `isinstance(instance, self._subclasses)`.
- Source callsite using `issubclass(..., AutoField)`:
  `Options._get_default_pk_class()`, now receives the corrected truth value.
- Source callsites using `isinstance(..., AutoField)`: inspected and unaffected
  because `__instancecheck__` was not edited.

Result: pass. No public compatibility blocker was found.
