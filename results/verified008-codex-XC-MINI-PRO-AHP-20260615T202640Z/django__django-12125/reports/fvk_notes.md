# FVK Notes

## Source decision

V1 stands unchanged. The only production source change remains the replacement
of `self.value.__name__` with `self.value.__qualname__` in
`repo/django/db/migrations/serializer.py`.

This is justified by `fvk/FINDINGS.md` F-001 and
`fvk/PROOF_OBLIGATIONS.md` PO-002/PO-007: enum class objects are routed to
`TypeSerializer`, and the required output for an importable nested class is
`module + "." + __qualname__`.

## Decisions not to edit other code

I did not change `EnumSerializer`. F-004 and PO-007 show that the issue's failing
value is an enum class object, not an enum member, and `serializer_factory()`
routes class objects to `TypeSerializer`.

I did not change `Field.deconstruct()`. F-005 and PO-008 show that the checked
source already uses `self.__class__.__qualname__` for field class paths.

I did not add compatibility handling for top-level classes, builtins,
`models.Model`, or `type(None)`. F-002/F-003 and PO-003 through PO-006 show that
V1 preserves those outputs through either unchanged branches or the identity
`__qualname__ == __name__` for top-level classes.

I did not add a new `<locals>` guard to `TypeSerializer`. F-006 records
function-local classes as a residual out-of-domain risk: the public issue and
examples require importable nested class paths such as `Thing.State`, not a new
policy for non-importable local classes.

## Verification status

The FVK proof is constructed, not machine-checked. I did not run tests, Python,
`kompile`, `kast`, or `kprove`, per the benchmark instructions.
