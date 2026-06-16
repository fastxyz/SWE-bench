# Constructed Proof

Status: constructed, not machine-checked. No tests, Python code, `kompile`, or
`kprove` were run.

## Claims Proved

The constructed K claims in `autodoc-mock-spec.k` cover:

1. `_make_subclass(TypeVar("T"), module, superclass)` constructs its generated
   type using string name `"T"` and display name `module + "." + "T"`.
2. `_make_subclass("name", module, superclass)` preserves the existing dotted
   display-name result.
3. `_make_subclass(name, module, superclass)` uses `normalizedName(name)` for all
   class-name and display-name string positions.
4. `_MockObject.__getitem__(TypeVar("T"))` reaches a generated mock instance
   through that safe helper path.

## Symbolic Proof Sketch

### `_make_subclass_name`

Case split on V1 control flow:

- If `name` is a string, the helper returns `name`. The result is a string and
  existing string-name behavior is identical to pre-V1 behavior.
- Otherwise, evaluate `getattr(name, "__name__", None)`. If that value is a
  string, the helper returns it. `typing.TypeVar("T")` falls in this branch by
  public Sphinx convention and Python object behavior.
- Otherwise, the helper returns `repr(name)`. Under the stated ordinary-object
  domain assumption, `repr(name)` is a string. The explicit `isinstance`
  check prevents a fabricated mock `__name__` attribute from being used as if it
  were a string.

Therefore PO1, PO2, PO3, and PO6 hold.

### `_make_subclass`

V1 rewrites `name` to `_make_subclass_name(name)` before building `attrs`.
By PO1, the local `name` is a string after that assignment. Therefore:

- `module + "." + name` is string concatenation, not `str + TypeVar`.
- `type(name, (superclass,), attrs)` receives a string class-name argument.

This discharges PO4. Attribute merging remains the same behavior as before V1;
the proof does not rely on any new attribute semantics.

### `_MockObject.__getitem__`

V1 widens `key` to `Any` and calls `_make_subclass(key, self.__display_name__,
self.__class__)()`. For every in-domain generic key satisfying PO1,
`_make_subclass` satisfies PO4, so generic subscription no longer fails at the
issue-reported `str + TypeVar` operation. This discharges PO5.

### Compatibility

The public compatibility audit found no changed arity or return shape. Existing
string-name paths are covered by PO3, and the changed annotation only reflects a
runtime behavior Python already permits for subscription keys. This discharges
PO7.

## Adequacy and Completeness Check

The formal model preserves the property axis that distinguishes pre-V1 from V1:
whether `_make_subclass` receives a non-string name at the string-concatenation
and `type()` points. The pre-V1 failing case maps to a non-string `PyName`
without normalization; V1 maps it through `normalizedName` first. Thus the model
can distinguish the reported failure from the repaired behavior.

The proof intentionally does not cover full Python generic alias semantics,
custom objects with broken `__repr__`, or visual formatting of generic display
names with brackets. Those are outside the public issue intent.

## Machine-Check Commands

These are the exact commands to run later in an environment with K installed.
Expected result after successful machine checking: `kprove` returns `#Top`.

```sh
cd fvk
kompile mini-python-mock.k --backend haskell
kast --backend haskell autodoc-mock-spec.k
kprove autodoc-mock-spec.k
```

## Test Guidance

No test files were modified. Because the proof is not machine-checked, no test
removal is recommended now. A future test for `mock.SomeClass[TypeVar("T")]`
would be subsumed by PO2, PO4, and PO5 only after the K claims machine-check.
