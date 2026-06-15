# FVK Proof

Status: constructed proof by source inspection and symbolic substitution; not
machine-checked. No tests, Python, or K commands were run.

## Proof Summary

V1 proves the intended contract for importable class-object serialization:
non-builtin nested classes serialize as `module.__qualname__`, while builtins,
special cases, and top-level classes keep their previous output.

## PO-001: Routing

`serializer_factory()` checks `isinstance(value, type)` before deconstructible
objects and before registry serializers. An enum class object is a class object,
so it reaches `TypeSerializer(value)`. This discharges the route needed by the
issue and explains why enum-member serialization is not the operative path.

Related finding: F-004.

## PO-002: Nested Importable Class

Let `C` be an importable nested class with:

- `C.__module__ = M`
- `C.__name__ = N`
- `C.__qualname__ = Q`, where `Q` includes the containing class path

For the issue examples, `Q` is `Outer.Inner` or `Thing.State`.

V1 reaches the non-builtin, non-special branch and returns:

```text
"%s.%s" % (M, Q), {"import %s" % M}
```

Substitution gives:

- `test1.models.Outer.Inner` for `Outer.Inner`
- `test1.models.Thing.State` for `Thing.State`

This matches SPEC I-001/I-002 and discharges PO-002.

Related finding: F-001.

## PO-003: Top-Level Preservation

For a top-level non-builtin class, Python sets `__qualname__ == __name__`.
Replacing `__name__` with `__qualname__` therefore leaves the serialized path
unchanged:

```text
module + "." + __qualname__ == module + "." + __name__
```

This discharges PO-003.

Related finding: F-002.

## PO-004 Through PO-006: Builtin And Special Cases

`models.Model` and `type(None)` are handled by explicit identity checks before
the module/name branch. Builtin classes are handled by the `module ==
builtins.__name__` branch and still return the bare `__name__` with an empty
import set.

The V1 edit is unreachable on these paths, so their previous behavior is
preserved. This discharges PO-004, PO-005, and PO-006.

Related finding: F-003.

## PO-007: Enum Class Route

The issue's enum field stores the enum class object as a field argument. That
object satisfies `isinstance(value, type)`, so PO-001 routes it to
`TypeSerializer`. PO-002 then supplies the correct nested qualified path.

This discharges PO-007.

Related finding: F-004.

## PO-008: Adjacent Serializer Frame

`Field.deconstruct()` already uses `self.__class__.__qualname__`, so nested field
subclasses are already represented with containing class names in the checked-out
base. `EnumSerializer.serialize()` already uses the enum member class
`__qualname__`, so enum members keep their existing correct behavior.

No adjacent serializer edit is needed to satisfy the public issue. This
discharges PO-008.

Related findings: F-004, F-005.

## Residual Risk And Honesty Gate

This is a partial-correctness proof over the stated serializer domain. It does
not prove a general policy for non-importable function-local classes whose
`__qualname__` contains `<locals>`; F-006 records that as outside the public
issue domain.

The proof is constructed, not machine-checked. The proof obligations list the
K-command shape that a future full K encoding should run before treating any
test-removal recommendation as verified.

## Test Guidance

Do not delete tests based on this constructed proof. If machine-checked later,
unit tests that only assert PO-002 through PO-006 points would be candidates for
conditional redundancy. Integration tests for `makemigrations` output should be
kept because they cover writer integration beyond this unit proof.
