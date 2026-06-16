# FVK Iteration Guidance

Status: V1 stands unchanged.

## Decision

Do not revise `repo/sympy/printing/pycode.py` beyond V1. The FVK audit found the V1 mapping-based fix satisfies the public intent and proof obligations.

## Rationale

- F-001 is resolved by PO-002 through PO-006: the target functions are known, dispatch reaches generated methods, formatting emits Python builtins, and the unsupported marker is bypassed.
- F-003 is accepted by PO-007: the shared mapping gives `MpmathPrinter` scalar support without breaking public signatures or NumPy's explicit vectorized overrides.
- F-004 is a test gap only. The benchmark forbids modifying tests, so no source or test change is justified from it.

## Recommended Follow-up Outside This Benchmark

- Add plain-printer regression coverage for `pycode(Min(x, y))`, `pycode(Max(x, y))`, and a variadic/nested case.
- Run the project tests and, if desired, the emitted FVK commands once an execution environment is available.
- Keep tests until the constructed proof is machine-checked and returns `#Top`.
