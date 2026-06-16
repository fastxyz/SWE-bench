# Iteration Guidance

Status: V2 source edit applied after FVK audit.

## Source Decision

Keep the V1 structural chain serialization approach, but narrow it to actual
multi-exception chains.

Reasoning:

- F-001 and PO-004/PO-005 require structured chain preservation for the reported
  direct-cause and implicit-context failures.
- F-002 and PO-006 show V1 was broader than necessary because it serialized a
  `chain` field for single-exception `ExceptionChainRepr` values.
- The V2 guard `len(rep.longrepr.chain) > 1` satisfies the issue while reducing
  compatibility risk for ordinary failures.

## Recommended Follow-Up Tests

Do not edit tests in this task. In a normal development flow, add tests that
construct reports for:

1. `raise ValueError(12) from ValueError(11)` nested into a third exception, then
   assert `_from_json(_to_json(report)).longreprtext` contains all three values
   and the direct-cause description.
2. Implicit exception context with three values, then assert the round-tripped
   text contains all three values and the context description.
3. A normal single failed assertion, then assert `_to_json()["longrepr"]` has no
   `chain` key while existing top-level traceback/crash fields still round-trip.

## Machine-Check Follow-Up

The FVK commands to run in an environment with K installed are:

```sh
kompile fvk/mini-pytest-report.k --backend haskell
kast --backend haskell fvk/report-serialization-spec.k
kprove fvk/report-serialization-spec.k
```

The pytest-level commands to run in a real execution environment should include
the report serialization tests and any new chained-exception tests. They were
not run here by instruction.

## Residual Risk

The proof is partial and constructed only. It covers the report longrepr
serialization shape, not the whole pytest or xdist runtime. It assumes
`ExceptionChainRepr` preserves the invariant established by its constructor:
top-level `reprtraceback` and `reprcrash` are derived from the last chain
element.
