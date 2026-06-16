# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 fixed the reported direct enum default, but F-02 exposed an avoidable edge
case in the newly introduced enum branch. V2 keeps the V1 behavior for named
enum members and adds a narrow refinement for `enum.Flag` composites and
nameless enum values.

## Applied Source Change

`repo/sphinx/util/inspect.py` now:

- stores `enum_name = object.name`;
- returns `EnumClass.Member` only when `enum_name is not None`;
- qualifies each pipe-separated `enum.Flag` component as `EnumClass.Component`;
- falls through to the existing repr path when no enum member name exists.

This directly addresses F-02 and PO-05 while preserving F-01's fix for PO-02.

## Recommended Tests to Add Later

Do not edit tests in this benchmark task. For a normal development pass, add
coverage for:

- function signature default `MyEnum.ValueA` renders as `MyEnum.ValueA`;
- `enum.IntEnum` default renders by class/member name, not by numeric `str`;
- named `enum.Flag` combination renders as `Perm.READ|Perm.WRITE`;
- nameless flag value does not render as `Perm.None`;
- representative non-enum defaults still use the previous repr behavior.

## Commands to Run Later

These commands are intentionally not run in this session:

```sh
cd fvk
kompile mini-enum-format.k --backend haskell
kast --backend haskell enum-default-spec.k
kprove enum-default-spec.k
```

Run the project test suite separately in an environment that permits execution.

## Residual Risks

Custom enum `__repr__` preservation is ambiguous in the public issue. The
current decision favors the public expected member-reference spelling for named
enum members.

Container defaults such as lists or tuples containing enum members are outside
the proven contract. The issue's concrete desired output covers a direct enum
default, so no broader container-formatting change was made.
