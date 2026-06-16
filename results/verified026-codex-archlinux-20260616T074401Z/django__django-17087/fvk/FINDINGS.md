# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public issue
intent, source inspection, and the constructed proof obligations.

## F-001: Nested class methods lost the outer class qualifier

Classification: code bug, resolved by V1 and preserved in V2.

Input: a field default set to `Profile.Capability.default`, where `Capability`
is nested under the importable model class `Profile`.

Pre-V1 observed behavior: migration serialization produced
`appname.models.Capability.default`.

Expected behavior: migration serialization must produce
`appname.models.Profile.Capability.default`.

Cause: `FunctionTypeSerializer.serialize()` used `klass.__name__`, which is only
`Capability`, instead of `klass.__qualname__`, which is `Profile.Capability`.

Resolution: keep the V1 core change to serialize class-bound methods using
`klass.__qualname__`.

Trace: PO-1, PO-3.

## F-002: V1 could emit `<locals>` for local class-bound methods

Classification: code bug surfaced by FVK whole-branch audit, fixed in V2.

Input: a class method on a class whose `klass.__qualname__` contains a local
scope marker such as `<locals>`.

V1 observed behavior by code inspection: after switching to `klass.__qualname__`,
the class-bound branch would emit a dotted path containing `<locals>`, which is
not an importable migration reference.

Expected behavior: reject the callable with the same "could not find function"
style used for local non-class-bound functions.

Resolution: add a guard in the class-bound branch. Importable class-bound methods
serialize successfully; local class-bound methods raise `ValueError`.

Trace: PO-2.

## F-003: Class-bound lambda callables bypassed the existing lambda rejection

Classification: code bug surfaced by FVK whole-branch audit, fixed in V2.

Input: a class-bound callable whose `value.__name__` is `<lambda>`.

Pre-V2 observed behavior by code inspection: the class-bound branch ran before
the existing lambda check and could emit a dotted path ending in `<lambda>`.

Expected behavior: lambdas are unsupported serializer inputs and must raise
`ValueError("Cannot serialize function: lambda")`.

Resolution: move the lambda check before the class-bound branch.

Trace: PO-4.

## F-004: Non-class-bound callable behavior must remain framed

Classification: compatibility condition, confirmed by code inspection.

Input classes: module-level functions, local functions, and functions with no
module where `value.__self__` is not a class.

Observed V2 behavior by code inspection: after the early lambda check, these
inputs continue through the same no-module, importable, and local-function
branches as before.

Expected behavior: preserve existing behavior outside the class-bound method
bug and the uniform lambda rejection.

Resolution: no further source edits.

Trace: PO-5.

## Open Findings

None.
