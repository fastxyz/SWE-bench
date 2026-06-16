# FVK Specification: Enum Defaults in Autodoc Signatures

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Scope

The audited observable is the text Sphinx emits for Python signature default
values when autodoc calls `stringify_signature()` and that function delegates
default formatting to `object_description()`.

Primary code under proof:

- `repo/sphinx/util/inspect.py::object_description`
- `repo/sphinx/util/inspect.py::stringify_signature`, only the default-value
  contributor that calls `object_description(param.default)`

## Intent Spec

I1. A Python enum member used as a function default must render as a readable
member reference, not Python's default enum `repr`.

I2. The expected direct enum-member form is `EnumClass.Member`, matching the
issue's expected `MyEnum.ValueA` and omitting the module prefix.

I3. The change must preserve existing non-enum default formatting: dictionaries,
sets, frozensets, generic `repr`, memory-address stripping, and newline
normalization are not part of the bug.

I4. The signature formatter must keep using the same spacing rules around
defaults; only the textual representation of enum default values changes.

I5. The source-like enum-member form is justified only when a member spelling
exists. For named flag combinations, each named component must be qualified.
For enum values without a name, the formatter must not invent `EnumClass.None`;
it should fall back to the existing `repr` path.

## Public Evidence Ledger

E1. Source `benchmark/PROBLEM.md`: "Python Enum values (used to show default
values in function signatures) are rendered ugly." This imposes an output-form
postcondition over enum defaults in signatures.

E2. Source `benchmark/PROBLEM.md`: expected signature
`ugly_enum_func(e: ugly_enum.MyEnum = MyEnum.ValueA) -> None`. This fixes the
direct enum-member output shape as `MyEnum.ValueA`.

E3. Source `benchmark/PROBLEM.md`: current behavior
`ugly_enum_func(e: ugly_enum.MyEnum = <MyEnum.ValueA: 10>) -> None`. This marks
the generic enum `repr` form as suspect legacy behavior, not as a spec oracle.

E4. Source `benchmark/PROBLEM.md` hints: `repr()` is generally appropriate for
defaults, but `enum.Enum` does not honor that convention and should be
special-cased. This supports preserving the generic `repr` fallback outside
enum values while adding an enum branch.

E5. Source code: `stringify_signature()` writes defaults via
`object_description(param.default)`. This is implementation evidence for the
proof path; it is not the source of the expected enum spelling.

E6. Source code: `object_description()` already owns repr-safe formatting for
signature defaults and autodoc value headers. This supports centralizing the
enum branch there, with frame conditions for the existing non-enum branches.

## Formal Spec English

K1. `objectDescription(enumNamed(C, N, R))` reaches the string `C + "." + N`
for any non-empty enum member name `N`.

K2. `objectDescription(flagNamed(C, N1|...|Nk, R))` reaches
`C.N1|...|C.Nk`, so a flag combination does not leave later components
unqualified.

K3. `objectDescription(enumUnnamed(C, R))` reaches the same cleaned repr string
as the generic fallback, avoiding the invented output `C.None`.

K4. `objectDescription(other(R))` reaches the cleaned repr string `R`; this
models the preserved fallback path for non-enum objects.

K5. `stringifyDefault(P, O)` reaches `P + objectDescription(O)`, so the enum
formatting result propagates unchanged into the signature default slot.

## Spec Audit

K1 passes I1-I2: it proves the named enum-member output shape from the public
expected signature.

K2 passes I1 and I5 under the default-domain assumption that `enum.Flag`
combination names are pipe-separated member names.

K3 passes I5: a missing name is outside the direct member-reference obligation,
and falling back to the existing repr path preserves behavior without inventing
a false member name.

K4 passes I3: non-enum formatting is framed.

K5 passes I4: the proof models only replacement of the default-value text, not
the surrounding signature grammar.

No spec item is derived solely from V1 behavior. The pre-fix `<MyEnum.ValueA:
10>` display is treated as suspect legacy evidence under the FVK intent rules.

## Public Compatibility Audit

Changed public callable signatures: none.

Changed public types or return shapes: none. `object_description()` still
returns `str` or raises `ValueError` from the existing `repr` exception path.

Changed dispatch protocols or subclass overrides: none. The edit adds an
internal branch before the existing dict/set/frozenset/repr branches.

Callsite compatibility: existing callsites of `object_description()` continue
to receive a string. For enum members, the string changes intentionally to the
publicly required member-reference form.

## Formal Core

Supporting K artifacts:

- `fvk/mini-enum-format.k`
- `fvk/enum-default-spec.k`

Exact commands to machine-check later, not run in this session:

```sh
cd fvk
kompile mini-enum-format.k --backend haskell
kast --backend haskell enum-default-spec.k
kprove enum-default-spec.k
```
