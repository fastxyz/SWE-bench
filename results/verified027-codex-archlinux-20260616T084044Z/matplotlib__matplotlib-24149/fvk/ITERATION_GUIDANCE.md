# Iteration Guidance

## V2 Decision

Keep V1 source unchanged.

Reason: FINDINGS F-001 through F-005 and PROOF_OBLIGATIONS PO-001 through PO-007
show that the public issue is addressed by the existing V1 edit, while the
obligations that protect adjacent behavior are also satisfied.

## Decisions

- Do not change `cbook._safe_first_finite`.
  - Trace: F-001, F-002, PO-001, PO-003, PO-007.
  - Reason: the issue identifies `_convert_dx` as the failure path. A global
    helper change would affect callers that intentionally handle
    `StopIteration`.

- Do not change empty `bar([], [])` behavior.
  - Trace: F-003, PO-004.
  - Reason: the issue cites empty data as context for why a NaN phantom bar is
    used, not as the behavior requested for repair.

- Do not add broader exception handling around all of `_convert_dx`.
  - Trace: F-001, PO-001, PO-005.
  - Reason: the only intent-derived new exception case is `StopIteration` from
    representative selection. Existing conversion-error fallbacks already cover
    `ValueError`, `TypeError`, and `AttributeError`.

- Do not edit tests.
  - Trace: task constraints, F-004, PROOF residual risk.
  - Reason: the benchmark fixes production code only; tests are fixed/hidden.

## Next Development Pass

If a normal execution environment is available later, run the project tests that
cover `Axes.bar`, then add focused regression tests for:

- all-NaN x and height data;
- NaN x with finite height;
- leading-NaN x with a later finite x value.

If K tooling is available later, run:

```sh
kompile fvk/mini-convert-dx.k --backend haskell
kast --backend haskell fvk/convert-dx-spec.k
kprove fvk/convert-dx-spec.k
```

Until those commands return `#Top`, keep the proof labeled constructed, not
machine-checked.
