# FVK Findings

Status: constructed from source inspection; not machine-checked.

## F-001: V1 fixes the reported nested enum class path

Input class shape: `Thing.State`, where `Thing.State.__module__ ==
"test1.models"` and `Thing.State.__qualname__ == "Thing.State"`.

Pre-V1 observed behavior from the issue and source route:
`TypeSerializer` used `__name__`, producing `test1.models.State`.

Expected behavior from SPEC I-002/I-003:
`test1.models.Thing.State`.

V1 behavior by inspection:
`TypeSerializer` now formats `module + "." + __qualname__`, producing
`test1.models.Thing.State`.

Classification: resolved code bug. No further code change required.

## F-002: V1 preserves top-level class serialization

Input class shape: top-level class `State`, where `__name__ == __qualname__ ==
"State"`.

Expected behavior from SPEC I-004:
the path remains `module.State`.

V1 behavior by inspection:
substituting `__qualname__` for `__name__` produces the same string.

Classification: compatibility confirmed.

## F-003: V1 preserves builtin and special-case serialization

Input class shapes: builtin classes such as `range`; special cases
`models.Model` and `type(None)`.

Expected behavior from SPEC I-004:
builtins remain bare names with no import; special cases remain their existing
spelled forms.

V1 behavior by inspection:
the builtin and special-case branches return before the non-builtin
`__qualname__` formatting branch.

Classification: compatibility confirmed.

## F-004: Changing `EnumSerializer` is not the operative fix

Input value shape: enum class object, not enum member.

Observed route by source inspection:
`serializer_factory()` checks `isinstance(value, type)` before registry
serializers, so enum class objects reach `TypeSerializer`. `EnumSerializer`
handles enum members and already uses `__qualname__`.

Expected behavior from SPEC I-003:
the class-object path must be fixed in `TypeSerializer`.

Classification: alternative rejected. No `EnumSerializer` edit required.

## F-005: Field subclass path is already covered outside V1

Input value shape: nested subclass of `models.Field`, such as `Outer.Inner`.

Observed route by source inspection:
`Field.deconstruct()` already builds its path from
`self.__class__.__qualname__`.

Expected behavior from SPEC I-001:
the migration field class path includes `Outer.Inner`.

Classification: already satisfied in the base checkout. No additional field
deconstruction edit required.

## F-006: Function-local classes remain outside the proven domain

Input class shape: class defined inside a function, where `__qualname__`
contains `<locals>`.

Observed behavior by source inspection:
V1 would format the raw qualified name on the non-builtin branch.

Expected behavior:
the public issue and examples concern importable nested classes on modules and
models. Function-local classes do not have an importable migration path of the
form required by the issue.

Classification: residual out-of-domain risk, not a blocker for confirming V1.
If a future requirement expands migration serialization to reject all
non-importable class objects explicitly, add a `ValueError` guard analogous to
`FunctionTypeSerializer`.
