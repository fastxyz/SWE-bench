# FVK Iteration Guidance

Status: V1 stands unchanged after FVK audit.

## Decision

No source edits are required beyond V1. The audit found the original public API mismatch and confirmed that V1 satisfies the required `coord` API while preserving a deprecated `dim` compatibility path.

## Why V1 Stands

F-001 is resolved by PO-001 and PO-002: the public argument name is now `coord`, and `coord=` delegates the same operand to `Dataset.integrate`.

F-002 is resolved by PO-004: `dim=` remains accepted as a deprecated alias, matching the issue's deprecation-cycle ambiguity and the public units-test callsite.

F-003 is resolved by PO-005: duplicate coordinate operands are rejected rather than silently ordered.

F-004 is resolved by PO-006: numerical integration code is unchanged and every normalized path delegates to the existing dataset implementation.

F-005 remains a verification-process caveat only: the proof is constructed but not machine-checked, so tests should not be removed.

## Recommended Next Tests

Add focused tests for the API surface when test editing is allowed:

- `da.integrate(coord="x")` succeeds and equals `da.integrate("x")`.
- `da.integrate(dim="x")` emits `FutureWarning` and equals `da.integrate("x")`.
- `da.integrate(coord="x", dim="y")` raises `TypeError`.
- `inspect.signature(xr.DataArray.integrate)` exposes `coord`.

## Commands To Run Later

Do not run these in this benchmark session. In a real FVK environment:

```sh
kompile fvk/mini-python-api.k --backend haskell
kast --backend haskell fvk/dataarray-integrate-spec.k
kprove fvk/dataarray-integrate-spec.k
```
