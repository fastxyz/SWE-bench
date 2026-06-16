# FVK Specification

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Target

`repo/django/db/migrations/serializer.py`,
`FunctionTypeSerializer.serialize()`.

There are no loops in the audited target. The proof is a branch proof over
callable kinds and class-bound method properties.

## Public Intent Ledger

E-1. The issue states that the generated migration incorrectly used
`appname.models.Capability.default` and that the right value is
`appname.models.Profile.Capability.default`. This requires nested class methods
to serialize with the full class qualified name.

E-2. The public hint identifies the implementation mechanism: in
`FunctionTypeSerializer`, use `__qualname__` instead of `__name__` for the bound
class.

E-3. Existing serializer behavior rejects local non-class-bound functions whose
`__qualname__` contains local-scope markers. The local-function test in
`tests.migrations.test_writer.WriterTests` confirms that such values are not
valid migration references.

E-4. Existing serializer behavior rejects lambda callables. This is a callable
serializer rule, not a property of only non-class-bound functions.

E-5. Existing nested-class serialization uses `__qualname__`, so the class-bound
method branch should align with the rest of migration serialization.

## Contract

S-1. If `value.__self__` is a class, `klass = value.__self__`, and
`klass.__qualname__` does not contain a local-scope marker, serialization returns:

`("%s.%s.%s" % (klass.__module__, klass.__qualname__, value.__name__), {"import %s" % klass.__module__})`

S-2. If `value.__self__` is a class and `klass.__qualname__` contains a
local-scope marker, serialization raises:

`ValueError("Could not find function %s in %s.\n" % (value.__name__, klass.__module__))`

S-3. If `value.__name__ == "<lambda>"`, serialization raises
`ValueError("Cannot serialize function: lambda")` before any successful
serialization branch.

S-4. If the value is not class-bound, the existing function serializer behavior
is preserved: no-module values raise, importable functions use
`value.__qualname__`, and local functions raise.

S-5. The public method signature, return shape, and import-set shape are
unchanged.

## Formal Artifacts

The supporting K artifacts are:

- `fvk/mini-python-serializer.k`
- `fvk/django-serializer-spec.k`

Exact commands to machine-check later, not executed here:

```sh
cd fvk && kompile mini-python-serializer.k --backend haskell
cd fvk && kast --backend haskell django-serializer-spec.k
cd fvk && kprove django-serializer-spec.k
```

Expected machine-check result after the toolchain is run: `#Top`.
