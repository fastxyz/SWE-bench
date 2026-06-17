# Iteration Guidance

Status: V1 stands unchanged.

## Decision

No additional source edit is justified by the FVK findings. V1 discharges the public issue obligations:

- `Contains(x, set).as_set()` now returns a Set for symbolic `x`.
- The generic one-free-symbol Boolean fallback now returns `ConditionSet`.
- False/empty membership reaches `EmptySet` through existing SymPy Boolean and `ConditionSet` behavior.

## Why Not Change More

Do not modify multivariate Boolean conversion in this pass. The public hint explicitly says it is not implemented and unclear, and `Boolean.as_set()` already preserves that boundary.

Do not edit tests. The user forbids test-file changes; the stale visible test is recorded as SUSPECT in `fvk/FINDINGS.md`.

Do not broaden the proof to full SymPy semantics here. The FVK run uses a property-complete mini model for the changed conversion path. Full object construction, solver behavior for periodic relationals, and all `Piecewise` simplification behavior are outside the proof's trusted scope.

## Recommended Future Work

- Add public tests for the new intended behavior in a normal development workflow.
- Machine-check the K artifacts in an environment with K installed before treating the proof as verified.
- If future intent requires multivariate Boolean `as_set`, design that API explicitly instead of inferring it from this one-variable fix.
