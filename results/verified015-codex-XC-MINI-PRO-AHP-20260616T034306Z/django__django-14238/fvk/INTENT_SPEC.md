# Intent Specification

Status: intent-only. Current implementation behavior is treated as candidate
behavior to audit, not as the source of truth.

1. `DEFAULT_AUTO_FIELD` accepts a class that is a subclass of `AutoField`.
2. Django's backward compatibility treats `BigAutoField` and `SmallAutoField`
   as `AutoField` subclasses for `issubclass(C, AutoField)`.
3. The compatibility obligation applies to subclasses of `BigAutoField` and
   `SmallAutoField`, including custom and indirect subclasses.
4. Non-auto field classes remain invalid as default auto fields and raise the
   existing ValueError path.
5. Empty or import-failing default auto field paths remain
   `ImproperlyConfigured`.
6. Public API shape and existing `isinstance(..., AutoField)` compatibility are
   preserved.
