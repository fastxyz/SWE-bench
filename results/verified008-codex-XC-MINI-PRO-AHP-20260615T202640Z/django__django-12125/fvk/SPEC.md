# FVK Spec: django__django-12125

Status: constructed from public intent and source inspection; not machine-checked.
No tests, Python, or K tooling were run.

## Scope

The audited observable is the migration serialization string and import set
produced for Python class objects used as serialized field arguments. The source
unit is `django.db.migrations.serializer.TypeSerializer.serialize()`, with
`serializer_factory()` included only for routing evidence.

The domain is importable class objects whose migration representation is meant to
be an attribute path from the module import. This covers top-level classes and
classes nested in other importable classes, including enum/model-choice classes
nested on a model. Function-local classes whose `__qualname__` contains
`<locals>` are not part of the public issue examples and are not used to justify
acceptance of V1.

## Intent Spec

I-001: Nested field classes must keep their containing class path.
Source: `benchmark/PROBLEM.md`.
Evidence: "test1.models.Inner ... should have been test1.models.Outer.Inner."
Obligation: a nested class path in generated migrations includes all containing
class names.
Status: encoded.

I-002: Nested enum classes passed as field arguments must keep their model
containing class path.
Source: `benchmark/PROBLEM.md`.
Evidence: "This refers to test1.models.State, instead of to
test1.models.Thing.State."
Obligation: enum class objects serialized as field argument values use
`module.Thing.State`, not `module.State`.
Status: encoded.

I-003: The specific failing route is class-object serialization through
`TypeSerializer`.
Source: `benchmark/PROBLEM.md`.
Evidence: "serializer_factory is returning TypeSerializer for the Enum subclass,
which is still using __name__ ... serializing them properly with __qualname__
seems prudent."
Obligation: `TypeSerializer` must use the class qualified name for non-builtin
class paths.
Status: encoded.

I-004: Existing working paths should not be disturbed.
Source: public compatibility from existing source behavior and issue scope.
Evidence: `TypeSerializer` has special cases for `models.Model`, `type(None)`,
and builtins; top-level classes have `__qualname__ == __name__`.
Obligation: special-case, builtin, and top-level serialization remain unchanged.
Status: encoded.

I-005: Adjacent class-path contributors already satisfy the nested-class path
obligation.
Source: source inspection.
Evidence: `Field.deconstruct()` and `EnumSerializer.serialize()` already use
`__qualname__`.
Obligation: do not replace those routes unless they conflict with I-001/I-002.
Status: encoded.

## Formal Spec English

FS-001: For any non-builtin, non-special importable class `C`, serialization
returns `C.__module__ + "." + C.__qualname__` and imports `C.__module__`.

FS-002: For a nested importable class with module `M`, name `Inner`, and
qualified name `Outer.Inner`, serialization returns `M.Outer.Inner` with
`import M`.

FS-003: For a top-level importable class with `__qualname__ == __name__`,
serialization returns the same string V0 returned: `module.name`.

FS-004: Builtin classes serialize as their bare builtin name with no import.

FS-005: `models.Model` serializes as `models.Model`; `type(None)` serializes as
`type(None)`.

FS-006: An enum class object reaches `TypeSerializer` because it is an instance
of `type`; enum members reach `EnumSerializer` separately.

## Adequacy Audit

FS-001 passes I-003 and is the general form needed for I-001/I-002.
FS-002 passes I-001 and I-002.
FS-003 and FS-004 pass I-004.
FS-005 passes I-004.
FS-006 passes I-003 and explains why changing `EnumSerializer` alone is
inadequate.

No formal-English clause preserves the reported legacy bug
`module.Inner`/`module.State` for nested importable classes.

## Public Compatibility Audit

Changed public symbol: `TypeSerializer.serialize()` output for non-builtin
class objects whose `__qualname__ != __name__`.

Compatible cases:

- Top-level non-builtin classes: unchanged because `__qualname__ == __name__`.
- Builtin classes: unchanged because the builtin branch still returns
  `__name__` with no import.
- `models.Model` and `type(None)`: unchanged because special cases return before
  the module/name branch.

Intentional behavior change:

- Importable nested non-builtin classes: output now includes containing class
  names. This is the issue-required change.

No public callsite, subclass override, method signature, return type shape, or
import-set shape changes were introduced beyond the serialized path string.
