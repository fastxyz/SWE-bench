# Iteration Guidance

Status: constructed, not machine-checked.

## Code Decision

Keep the V1 `ColumnTransformer` remainder propagation and add the V2
`_safe_set_output(transform=None)` early return.

## Why

- F-001 and PO-1/PO-2/PO-3 justify keeping the V1 source change:
  estimator-valued `remainder` must be configured before fit so its clone can
  produce pandas output.
- F-002 and PO-4 justify the V2 helper change: once `ColumnTransformer` calls
  `_safe_set_output` on `remainder`, the helper's documented `None` no-op must
  be honored for that path as well.
- F-003 and PO-5 constrain the V2 helper change: do not weaken the existing
  error for non-`None` output configuration on unconfigurable transformers.

## Remaining Work For A Runtime-Capable Environment

Do not run these in this session. In a runtime-capable environment, run:

```sh
kompile fvk/mini-column-transformer.k --backend haskell
kprove fvk/column-transformer-set-output-spec.k
```

Then run focused Python tests for the issue and the `transform=None` helper
edge. Until then, treat the proof as constructed, not machine-checked.
