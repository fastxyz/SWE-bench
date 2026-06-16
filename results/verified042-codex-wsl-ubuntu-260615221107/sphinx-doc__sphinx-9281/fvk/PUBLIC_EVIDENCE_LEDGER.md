# Public Evidence Ledger

Status: constructed, not machine-checked.

E1. Source `benchmark/PROBLEM.md`: "Python Enum values (used to show default
values in function signatures) are rendered ugly." Obligation: enum defaults in
signatures need a readable output form.

E2. Source `benchmark/PROBLEM.md`: expected signature contains
`MyEnum.ValueA`. Obligation: direct enum members render as `EnumClass.Member`.

E3. Source `benchmark/PROBLEM.md`: observed signature contains
`<MyEnum.ValueA: 10>`. Status: suspect legacy behavior; do not preserve as an
oracle.

E4. Source `benchmark/PROBLEM.md` hints: `repr()` is generally appropriate for
defaults, but `enum.Enum` does not honor the convention. Obligation: special
case enum values while preserving generic repr fallback.

E5. Source code: `stringify_signature()` calls
`object_description(param.default)`. Obligation: the enum result must propagate
through this contributor.

E6. Source code: `object_description()` centralizes repr-safe formatting.
Obligation: add the enum branch there and frame existing non-enum branches.
