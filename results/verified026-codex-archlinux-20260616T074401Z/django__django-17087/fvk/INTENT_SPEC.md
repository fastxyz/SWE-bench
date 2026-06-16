# Intent Specification

Status: constructed from public evidence; not machine-checked.

## Required Behaviors

I-1. A callable default that is a class method on an importable nested class must
serialize to a dotted path containing the full class qualified name. For the issue
example, the expected path is `appname.models.Profile.Capability.default`, not
`appname.models.Capability.default`.

I-2. The serializer output for a callable default must be importable by the
generated migration. When no importable path exists because the callable is local
to a function scope, the serializer should reject it instead of emitting invalid
or unresolvable migration code.

I-3. Lambda callables remain unsupported and must raise
`ValueError("Cannot serialize function: lambda")` regardless of whether the
lambda is class-bound.

I-4. Existing non-class-bound callable serialization remains unchanged:
module-level functions use `module.__qualname__`, local functions are rejected,
and functions without a module are rejected.

I-5. The public API shape of `FunctionTypeSerializer.serialize()` remains
unchanged: no signature change, return-shape change, or test-file edit.
