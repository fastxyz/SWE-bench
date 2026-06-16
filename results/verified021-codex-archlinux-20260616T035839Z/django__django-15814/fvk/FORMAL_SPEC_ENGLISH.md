# Formal Spec English

Status: constructed, not machine-checked.

## Claim PROXY-ONLY-PK

For a valid `only()` path that starts on `anotherModel`, follows the relation
field `customFk` to `proxyCustomModel`, and then selects `nameField`, mask
construction first normalizes the related target to `customModel`. The resulting
load mask contains both `key(customModel, idField)` and
`key(customModel, nameField)`. Running default-column selection for
`customModel` therefore selects both `idField` and `nameField`.

## Claim CONCRETE-TARGET-FRAME

For the same path shape with a non-proxy target `customModel`, normalization is
the identity. The load mask still contains `key(customModel, idField)` and
`key(customModel, nameField)`, and default-column selection still selects both
fields. This captures that the fix does not change concrete-target behavior.

## Counterexample LEGACY-PROXY-COUNTEREXAMPLE

If the pre-fix algorithm records the related primary key under the proxy model
key instead of the concrete model key, default-column selection for the concrete
model sees `nameField` but not `idField`. This is the mechanism behind the
reported `ValueError`.

